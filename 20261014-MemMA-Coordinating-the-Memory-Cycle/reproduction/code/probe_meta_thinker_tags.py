# -*- coding: utf-8 -*-
"""Meta-Thinker 标签/截断探针：用仓库真实的 v4 answerability system prompt 直打模型。

目的：判明 Strategic 档退化的病根是"模型不会吐标签"还是"输出被 max_tokens 截断"。
做法：对同一批 NOT_ANSWERABLE 问题，分别在 max_tokens=800 / 4000 下调用，
      记录 finish_reason、completion_tokens、各标签是否解析成功、检索环能否继续。

只读、只发少量请求，不改主流程。用法：
    python probe_meta_thinker_tags.py
环境变量：OPENAI_API_KEY / OPENAI_BASE_URL（由 run_deepseek.ps1 注入）
"""
import ast
import json
import os
import re

from openai import OpenAI

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # .../reproduction
SRC = os.path.join(BASE, "code", "memma", "scripts", "run_memma_self_refine_single.py")
BANK = os.path.join(BASE, "results", "cost_probe", "memory_bank", "conv-26", "memory_bank.json")
RES = os.path.join(BASE, "results", "cost_probe", "eval_strategic_c1",
                   "results_20261014_175658.json")

TAGS = ["decision", "reason", "key_gaps", "retrieval_guidance", "missing_speaker", "time_need"]
MODELS = ["deepseek-flash", "deepseek-v4-pro"]
BUDGETS = [800, 4000]   # 800 = 仓库硬编码值；4000 = 放开后对照
N_Q = 6


def extract_const(path, name):
    tree = ast.parse(open(path, encoding="utf-8").read())
    for node in tree.body:
        if isinstance(node, ast.Assign):
            for t in node.targets:
                if isinstance(t, ast.Name) and t.id == name:
                    if isinstance(node.value, ast.Constant) and isinstance(node.value.value, str):
                        return node.value.value
    raise SystemExit(f"const not found: {name}")


def build_memories():
    """复刻 SingleAgentEvaluator._format_memories_by_speaker 的输出。"""
    bank = json.load(open(BANK, encoding="utf-8"))
    entries = bank["entries"]
    groups = {}
    for e in entries:
        name = e.get("speaker") or "Unknown"
        ts = f"[{e['timestamp']}] " if e.get("timestamp") else ""
        groups.setdefault(name, []).append(f"{ts}{e['content']}")
    names = list(groups.keys())
    join = lambda items: "\n".join(items) if items else "No memories available."
    s1 = names[0]
    s1m = join(groups[s1])
    s2, s2m = (names[1], join(groups[names[1]])) if len(names) > 1 else ("Speaker 2", "No memories available.")
    return len(entries), s1, s1m, s2, s2m


def load_questions():
    res = json.load(open(RES, encoding="utf-8"))
    qas = res["sample_results"][0]["results"]
    na = [q["question"] for q in qas
          if q.get("retrieval_turns") and q["retrieval_turns"][0]["decision"] == "NOT_ANSWERABLE"]
    return na[:N_Q]


def one_call(client, model, system_prompt, combined, question, budget):
    user = (f"Question: {question}\n\n"
            f"Retrieved Memories:\n{combined}\n\n"
            f"Previous Queries Used:\n[None]\n\n"
            f"Analyze whether the evidence is sufficient to answer the question.")
    r = client.chat.completions.create(
        model=model, temperature=0.3, max_tokens=budget,
        messages=[{"role": "system", "content": system_prompt},
                  {"role": "user", "content": user}],
    )
    ch = r.choices[0]
    usage = r.usage
    return {
        "text": ch.message.content or "",
        "finish": ch.finish_reason,
        "completion_tokens": getattr(usage, "completion_tokens", None),
        "usage_raw": usage.model_dump() if usage else None,
    }


def analyze(text):
    p = {}
    for t in TAGS:
        m = re.search(rf"<{t}>(.*?)</{t}>", text, re.S | re.I)
        p[t] = m.group(1).strip() if m else None
    dm = re.search(r"<decision>\s*(ANSWERABLE|NOT_ANSWERABLE)\s*</decision>", text, re.I)
    p["_dec"] = dm.group(1) if dm else "?"
    p["_dec_matched"] = bool(dm) or ("ANSWERABLE" in text.upper())
    p["_loop_ok"] = (p["_dec"] == "NOT_ANSWERABLE" and (bool(p["key_gaps"]) or bool(p["retrieval_guidance"])))
    return p


def main():
    system_prompt = extract_const(SRC, "META_THINKER_ANSWERABILITY_PROMPT_v4")
    n_entries, s1, s1m, s2, s2m = build_memories()
    combined = f"[{s1}]\n{s1m}\n\n[{s2}]\n{s2m}"
    questions = load_questions()

    client = OpenAI(api_key=os.environ["OPENAI_API_KEY"],
                    base_url=os.environ.get("OPENAI_BASE_URL") or os.environ.get("OPENAI_API_BASE"))

    print(f"# models={MODELS} budgets={BUDGETS} questions={len(questions)} mem_entries={n_entries}")
    summary = []
    for model in MODELS:
        for budget in BUDGETS:
            loop_ok = 0
            fin = {}
            print(f"\n== {model} @ max_tokens={budget} ==")
            for i, q in enumerate(questions, 1):
                try:
                    r = one_call(client, model, system_prompt, combined, q, budget)
                except Exception as e:
                    print(f"  [{i}] CALL FAILED: {type(e).__name__}: {e}")
                    continue
                p = analyze(r["text"])
                fin[r["finish"]] = fin.get(r["finish"], 0) + 1
                if p["_loop_ok"]:
                    loop_ok += 1
                tags = "".join("o" if p[t] is not None else "." for t in TAGS)
                print(f"  [{i}] finish={str(r['finish']):<7} ctok={str(r['completion_tokens']):<5} "
                      f"len={len(r['text']):<5} dec={p['_dec']:<14} tags={tags} "
                      f"loop={'CONTINUE' if p['_loop_ok'] else 'STOP':<8} | {q[:45]}")
                if p["_loop_ok"] is False and r["finish"] == "length":
                    print(f"       >> 末尾 120 字符: ...{r['text'][-120:]!r}")
            print(f"  -> 检索环可继续 {loop_ok}/{len(questions)}   finish_reason={fin}")
            summary.append((model, budget, loop_ok, fin))

    print("\n===== 汇总 =====")
    for model, budget, loop_ok, fin in summary:
        print(f"{model:<18} max_tokens={budget:<5} continue={loop_ok}/{len(questions)}  finish={fin}")
    if questions:
        print("\n# 单次 usage 样例:")
        try:
            r = one_call(client, MODELS[0], system_prompt, combined, questions[0], 4000)
            print(json.dumps(r["usage_raw"], ensure_ascii=False, indent=2))
        except Exception as e:
            print(f"usage dump failed: {e}")


if __name__ == "__main__":
    main()
# -*- coding: utf-8 -*-
"""DeepSeek 服务健康探测：连打 N 次最小请求，统计成功率与延迟。

用于判断上游是否过载（503 Service is too busy）/ 超时。
环境变量：OPENAI_API_KEY / OPENAI_BASE_URL（由 run_deepseek.ps1 注入）
"""
import os
import time

import httpx
from openai import OpenAI

N = int(os.environ.get("HEALTH_N", "6"))
MODEL = os.environ.get("HEALTH_MODEL", "deepseek-flash")
client = OpenAI(
    api_key=os.environ["OPENAI_API_KEY"],
    base_url=os.environ.get("OPENAI_BASE_URL") or os.environ.get("OPENAI_API_BASE"),
    max_retries=0,
    timeout=httpx.Timeout(25.0, connect=10.0),
)

ok = 0
lat = []
for i in range(1, N + 1):
    t0 = time.time()
    try:
        r = client.chat.completions.create(
            model=MODEL, max_tokens=32,
            messages=[{"role": "user", "content": "hi"}],
        )
        el = time.time() - t0
        lat.append(el)
        ok += 1
        print(f"#{i} OK   {el:5.1f}s  {repr((r.choices[0].message.content or '')[:50])}", flush=True)
    except Exception as e:
        print(f"#{i} FAIL {time.time() - t0:5.1f}s  {type(e).__name__}: {str(e)[:110]}", flush=True)

if lat:
    print(f"== ok {ok}/{N}   latency min={min(lat):.1f}s avg={sum(lat)/len(lat):.1f}s max={max(lat):.1f}s", flush=True)
else:
    print(f"== ok {ok}/{N}   （全部失败）", flush=True)
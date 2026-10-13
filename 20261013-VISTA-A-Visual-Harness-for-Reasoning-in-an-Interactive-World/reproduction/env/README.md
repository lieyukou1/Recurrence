# 隔离环境定义 · VISTA: A Visual Harness for Reasoning in an Interactive World

按 AGENTS.md §5 的混合式规范，**在本目录内**放该论文的环境定义（三选一或组合）：

| 场景 | 放什么文件 |
| --- | --- |
| 纯 Python / 轻依赖 | `pyproject.toml` + `uv.lock`（环境建于本目录内 `.venv/`） |
| 深度学习 / CUDA | `environment.yml`（conda/mamba，环境名 `rec-<开工日>-<简称>`） |
| 非 Python / 系统依赖 | `Dockerfile` |

**红线**：不改动本机全局环境、不 pip 全局安装、环境名带论文前缀。环境随论文走，删除本论文目录即彻底干净。

## 使用示例

uv：
```
uv venv .venv
uv pip install -r requirements.txt
```

conda/mamba：
```
mamba env create -f environment.yml
mamba activate rec-20261013-<简称>
```

Docker：
```
docker build -t VISTA-A-Visual-Harness-for-Reasoning-in-an-Interactive-World:latest .
docker run --rm -it VISTA-A-Visual-Harness-for-Reasoning-in-an-Interactive-World:latest
```
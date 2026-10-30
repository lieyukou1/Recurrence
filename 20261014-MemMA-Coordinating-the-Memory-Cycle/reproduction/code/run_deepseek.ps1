# 统一注入 DeepSeek 环境变量（读 code/memma/.env），再把参数原样转发给指定脚本。
#
# 用法（在 reproduction/code 目录下）：
#   .\run_deepseek.ps1 scripts\run_memma_self_refine_single.py --dataset data\locomo10.json `
#       --memory-dir .\results\... --model deepseek-flash --base_url https://api.deepseek.com ...
#
# 之所以需要本脚本：仓库脚本不读 .env，只认真实环境变量 + CLI 参数。

# 不能用 Stop：Python 的 logging 走 stderr，PowerShell 会把它当致命错误而中断子进程
$ErrorActionPreference = "Continue"

$CodeDir  = $PSScriptRoot
$RepoRoot = Join-Path $CodeDir "memma"
$EnvFile  = Join-Path $RepoRoot ".env"
$Py       = Join-Path (Split-Path $CodeDir -Parent) "env\.venv\Scripts\python.exe"

if (-not (Test-Path $EnvFile)) { throw "找不到 $EnvFile" }
if (-not (Test-Path $Py))      { throw "找不到 venv 解释器 $Py" }

# 解析 KEY=VALUE 形式的 .env，逐条写入当前进程环境
Get-Content $EnvFile | Where-Object { $_ -match '^\s*[^#\s][^=]*=' } | ForEach-Object {
    $k, $v = $_ -split '=', 2
    Set-Item -Path ("env:" + $k.Trim()) -Value $v.Trim()
}

Push-Location $RepoRoot
try {
    & $Py @args
} finally {
    Pop-Location
}
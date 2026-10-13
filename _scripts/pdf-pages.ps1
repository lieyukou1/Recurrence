<#
.SYNOPSIS
    把 PDF 逐页渲染为 PNG，供多模态 AI 真正"看"论文。

.DESCRIPTION
    默认输出到 PDF 同级目录下的 extracted\pages\（即 <paper>\extracted\pages\），
    命名规范 page-001.png ...，与 AGENTS.md §6 的多模态阅读工作流一致。

    渲染后端按以下顺序自动探测：
      1) pdftoppm (poppler)   2) ImageMagick (magick)   3) Python + PyMuPDF (fitz)

.EXAMPLE
    .\_scripts\pdf-pages.ps1 -Pdf ".\20261013-Attention-Is-All-You-Need\paper\original.pdf"

.EXAMPLE
    .\_scripts\pdf-pages.ps1 -Pdf ".\x\paper\original.pdf" -Dpi 200 -First 1 -Last 5
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Pdf,

    [string]$Out = '',

    [int]$Dpi = 150,

    [int]$First = 0,

    [int]$Last = 0
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $Pdf)) {
    throw "找不到 PDF 文件：$Pdf"
}
$Pdf = (Resolve-Path $Pdf).Path

if ([string]::IsNullOrWhiteSpace($Out)) {
    $Out = Join-Path (Join-Path (Split-Path -Parent $Pdf) 'extracted') 'pages'
}
New-Item -ItemType Directory -Path $Out -Force | Out-Null

$firstArg = if ($First -gt 0) { $First } else { $null }
$lastArg  = if ($Last  -gt 0) { $Last  } else { $null }

$done = $false

# ---- 后端 1：pdftoppm (poppler) ----
$pdftoppm = Get-Command pdftoppm -ErrorAction SilentlyContinue
if (-not $done -and $pdftoppm) {
    $prefix = Join-Path $Out 'page'
    $args = @('-png', '-r', $Dpi)
    if ($firstArg) { $args += @('-f', $firstArg) }
    if ($lastArg)  { $args += @('-l', $lastArg) }
    $args += @($Pdf, $prefix)
    & $pdftoppm.Source @args
    $done = $true
}

# ---- 后端 2：ImageMagick ----
if (-not $done) {
    $magick = Get-Command magick -ErrorAction SilentlyContinue
    if ($magick) {
        $pattern = Join-Path $Out 'page-%03d.png'
        & $magick.Source -density $Dpi $Pdf $pattern
        $done = $true
    }
}

# ---- 后端 3：Python + PyMuPDF ----
if (-not $done) {
    $py = Get-Command python -ErrorAction SilentlyContinue
    if ($py) {
        $code = @'
import sys, fitz
pdf, out, dpi, first, last = sys.argv[1], sys.argv[2], int(sys.argv[3]), sys.argv[4], sys.argv[5]
doc = fitz.open(pdf)
n = doc.page_count
f = int(first) if first else 1
l = int(last) if last else n
for i in range(f, l + 1):
    doc.load_page(i - 1).get_pixmap(dpi=dpi).save(f"{out}/page-{i:03d}.png")
'@
        & $py.Source -c $code $Pdf $Out $Dpi "$First" "$Last"
        $done = $true
    }
}

if (-not $done) {
    throw "未找到可用的 PDF 渲染后端。请安装其一：poppler(pdftoppm) / ImageMagick / Python PyMuPDF(fitz)，然后重试。"
}

# ---- 统一命名为 3 位补零（兼容 pdftoppm 输出）----
Get-ChildItem -Path $Out -Filter 'page-*.png' -File | ForEach-Object {
    if ($_.BaseName -match '^page-(\d+)$') {
        $n = [int]$Matches[1]
        $newName = 'page-{0:D3}.png' -f $n
        if ($_.Name -ne $newName) {
            Rename-Item -Path $_.FullName -NewName $newName
        }
    }
}

$count = (Get-ChildItem -Path $Out -Filter 'page-*.png' -File).Count
Write-Host ""
Write-Host "已渲染 $count 张页面图到：$Out" -ForegroundColor Green
Write-Host "接下来：用多模态能力逐页 Read 这些 PNG，再据此撰写 reading\ 下的笔记。" -ForegroundColor Cyan
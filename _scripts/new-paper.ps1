<#
.SYNOPSIS
    按 Recurrence 工作区规范生成一篇新论文的目录骨架。

.DESCRIPTION
    一级目录命名：<开工日YYYYMMDD>-<论文标题Slug>
    从 _templates/ 复制模板，并自动替换占位符：
      {{TITLE}} {{DATE}} {{SLUG}} {{DIRNAME}} {{ARXIV}} {{CREATED}}

.EXAMPLE
    .\_scripts\new-paper.ps1 -Title "Attention Is All You Need" -Arxiv 1706.03762

.EXAMPLE
    .\_scripts\new-paper.ps1 -Title "Zero To One Reasoning" -Date 20261015 -Slug Zero-To-One-Reasoning
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Title,

    [string]$Date = (Get-Date).ToString('yyyyMMdd'),

    [string]$Arxiv = '',

    [string]$Slug = '',

    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# 工作区根目录 = 本脚本所在目录的上一级
$Root      = Split-Path -Parent $PSScriptRoot
$TemplateDir = Join-Path $Root '_templates'

if (-not (Test-Path $TemplateDir)) {
    throw "找不到模板目录：$TemplateDir"
}

# 未指定 Slug 时，从标题推导：非字母/数字（含中文）的字符统一按分隔符处理
if ([string]::IsNullOrWhiteSpace($Slug)) {
    $parts = ($Title -split '[^\p{L}\p{N}]+') | Where-Object { $_ -ne '' }
    $Slug  = $parts -join '-'
}

$DirName = "$Date-$Slug"
$Target  = Join-Path $Root $DirName

if (Test-Path $Target) {
    if (-not $Force) {
        throw "目录已存在：$Target（如需覆盖请加 -Force）"
    }
    Remove-Item $Target -Recurse -Force
}

# 1) 复制模板骨架
New-Item -ItemType Directory -Path $Target -Force | Out-Null
Copy-Item -Path (Join-Path $TemplateDir '*') -Destination $Target -Recurse -Force

# 2) 替换占位符（UTF-8 无 BOM，避免中文乱码）
$map = @{
    '{{TITLE}}'   = $Title
    '{{DATE}}'    = $Date
    '{{SLUG}}'    = $Slug
    '{{DIRNAME}}' = $DirName
    '{{ARXIV}}'   = $Arxiv
    '{{CREATED}}' = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
}

$textExt   = @('.md', '.yaml', '.yml', '.txt', '.gitkeep')
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

Get-ChildItem -Path $Target -Recurse -File | ForEach-Object {
    if ($textExt -contains $_.Extension.ToLower()) {
        $content = [System.IO.File]::ReadAllText($_.FullName, $utf8NoBom)
        foreach ($k in $map.Keys) {
            $content = $content.Replace($k, $map[$k])
        }
        [System.IO.File]::WriteAllText($_.FullName, $content, $utf8NoBom)
    }
}

# 3) 输出结果与后续步骤
Write-Host ""
Write-Host "已创建论文目录：$Target" -ForegroundColor Green
Write-Host ""
Write-Host "后续步骤：" -ForegroundColor Cyan
Write-Host "  1. 下载论文 PDF 并放为: $DirName\paper\original.pdf"
Write-Host "  2. 填写元数据:          $DirName\paper\metadata.yaml"
Write-Host "  3. 渲染页面图:          .\_scripts\pdf-pages.ps1 -Pdf `"$DirName\paper\original.pdf`""
Write-Host "  4. 多模态逐页精读，产出 reading\ 下四件套"
Write-Host "  5. 填写 OUTLINE.md（定主分类+标签），并更新根目录 CATALOG.md（见 AGENTS.md §4）"
Write-Host "  6. 在 reproduction\env\ 建立隔离环境（见 AGENTS.md §5）"
param([string]$GameRoot = 'E:\SteamLibrary\steamapps\common\The Witcher 3')
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
& node (Join-Path $PSScriptRoot 'build-menu-strings.cjs')
if($LASTEXITCODE -ne 0){throw 'Menu string generation failed'}
$source = Join-Path $repoRoot 'mods\modShadowMonarch\content\scripts\local\shadow_monarch.ws'
[xml](Get-Content -Raw (Join-Path $repoRoot 'bin\config\r4game\user_config_matrix\pc\modShadowMonarch.xml')) | Out-Null
$text = Get-Content -Raw $source
if($text -match '\bsaved\s+var\b|FactsAdd\(|FactsSet\('){throw 'Persistent mod bookkeeping detected'}
if(($text.ToCharArray() | Where-Object {$_ -eq '{'}).Count -ne ($text.ToCharArray() | Where-Object {$_ -eq '}'}).Count){throw 'Unbalanced braces'}
if(!(Test-Path -LiteralPath (Join-Path $repoRoot 'mods\modShadowMonarch\content\precompiled.rsblob'))){throw 'Compile the production blob before packaging'}
New-Item -ItemType Directory -Force (Join-Path $repoRoot 'dist') | Out-Null
Compress-Archive -Path (Join-Path $repoRoot 'mods'),(Join-Path $repoRoot 'bin'),(Join-Path $repoRoot 'README.md'),(Join-Path $repoRoot 'README.txt'),(Join-Path $repoRoot 'spec.md'),(Join-Path $repoRoot 'docs') -DestinationPath (Join-Path $repoRoot 'dist\ShadowMonarch-1.0.0-rc1.zip') -Force
Write-Output 'Static/package checks passed. This does not compile WitcherScript or validate gameplay.'

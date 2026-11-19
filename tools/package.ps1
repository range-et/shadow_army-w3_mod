param([string]$GameRoot = 'E:\SteamLibrary\steamapps\common\The Witcher 3')
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
# Package the checked-in production files. After changing menu strings, run
# build-menu-strings.cjs separately with the reference described in docs/reference-sources.md.
$source = Join-Path $repoRoot 'mods\modShadowMonarch\content\scripts\local\shadow_monarch.ws'
[xml](Get-Content -Raw (Join-Path $repoRoot 'bin\config\r4game\user_config_matrix\pc\modShadowMonarch.xml')) | Out-Null
$text = Get-Content -Raw $source
if($text -match '\bsaved\s+var\b|FactsAdd\(|FactsSet\('){throw 'Persistent mod bookkeeping detected'}
if(($text.ToCharArray() | Where-Object {$_ -eq '{'}).Count -ne ($text.ToCharArray() | Where-Object {$_ -eq '}'}).Count){throw 'Unbalanced braces'}
if(!(Test-Path -LiteralPath (Join-Path $repoRoot 'mods\modShadowMonarch\content\precompiled.rsblob'))){throw 'Compile the production blob before packaging'}

$releaseFiles = [ordered]@{
    'mods/modShadowMonarch/content/scripts/local/shadow_monarch.ws' = 'mods/modShadowMonarch/content/scripts/local/shadow_monarch.ws'
    'mods/modShadowMonarch/content/precompiled.rsblob' = 'mods/modShadowMonarch/content/precompiled.rsblob'
    'mods/modShadowMonarch/content/en.w3strings' = 'mods/modShadowMonarch/content/en.w3strings'
    'bin/config/r4game/user_config_matrix/pc/modShadowMonarch.xml' = 'bin/config/r4game/user_config_matrix/pc/modShadowMonarch.xml'
    'mods/modShadowMonarch/ShadowMonarch-README.txt' = 'README.txt'
    'mods/modShadowMonarch/ShadowMonarch-LICENSE.txt' = 'LICENSE'
}
$dist = Join-Path $repoRoot 'dist'
New-Item -ItemType Directory -Force $dist | Out-Null
$destination = Join-Path $dist 'ShadowMonarch-1.0.0-rc1.zip'
$temporaryZip = Join-Path $dist ("ShadowMonarch-{0}.tmp" -f [guid]::NewGuid())
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
try {
    $archive = [IO.Compression.ZipFile]::Open($temporaryZip, [IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($entry in $releaseFiles.GetEnumerator()) {
            [IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $archive, (Join-Path $repoRoot $entry.Value), $entry.Key
            ) | Out-Null
        }
    } finally {
        $archive.Dispose()
    }
    Move-Item -LiteralPath $temporaryZip -Destination $destination -Force
} finally {
    if (Test-Path -LiteralPath $temporaryZip) {
        Remove-Item -LiteralPath $temporaryZip
    }
}
Write-Output 'Static/package checks passed. This does not compile WitcherScript or validate gameplay.'

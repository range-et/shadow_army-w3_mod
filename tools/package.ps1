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

# Preserve the entry order and ZIP wall-clock timestamps from the Vortex-tested
# rc1 archive. ZIP stores these timestamps without a time zone.
$releaseFiles = @(
    @{ Path = 'mods/modShadowMonarch/content/scripts/local/shadow_monarch.ws'; Timestamp = '2026-11-18T22:05:06+00:00' }
    @{ Path = 'mods/modShadowMonarch/content/precompiled.rsblob'; Timestamp = '2026-11-18T22:05:44+00:00' }
    @{ Path = 'mods/modShadowMonarch/content/en.w3strings'; Timestamp = '2026-11-19T15:02:36+00:00' }
    @{ Path = 'bin/config/r4game/user_config_matrix/pc/modShadowMonarch.xml'; Timestamp = '2026-11-18T22:05:06+00:00' }
    @{ Path = 'mods/modShadowMonarch/ShadowMonarch-README.txt'; Timestamp = '2026-11-19T15:02:34+00:00'; Source = 'README.txt' }
    @{ Path = 'mods/modShadowMonarch/ShadowMonarch-LICENSE.txt'; Timestamp = '2026-11-19T14:19:18+00:00'; Source = 'LICENSE' }
)
$dist = Join-Path $repoRoot 'dist'
New-Item -ItemType Directory -Force $dist | Out-Null
$destination = Join-Path $dist 'ShadowMonarch-1.0.0-rc1.zip'
$temporaryZip = Join-Path $dist ("ShadowMonarch-{0}.tmp" -f [guid]::NewGuid())
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
try {
    $archive = [IO.Compression.ZipFile]::Open($temporaryZip, [IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($file in $releaseFiles) {
            $sourcePath = $file.Path
            if ($file.Source) { $sourcePath = $file.Source }
            $entry = $archive.CreateEntry($file.Path, [IO.Compression.CompressionLevel]::Optimal)
            $entry.LastWriteTime = [datetimeoffset]$file.Timestamp
            $entry.ExternalAttributes = 0

            $inputStream = [IO.File]::OpenRead((Join-Path $repoRoot $sourcePath))
            try {
                $entryStream = $entry.Open()
                try {
                    $inputStream.CopyTo($entryStream)
                } finally {
                    $entryStream.Dispose()
                }
            } finally {
                $inputStream.Dispose()
            }
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

param(
    [string]$RedkitRoot = 'D:\SteamLibrary\steamapps\common\The Witcher 3 REDkit',
    [string]$GameRoot = 'E:\SteamLibrary\steamapps\common\The Witcher 3',
    [switch]$Diagnostics,
    [switch]$DamageTest,
    [switch]$CompatibilityCheck,
    [switch]$IntegrationTest,
    [switch]$IntegrationTail
)
$ErrorActionPreference = 'Stop'
if($IntegrationTail){$IntegrationTest = $true}
if($DamageTest){throw 'The standalone damage harness is historical. Use -Diagnostics with both production mods enabled for companion testing.'}
$repoRoot = Split-Path $PSScriptRoot -Parent
$compiler = Join-Path $RedkitRoot 'bin\x64_RedKit\wcc_lite.exe'
if(!(Test-Path -LiteralPath $compiler)){throw "REDkit compiler missing: $compiler"}
$patchSource = Join-Path $repoRoot 'mods\modShadowMonarch\content\scripts'
$buildName = 'production'
if($Diagnostics -or $IntegrationTest){
    $buildName = 'companion-diagnostic'
    $testSourceName = 'shadow_monarch_companion_test.ws'
    $patchSource = Join-Path $repoRoot 'build\companion-observer-scripts'
    New-Item -ItemType Directory -Force (Join-Path $patchSource 'local') | Out-Null
    Copy-Item (Join-Path $repoRoot 'mods\modShadowMonarch\content\scripts\local\shadow_monarch.ws') (Join-Path $patchSource 'local') -Force
    Copy-Item (Join-Path $PSScriptRoot "testing\$testSourceName") (Join-Path $patchSource 'local') -Force
    if($IntegrationTest){
        $buildName = 'companion-integration'
        $patchSource = Join-Path $repoRoot 'build\companion-integration-scripts'
        New-Item -ItemType Directory -Force (Join-Path $patchSource 'local') | Out-Null
        Copy-Item (Join-Path $repoRoot 'mods\modShadowMonarch\content\scripts\local\shadow_monarch.ws') (Join-Path $patchSource 'local') -Force
        Copy-Item (Join-Path $PSScriptRoot 'testing\shadow_monarch_companion_test.ws'),(Join-Path $PSScriptRoot 'testing\shadow_monarch_companion_integration.ws') (Join-Path $patchSource 'local') -Force
        if($IntegrationTail){
            $driver = Join-Path $patchSource 'local\shadow_monarch_companion_integration.ws'
            (Get-Content -LiteralPath $driver -Raw).Replace('smITPhase = 1;', 'smITPhase = 5;') | Set-Content -LiteralPath $driver
        }
    }
}
if($CompatibilityCheck){
    if($Diagnostics -or $IntegrationTest){throw 'Compile production compatibility and diagnostic observer separately'}
    $buildName = 'compatibility'
    $patchSource = Join-Path $repoRoot 'build\compatibility-scripts'
    New-Item -ItemType Directory -Force (Join-Path $patchSource 'local') | Out-Null
    Copy-Item (Join-Path $repoRoot 'mods\modShadowMonarch\content\scripts\local\shadow_monarch.ws') (Join-Path $patchSource 'local') -Force
    $dependency = @(Get-ChildItem (Join-Path $repoRoot 'references') -Recurse -Filter 'trophynecromancy.ws')
    if($dependency.Count -ne 1){throw 'Expected exactly one Trophy Necromancy reference for compatibility compilation'}
    Copy-Item -LiteralPath $dependency[0].FullName -Destination (Join-Path $patchSource 'local\trophynecromancy.ws') -Force
    # This combined blob is verification only. Never ship the dependency's code.
}
$outputDir = Join-Path $repoRoot "build\$buildName"
New-Item -ItemType Directory -Force $outputDir,(Join-Path $repoRoot 'build\logs') | Out-Null
Push-Location (Split-Path $compiler -Parent)
try {
    & $compiler compilescripts ((Join-Path $GameRoot 'content\content0\scripts') + '\') "-patch=$patchSource\" "-out=$outputDir" 2>&1 | Tee-Object -FilePath (Join-Path $repoRoot "build\logs\compile-$buildName.log")
    if($LASTEXITCODE -ne 0){throw "Compiler exited $LASTEXITCODE"}
    if(!(Test-Path -LiteralPath (Join-Path $outputDir 'blob.rsblob'))){throw 'Compiler produced no blob'}
} finally {Pop-Location}
if(!$Diagnostics -and !$DamageTest -and !$CompatibilityCheck -and !$IntegrationTest){Copy-Item (Join-Path $outputDir 'blob.rsblob') (Join-Path $repoRoot 'mods\modShadowMonarch\content\precompiled.rsblob') -Force}

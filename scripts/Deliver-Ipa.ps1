[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SourceDirectory,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('\.ipa$')]
    [string]$SourceFileName,

    [Parameter(Mandatory = $true)]
    [string]$DestinationDirectory,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('\.ipa$')]
    [string]$DestinationFileName
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $SourceDirectory -PathType Container)) {
    throw "Source directory does not exist: $SourceDirectory"
}
if (-not (Test-Path -LiteralPath $DestinationDirectory -PathType Container)) {
    throw "Destination directory does not exist: $DestinationDirectory"
}

$sourceRoot = (Resolve-Path -LiteralPath $SourceDirectory).Path
$destinationRoot = (Resolve-Path -LiteralPath $DestinationDirectory).Path
$sourcePath = Join-Path -Path $sourceRoot -ChildPath $SourceFileName
$destinationPath = Join-Path -Path $destinationRoot -ChildPath $DestinationFileName

if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
    throw "IPA was not found: $sourcePath"
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead($sourcePath)
try {
    $appEntries = @($archive.Entries | Where-Object {
        $_.FullName -match '^Payload/[^/]+\.app/Info\.plist$'
    })
    if ($appEntries.Count -ne 1) {
        throw "IPA must contain exactly one Payload/*.app/Info.plist entry. Found: $($appEntries.Count)"
    }
}
finally {
    $archive.Dispose()
}

$temporaryName = ".{0}.{1}.tmp" -f $DestinationFileName, ([Guid]::NewGuid().ToString('N'))
$temporaryPath = Join-Path -Path $destinationRoot -ChildPath $temporaryName

try {
    Copy-Item -LiteralPath $sourcePath -Destination $temporaryPath -Force
    $sourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
    $temporaryHash = (Get-FileHash -LiteralPath $temporaryPath -Algorithm SHA256).Hash
    if ($sourceHash -ne $temporaryHash) {
        throw 'SHA-256 mismatch after staging the IPA.'
    }

    Copy-Item -LiteralPath $temporaryPath -Destination $destinationPath -Force
    $destinationHash = (Get-FileHash -LiteralPath $destinationPath -Algorithm SHA256).Hash
    if ($sourceHash -ne $destinationHash) {
        throw 'SHA-256 mismatch after delivering the IPA.'
    }

    $item = Get-Item -LiteralPath $destinationPath
    Write-Host "Delivered: $($item.FullName)"
    Write-Host "Size: $($item.Length) bytes"
    Write-Host "SHA256: $destinationHash"
}
finally {
    if (Test-Path -LiteralPath $temporaryPath) {
        Remove-Item -LiteralPath $temporaryPath -Force
    }
}


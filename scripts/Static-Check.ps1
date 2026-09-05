[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot

function Assert-Contains {
    param([string]$Path, [string]$Pattern, [string]$Description)
    $content = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    if ($content -notmatch $Pattern) {
        throw "Missing requirement: $Description ($Path)"
    }
}

$projectFile = Join-Path $projectRoot 'project.yml'
$uaFile = Join-Path $projectRoot 'MiniBrowser\Models\BrowserUserAgent.swift'
$viewModelFile = Join-Path $projectRoot 'MiniBrowser\ViewModels\BrowserViewModel.swift'
$webViewFile = Join-Path $projectRoot 'MiniBrowser\Web\BrowserWebView.swift'
$inputZoomFile = Join-Path $projectRoot 'MiniBrowser\Services\InputAutoZoomPreventionService.swift'
$infoFile = Join-Path $projectRoot 'MiniBrowser\Info.plist'
$workflowFile = Join-Path $projectRoot '.github\workflows\reusable-ios-unsigned-build-deliver.yml'

Assert-Contains $projectFile 'iOS:\s*"26\.0"' 'iOS 26 deployment target'
Assert-Contains $webViewFile 'WKWebViewConfiguration' 'WKWebView configuration'
Assert-Contains $webViewFile 'websiteDataStore\s*=\s*\.default\(\)' 'persistent website data store'
Assert-Contains $webViewFile 'InputAutoZoomPreventionService\.install' 'input focus auto-zoom prevention'
Assert-Contains $inputZoomFile 'fontSize\s*<\s*16' 'small input font-size guard'
Assert-Contains $inputZoomFile 'forMainFrameOnly:\s*false' 'input auto-zoom prevention in subframes'
Assert-Contains $viewModelFile 'CookieDomainMatcher' 'site-related cookie filter'
Assert-Contains $viewModelFile 'minibrowser://return' 'MiniBrowser callback URL'
Assert-Contains $viewModelFile 'evaluateJavaScript' 'bookmarklet execution'
Assert-Contains $workflowFile 'CODE_SIGNING_ALLOWED=NO' 'unsigned build'
Assert-Contains $workflowFile 'actions/download-artifact@v8' 'artifact download on Windows'

$uaText = Get-Content -LiteralPath $uaFile -Raw -Encoding UTF8
$uaCount = ([regex]::Matches($uaText, '\.init\(id:\s*\d+')).Count
if ($uaCount -ne 10) {
    throw "Expected exactly 10 user agents, found $uaCount."
}
$uaValues = [regex]::Matches($uaText, 'value:\s*"([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
if (($uaValues | Select-Object -Unique).Count -ne 10) {
    throw 'Expected 10 distinct user-agent strings.'
}
if ($uaValues -match 'CPU (iPhone )?OS 26_') {
    throw 'iOS 26 UA profiles must use the frozen iOS 18 OS token.'
}

[xml]$plist = Get-Content -LiteralPath $infoFile -Raw -Encoding UTF8
if ($plist.plist.dict.key -notcontains 'CFBundleURLTypes') {
    throw 'CFBundleURLTypes is missing from Info.plist.'
}
if ($plist.plist.dict.key -notcontains 'UISupportedInterfaceOrientations') {
    throw 'Portrait orientation declaration is missing from Info.plist.'
}

$inputZoomText = Get-Content -LiteralPath $inputZoomFile -Raw -Encoding UTF8
if ($inputZoomText -match 'maximum-scale|user-scalable|pinchGestureRecognizer') {
    throw 'Manual pinch zoom must remain enabled.'
}

$cookieValueLeaks = Get-ChildItem -LiteralPath (Join-Path $projectRoot 'MiniBrowser') -Filter '*.swift' -Recurse |
    Select-String -Pattern 'cookie\.value' -CaseSensitive:$false
if ($cookieValueLeaks) {
    throw 'Cookie values must not be accessed or logged.'
}

Write-Host 'Static checks passed.'
Write-Host "User agents: $uaCount"
Write-Host 'Distinct user-agent strings: 10'
Write-Host 'Cookie value access: none'
Write-Host 'Deployment target: iOS 26.0'

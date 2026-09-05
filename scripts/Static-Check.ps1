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
$focusModeFile = Join-Path $projectRoot 'MiniBrowser\Services\CompactPageModeService.swift'
$listServiceFile = Join-Path $projectRoot 'MiniBrowser\Services\ThreadListService.swift'
$listViewFile = Join-Path $projectRoot 'MiniBrowser\Views\ThreadListView.swift'
$listViewModelFile = Join-Path $projectRoot 'MiniBrowser\ViewModels\ThreadListViewModel.swift'
$infoFile = Join-Path $projectRoot 'MiniBrowser\Info.plist'
$workflowFile = Join-Path $projectRoot '.github\workflows\reusable-ios-unsigned-build-deliver.yml'
$specFile = Join-Path $projectRoot 'MiniBrowser_Codex_Spec.md'
$agentsFile = Join-Path $projectRoot 'AGENTS.md'

Assert-Contains $projectFile 'iOS:\s*"26\.0"' 'iOS 26 deployment target'
Assert-Contains $webViewFile 'WKWebViewConfiguration' 'WKWebView configuration'
Assert-Contains $webViewFile 'websiteDataStore\s*=\s*\.default\(\)' 'persistent website data store'
Assert-Contains $webViewFile 'InputAutoZoomPreventionService\.install' 'input focus auto-zoom prevention'
Assert-Contains $inputZoomFile 'fontSize\s*<\s*16' 'small input font-size guard'
Assert-Contains $inputZoomFile 'forMainFrameOnly:\s*false' 'input auto-zoom prevention in subframes'
Assert-Contains $focusModeFile 'MiniBrowser\.TargetPageDraftEnabled' 'global TargetPage draft setting'
Assert-Contains $focusModeFile 'clearEmail' 'empty TargetPage email guard'
Assert-Contains $focusModeFile 'fixedDeleteKey\s*=\s*"2310"' 'fixed TargetPage deletion key'
Assert-Contains $focusModeFile 'enforceDeleteKey' 'TargetPage deletion key enforcement'
Assert-Contains $focusModeFile 'textarea\.rows\s*=\s*2' 'compact TargetPage comment field'
Assert-Contains $focusModeFile 'disableFormPositionToggle' 'disabled TargetPage form position switch'
Assert-Contains $listServiceFile 'bytes=0-32767' 'bounded TargetPage opener request'
Assert-Contains $listServiceFile 'limit:\s*Int\s*=\s*60' 'sixty-item TargetPage list limit'
Assert-Contains $listServiceFile 'replyCount\s*<\s*1_000' 'completed TargetPage thread exclusion'
Assert-Contains $listViewModelFile 'listItemLimit\s*=\s*60' 'sixty-item TargetPage list request'
Assert-Contains $listViewModelFile 'mergingDisplayState' 'list thumbnail state preservation across refresh'
Assert-Contains $listViewFile 'LazyVGrid' 'native two-column TargetPage list'
Assert-Contains $listViewFile 'model\.recordOpen\(item\)' 'persistent TargetPage list open counter'
Assert-Contains $listViewFile 'thumbnailData' 'explicit TargetPage thumbnail rendering'
Assert-Contains $listServiceFile 'makeThumbnailRequest' 'explicit TargetPage thumbnail request'
Assert-Contains $focusModeFile 'modeHeader\.classList\.add' 'hidden TargetPage response-mode header'

$listViewModelText = Get-Content -LiteralPath $listViewModelFile -Raw -Encoding UTF8
if ($listViewModelText -match 'withTaskGroup|withThrowingTaskGroup') {
    throw 'TargetPage opener loading must avoid the task-group completion crash seen on iOS 26.5.2.'
}
Assert-Contains $viewModelFile 'CookieDomainMatcher' 'site-related cookie filter'
Assert-Contains $viewModelFile 'minibrowser://return' 'MiniBrowser callback URL'
Assert-Contains $viewModelFile 'evaluateJavaScript' 'bookmarklet execution'
Assert-Contains $workflowFile 'CODE_SIGNING_ALLOWED=NO' 'unsigned build'
Assert-Contains $workflowFile 'actions/download-artifact@v8' 'artifact download on Windows'
Assert-Contains $specFile '# MiniBrowser 実装仕様書' 'canonical product specification'
Assert-Contains $agentsFile 'project-maintainer/MiniBrowser' 'canonical repository rule'
Assert-Contains $agentsFile 'GitHub Issues' 'issue handoff rule'

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

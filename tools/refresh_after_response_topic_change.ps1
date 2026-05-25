param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [int]$KeepBackups = 3
)

$ErrorActionPreference = "Stop"

function Set-Utf8NoBom {
    param([string]$Path, [string]$Value)
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Value, $encoding)
}

function Get-Utf8Text {
    param([string]$Path)
    $encoding = New-Object System.Text.UTF8Encoding($false)
    return [System.IO.File]::ReadAllText($Path, $encoding)
}

function ConvertTo-PlainArray {
    param([object]$Value)
    if ($null -eq $Value) { return @() }
    return @($Value | ForEach-Object { [string]$_ })
}

function Get-Timestamp {
    return (Get-Date).ToString("yyyy_MM_dd_HH_mm_ss")
}

function New-CidyBackup {
    param(
        [string]$Root,
        [string]$Timestamp,
        [int]$KeepBackups
    )
    $backupRoot = Join-Path $Root "Backups"
    $backupDir = Join-Path $backupRoot "response_topic_update_$Timestamp"
    New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

    $files = @(
        "Cidy_Intent.yaml",
        "Cidy_Intent_Clarifier.yaml",
        "Cidy_Intent_Router.yaml",
        "Cidy_Intent_Variables_Defaults.json"
    )

    foreach ($file in $files) {
        $source = Join-Path $Root $file
        if (Test-Path $source) {
            Copy-Item -Path $source -Destination (Join-Path $backupDir $file) -Force
        }
    }

    Get-ChildItem -Path $backupRoot -Directory -Filter "response_topic_update_*" |
        Sort-Object LastWriteTime -Descending |
        Select-Object -Skip $KeepBackups |
        ForEach-Object { Remove-Item -LiteralPath $_.FullName -Recurse -Force }

    return $backupDir
}

function Sync-IntentAllowedTopicAreas {
    param(
        [string]$Root,
        [string[]]$TopicAreas
    )
    $intentPath = Join-Path $Root "Cidy_Intent.yaml"
    $defaultsPath = Join-Path $Root "Cidy_Intent_Variables_Defaults.json"
    $updates = New-Object System.Collections.Generic.List[string]

    $topicAreaText = ($TopicAreas -join ", ")
    $intentText = Get-Utf8Text $intentPath
    $pattern = '("Allowed topic_area values:"\s*&\s*Char\(10\)\s*&\s*\r?\n\s*")([^"]*)("\s*&\s*Char\(10\))'
    $intentUpdated = [regex]::Replace($intentText, $pattern, "`$1$topicAreaText`$3", 1)
    if ($intentUpdated -ne $intentText) {
        Set-Utf8NoBom -Path $intentPath -Value $intentUpdated
        $updates.Add("Updated Cidy_Intent.yaml allowed topic_area values.")
    }

    $defaults = Get-Utf8Text $defaultsPath | ConvertFrom-Json
    $currentDefaults = ConvertTo-PlainArray $defaults.variables.'Global.topicArea'.allowedValues
    $missingDefaults = @($TopicAreas | Where-Object { $_ -notin $currentDefaults })
    if ($missingDefaults.Count -gt 0 -or ($currentDefaults -join "|") -ne ($TopicAreas -join "|")) {
        $defaults.variables.'Global.topicArea'.allowedValues = @($TopicAreas)
        Set-Utf8NoBom -Path $defaultsPath -Value (($defaults | ConvertTo-Json -Depth 30) + [Environment]::NewLine)
        $updates.Add("Updated Cidy_Intent_Variables_Defaults.json Global.topicArea.allowedValues.")
    }

    return @($updates.ToArray())
}

function Get-InventoryTopicAreas {
    param([object]$Inventory)
    $base = @(
        "about_cidy",
        "budget_finance",
        "cd_strategy",
        "definition",
        "design_evaluation",
        "evaluation_criteria",
        "evaluation_design",
        "general",
        "governance_roles",
        "ipmr",
        "lessons_learned",
        "monitoring_reporting",
        "policy_compliance",
        "policy_guidance_compliance",
        "process_governance",
        "programme_design_standards",
        "programme_management",
        "project_planning_design",
        "recommendations",
        "reporting_documentation",
        "reports",
        "steering_committee",
        "tag",
        "tag_meetings",
        "templates",
        "unclear"
    )
    $fromFolders = @($Inventory.folders | ForEach-Object { $_.topicArea } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    return @($base + $fromFolders | Select-Object -Unique | Sort-Object)
}

function Get-TestSummary {
    param([string]$ResultsPath)
    if (-not (Test-Path $ResultsPath)) {
        return [ordered]@{ total = ""; passed = ""; failed = "" }
    }
    $results = Get-Content -Raw $ResultsPath | ConvertFrom-Json
    return $results.summary
}

function New-RefreshReport {
    param(
        [string]$Root,
        [string]$Timestamp,
        [string]$BackupDir,
        [object]$Inventory,
        [string[]]$IntentUpdates,
        [object]$TestSummary
    )
    $reportPath = Join-Path $Root ("documentation/test_case_$Timestamp.md")
    $changedResponseFiles = @(& git -C $Root diff --name-only -- "Formulate_Response_*.yaml")
    $newTopics = @($Inventory.folders | Where-Object { $_.isNewTopic } | Sort-Object yamlFile, topicArea)
    $newYamls = @($Inventory.domains | Where-Object { $_.isNewYaml } | Sort-Object yamlFile)
    $responseDiff = & git -C $Root diff -- "Formulate_Response_*.yaml"
    if (-not $responseDiff) { $responseDiff = "No uncommitted Formulate_Response_*.yaml diff was detected." }
    $backupRelative = $BackupDir.Replace($Root, "").TrimStart("\")
    $changedResponseText = if ($changedResponseFiles.Count) { $changedResponseFiles -join ", " } else { "None detected by git diff" }

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("# Cidy Response Topic Refresh - $Timestamp")
    $lines.Add("")
    $lines.Add("## Summary")
    $lines.Add("")
    $lines.Add("- Backup folder: $backupRelative")
    $lines.Add("- Response YAML files changed locally: $changedResponseText")
    $lines.Add("- New response YAMLs detected: $($newYamls.Count)")
    $lines.Add("- New topic mappings detected: $($newTopics.Count)")
    $lines.Add("- Intent/default config updates: $($IntentUpdates.Count)")
    $lines.Add("- Structural tests: total=$($TestSummary.total), passed=$($TestSummary.passed), failed=$($TestSummary.failed)")
    $lines.Add("")
    $lines.Add("## Intent And Config Updates")
    $lines.Add("")
    if ($IntentUpdates.Count) {
        foreach ($update in $IntentUpdates) { $lines.Add("- $update") }
    } else {
        $lines.Add("- No intent/default allowed-value updates were needed.")
    }
    $lines.Add("- Cidy_Intent_Clarifier.yaml: review manually if a new topic requires a new clarification option or artifact mapping.")
    $lines.Add("- Cidy_Intent_Router.yaml: review manually if a new Formulate_Response YAML introduces a new knowledge_domain or needs router wiring.")
    $lines.Add("")
    $lines.Add("## New Topics")
    $lines.Add("")
    if ($newTopics.Count) {
        foreach ($topic in $newTopics) {
            $lines.Add(("- {0} in {1} -> source {2}" -f $topic.topicArea, $topic.yamlFile, $topic.knowledgeSourceId))
        }
    } else {
        $lines.Add("- No new topic mappings detected.")
    }
    $lines.Add("")
    $lines.Add("## New YAMLs")
    $lines.Add("")
    if ($newYamls.Count) {
        foreach ($yaml in $newYamls) {
            $lines.Add(("- {0} for domain {1}" -f $yaml.yamlFile, $yaml.id))
        }
    } else {
        $lines.Add("- No new response YAML files detected.")
    }
    $lines.Add("")
    $lines.Add("## Formulate Response YAML Diff")
    $lines.Add("")
    $lines.Add('```diff')
    foreach ($line in @($responseDiff)) { $lines.Add($line) }
    $lines.Add('```')
    $lines.Add("")
    $lines.Add("## Next Review Checklist")
    $lines.Add("")
    $lines.Add('- Confirm `Cidy_Intent.yaml` classifier prompt includes any new topic_area values.')
    $lines.Add('- Confirm `Cidy_Intent_Variables_Defaults.json` includes any new topic_area values.')
    $lines.Add('- Confirm `Cidy_Intent_Clarifier.yaml` needs no new clarification choice or artifact mapping.')
    $lines.Add('- Confirm `Cidy_Intent_Router.yaml` needs no new domain route.')
    $lines.Add('- Review `documentation/cidy_intent_test_failures.json` for any new route or topic-area failures.')

    Set-Utf8NoBom -Path $reportPath -Value (($lines.ToArray() -join [Environment]::NewLine) + [Environment]::NewLine)
    return $reportPath
}

$timestamp = Get-Timestamp
$backupDir = New-CidyBackup -Root $Root -Timestamp $timestamp -KeepBackups $KeepBackups

& (Join-Path $Root "tools/generate_knowledge_inventory.ps1") -CompareWithGitRef HEAD
if ($LASTEXITCODE -ne 0) { throw "generate_knowledge_inventory.ps1 failed." }

$inventoryPath = Join-Path $Root "documentation/cidy_knowledge_inventory.json"
$inventory = Get-Content -Raw $inventoryPath | ConvertFrom-Json
$topicAreas = Get-InventoryTopicAreas -Inventory $inventory
$intentUpdates = Sync-IntentAllowedTopicAreas -Root $Root -TopicAreas $topicAreas

& (Join-Path $Root "tools/generate_knowledge_inventory.ps1") -CompareWithGitRef HEAD
if ($LASTEXITCODE -ne 0) { throw "generate_knowledge_inventory.ps1 failed after intent sync." }

& (Join-Path $Root "tools/run_intent_test_cases.ps1")
if ($LASTEXITCODE -ne 0) { throw "run_intent_test_cases.ps1 failed." }

$testSummary = Get-TestSummary -ResultsPath (Join-Path $Root "documentation/cidy_intent_test_results.json")
$inventory = Get-Content -Raw $inventoryPath | ConvertFrom-Json
$reportPath = New-RefreshReport -Root $Root -Timestamp $timestamp -BackupDir $backupDir -Inventory $inventory -IntentUpdates $intentUpdates -TestSummary $testSummary

Write-Host "Created backup: $backupDir"
Write-Host "Updated generated inventory and intent defaults."
Write-Host "Ran structural intent tests."
Write-Host "Wrote report: $reportPath"

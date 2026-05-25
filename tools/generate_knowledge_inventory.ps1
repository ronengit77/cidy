param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [switch]$NoHtmlEmbed
)

$ErrorActionPreference = "Stop"

function ConvertTo-Slug {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return "" }
    return (($Value.Trim().ToLowerInvariant() -replace "&", " and " -replace "[^a-z0-9]+", "_").Trim("_"))
}

function ConvertTo-Title {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return "" }
    $words = ($Value -replace "_", " ").Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)
    (($words | ForEach-Object { $_.Substring(0, 1).ToUpperInvariant() + $_.Substring(1) }) -join " ")
}

function Get-ExpectedYaml {
    param([string]$DomainId)
    if ($DomainId -eq "pdf") { return "Formulate_Response_PDF.yaml" }
    if ($DomainId -eq "da") { return "Formulate_Response_DA.yaml" }
    if ($DomainId -eq "rptc") { return "Formulate_Response_RPTC.yaml" }
    $suffix = ConvertTo-Title $DomainId
    $suffix = $suffix -replace "[^A-Za-z0-9]+", "_"
    return "Formulate_Response_$suffix.yaml"
}

function Get-DomainFromResponseFile {
    param([string]$FileName)
    $suffix = [IO.Path]::GetFileNameWithoutExtension($FileName) -replace "^Formulate_Response_", ""
    return ConvertTo-Slug $suffix
}

function Get-ResponseTopicAlias {
    param([string]$Dialog)
    if ($Dialog -eq "copilots_header_3141e.topic.DA") { return "da" }
    if ($Dialog -eq "copilots_header_3141e.topic.FormulateResponseCopy") { return "rptc" }
    if ($Dialog -eq "copilots_header_3141e.topic.FormulateResponse") { return "pdf" }
    $last = ($Dialog -split "\.")[-1]
    return ConvertTo-Slug ($last -replace "^FormulateResponse", "")
}

function Get-RouterDomains {
    param([string]$RouterPath)
    $text = Get-Content -Raw $RouterPath
    $domains = @{}
    $pattern = '(?ms)- id: conditionItem_route(?<route>[A-Za-z0-9]+).*?condition:\s*=(?<condition>[^\r\n]+).*?(?=(?:\r?\n\s*- id: conditionItem_route)|(?:\r?\n\s*elseActions:)|\z)'
    foreach ($match in [regex]::Matches($text, $pattern)) {
        $condition = $match.Groups["condition"].Value
        $domainId = $null
        $fundingStream = "UNCLEAR"
        if ($condition -match 'Global\.knowledgeDomain\s*=\s*"([^"]+)"') {
            $domainId = $Matches[1]
        }
        if ($condition -match 'Global\.fundingStream\s*=\s*"([^"]+)"') {
            $fundingStream = $Matches[1]
        }
        if (-not $domainId) { continue }

        $block = $match.Value
        $routingTarget = ""
        if ($block -match '(?m)^\s*value:\s*(Formulate Response [^\r\n]+|User Feedback)\s*$') {
            $routingTarget = $Matches[1].Trim()
        }
        if ($routingTarget -eq "User Feedback") { continue }
        $dialog = ""
        if ($block -match 'dialog:\s*(copilots_header_3141e\.topic\.[A-Za-z0-9_-]+)') {
            $dialog = $Matches[1]
        }

        $domains[$domainId] = [ordered]@{
            id           = $domainId
            label        = if ($routingTarget -match '^Formulate Response (.+)$') { $Matches[1] } else { ConvertTo-Title $domainId }
            fundingStream = $fundingStream
            routerStatus = if ($dialog) { "wired" } else { "not_wired" }
            routerDialog = $dialog
            yamlFile     = ""
            notes        = if ($dialog) { "Discovered from Cidy_Intent_Router.yaml." } else { "Router currently sends a temporary not-developed message or ends without a response YAML." }
        }
    }
    return $domains
}

function Get-SourceUseInstruction {
    param([string]$Block)
    if ($Block -notmatch 'variable:\s*Global\.sourceUseInstructions') { return "" }
    $lines = $Block -split "`r?`n"
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*value:\s*(.*)$') {
            $first = $Matches[1]
            if ($first -eq "|-" -or $first -eq "|") {
                $collected = New-Object System.Collections.Generic.List[string]
                for ($j = $i + 1; $j -lt $lines.Count; $j++) {
                    if ($lines[$j] -match '^\s{16,}\S') {
                        $collected.Add(($lines[$j] -replace '^\s{16}', '' -replace '^\s+', ''))
                    } elseif ($collected.Count -gt 0 -and $lines[$j] -match '^\s*$') {
                        $collected.Add("")
                    } elseif ($collected.Count -gt 0) {
                        break
                    }
                }
                return (($collected.ToArray() -join " ") -replace "\s+", " ").Trim()
            }
            return ($first.Trim().Trim('"') -replace "\s+", " ")
        }
    }
    return ""
}

function Get-KnowledgeSources {
    param([string]$Block)
    $sources = [regex]::Matches($Block, '(?m)^\s*-\s+(copilots_header_3141e\.topic\.[A-Za-z0-9_]+)\s*$') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
    return @($sources)
}

function Get-SourceLabels {
    param([string[]]$Sources)
    return @($Sources | ForEach-Object {
        $last = ($_ -split "\.")[-1]
        $label = $last -replace "_[A-Za-z0-9-]{8,}$", ""
        $label = $label -replace '(?<=[a-z])and(?=[A-Z])', 'And'
        $chunks = [regex]::Matches($label, '[A-Z]+(?=[A-Z][a-z]|$)|[A-Z]?[a-z]+|[0-9]+') | ForEach-Object {
            $chunk = $_.Value
            if ($chunk -cmatch '^[A-Z0-9]+$') { $chunk } else { $_.Value.Substring(0, 1).ToUpperInvariant() + $_.Value.Substring(1) }
        }
        if ($chunks.Count -gt 0) { ($chunks -join " ") } else { $label }
    })
}

function Get-FoldersFromResponseYaml {
    param(
        [string]$Path,
        [string]$DomainId,
        [string]$RouterStatus
    )
    $fileName = Split-Path $Path -Leaf
    $text = Get-Content -Raw $Path
    $folders = New-Object System.Collections.Generic.List[object]
    $conditionMatches = [regex]::Matches($text, '(?ms)- id: (?<id>[A-Za-z0-9_]+).*?condition:\s*=Global\.topicArea\s*=\s*"(?<topicArea>[^"]+)".*?(?=(?:\r?\n\s*- id: conditionItem_)|(?:\r?\n\s*elseActions:)|\z)')

    foreach ($match in $conditionMatches) {
        $topicArea = $match.Groups["topicArea"].Value
        $block = $match.Value
        $sources = Get-KnowledgeSources $block
        if ($sources.Count -eq 0) { continue }
        $instructions = Get-SourceUseInstruction $block
        $status = "mapped"
        if ($RouterStatus -eq "not_wired") { $status = "yaml_exists_not_wired" }
        if ($DomainId -eq "programme_development") { $status = "review_required" }
        if ($DomainId -eq "rptc" -and @("policy_compliance", "reporting_documentation", "process_governance", "design_evaluation", "definition") -contains $topicArea) {
            $status = "mapped_needs_topic_area_alignment"
        }
        $folderName = ConvertTo-Title $topicArea
        $sourceLabels = Get-SourceLabels $sources
        $folders.Add([ordered]@{
            id                = "$(ConvertTo-Slug $DomainId)_$(ConvertTo-Slug $topicArea)"
            domain            = $DomainId
            topicArea         = $topicArea
            topicName         = ConvertTo-Title $topicArea
            folderName        = $folderName
            knowledgeSourceId = ($sources -join "; ")
            sourceIds         = @($sources)
            sourceLabels      = @($sourceLabels)
            sourceCount       = $sources.Count
            yamlConditionId   = $match.Groups["id"].Value
            yamlFile          = $fileName
            generatedFromYaml = $true
            sourceUseInstructionSource = if ($instructions) { "Global.sourceUseInstructions" } else { "" }
            mappingStatus     = $status
            ownerUnit         = "TBD"
            instructions      = if ($instructions) { $instructions } else { "No separate source-use instruction variable is currently set in this YAML branch." }
        })
    }

    if ($conditionMatches.Count -eq 0) {
        $sources = Get-KnowledgeSources $text
        if ($sources.Count -gt 0) {
            $sourceLabels = Get-SourceLabels $sources
            $folders.Add([ordered]@{
                id                = "$(ConvertTo-Slug $DomainId)_general"
                domain            = $DomainId
                topicArea         = "general"
                topicName         = "General"
                folderName        = "$(ConvertTo-Title $DomainId) General"
                knowledgeSourceId = ($sources -join "; ")
                sourceIds         = @($sources)
                sourceLabels      = @($sourceLabels)
                sourceCount       = $sources.Count
                yamlConditionId   = ""
                yamlFile          = $fileName
                generatedFromYaml = $true
                sourceUseInstructionSource = ""
                mappingStatus     = if ($RouterStatus -eq "not_wired") { "yaml_exists_not_wired" } else { "mapped" }
                ownerUnit         = "TBD"
                instructions      = "No separate source-use instruction variable is currently set in this YAML."
            })
        }
    }

    $fallbackSources = @()
    if ($text -match '(?ms)elseActions:.*?knowledgeSources:\s*\r?\n\s+kind: SearchSpecificKnowledgeSources\s*\r?\n\s+knowledgeSources:\s*\r?\n(?<sources>(?:\s+- copilots_header_3141e\.topic\.[A-Za-z0-9_]+\s*\r?\n?)+)') {
        $fallbackSources = Get-KnowledgeSources $Matches["sources"]
    }
    if ($fallbackSources.Count -gt 0) {
        $fallbackId = "$(ConvertTo-Slug $DomainId)_fallback"
        if (-not ($folders | Where-Object { $_.knowledgeSourceId -eq ($fallbackSources -join "; ") -and $_.topicArea -eq "general" })) {
            $sourceLabels = Get-SourceLabels $fallbackSources
            $folders.Add([ordered]@{
                id                = $fallbackId
                domain            = $DomainId
                topicArea         = "general"
                topicName         = "General"
                folderName        = "$(ConvertTo-Title $DomainId) Fallback"
                knowledgeSourceId = ($fallbackSources -join "; ")
                sourceIds         = @($fallbackSources)
                sourceLabels      = @($sourceLabels)
                sourceCount       = $fallbackSources.Count
                yamlConditionId   = "elseActions"
                yamlFile          = $fileName
                generatedFromYaml = $true
                sourceUseInstructionSource = ""
                mappingStatus     = "fallback"
                ownerUnit         = "TBD"
                instructions      = "Fallback knowledge source used when no specific branch applies or when the draft response is blank."
            })
        }
    }
    return @($folders.ToArray())
}

function Merge-ById {
    param(
        [array]$Generated,
        [array]$Overrides,
        [string[]]$Fields
    )
    if (-not $Overrides) { return $Generated }
    $overrideById = @{}
    foreach ($item in $Overrides) {
        if ($item.id) { $overrideById[$item.id] = $item }
    }
    foreach ($item in $Generated) {
        if ($overrideById.ContainsKey($item.id)) {
            foreach ($field in $Fields) {
                if ($null -ne $overrideById[$item.id].$field -and $overrideById[$item.id].$field -ne "") {
                    $item[$field] = $overrideById[$item.id].$field
                }
            }
        }
    }
    return $Generated
}

function Set-Utf8NoBom {
    param(
        [string]$Path,
        [string]$Value
    )
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Value, $encoding)
}

$documentationDir = Join-Path $Root "documentation"
$inventoryPath = Join-Path $documentationDir "cidy_knowledge_inventory.json"
$overridesPath = Join-Path $documentationDir "cidy_knowledge_overrides.json"
$htmlPath = Join-Path $documentationDir "cidy_knowledge_control_center.html"
$routerPath = Join-Path $Root "Cidy_Intent_Router.yaml"

$previous = $null
if (Test-Path $inventoryPath) {
    $previous = Get-Content -Raw $inventoryPath | ConvertFrom-Json
}
$overrides = $null
if (Test-Path $overridesPath) {
    $overrides = Get-Content -Raw $overridesPath | ConvertFrom-Json
}

$routerDomains = Get-RouterDomains $routerPath
$responseFiles = Get-ChildItem -Path $Root -Filter "Formulate_Response_*.yaml" | Sort-Object Name
$responseDomainByFile = @{}

foreach ($file in $responseFiles) {
    $domainId = Get-DomainFromResponseFile $file.Name
    if ($domainId -eq "rptc") { $domainId = "rptc" }
    if ($domainId -eq "general" -and $routerDomains.ContainsKey("general_cd")) { $domainId = "general_cd" }
    $responseDomainByFile[$file.Name] = $domainId
    if (-not $routerDomains.ContainsKey($domainId)) {
        $routerDomains[$domainId] = [ordered]@{
            id            = $domainId
            label         = ConvertTo-Title $domainId
            fundingStream = "UNCLEAR"
            routerStatus  = "not_wired"
            routerDialog  = ""
            yamlFile      = $file.Name
            notes         = "Response YAML exists, but no matching router branch was discovered."
        }
    }
}

foreach ($domain in $routerDomains.Values) {
    if (-not $domain.yamlFile) {
        $matchedFile = $null
        foreach ($fileName in $responseDomainByFile.Keys) {
            if ($responseDomainByFile[$fileName] -eq $domain.id) { $matchedFile = $fileName }
        }
        if ($matchedFile) {
            $domain.yamlFile = $matchedFile
            if ($domain.routerStatus -eq "not_wired") { $domain.routerStatus = "not_wired" }
        } elseif ($domain.routerDialog) {
            $alias = Get-ResponseTopicAlias $domain.routerDialog
            $candidate = Get-ChildItem -Path $Root -Filter "Formulate_Response_*.yaml" | Where-Object { (Get-DomainFromResponseFile $_.Name) -eq $alias } | Select-Object -First 1
            if ($candidate) {
                $domain.yamlFile = $candidate.Name
            } else {
                $domain.yamlFile = Get-ExpectedYaml $domain.id
                $domain.routerStatus = "missing_yaml"
                $domain.notes = "Router calls $($domain.routerDialog), but no matching response YAML was discovered."
            }
        } else {
            $domain.yamlFile = Get-ExpectedYaml $domain.id
        }
    }
    if ($domain.routerStatus -eq "not_wired" -and -not (Test-Path (Join-Path $Root $domain.yamlFile))) {
        $domain.routerStatus = "missing_yaml"
        $domain.notes = "Router recognizes this domain, but no response YAML was discovered."
    }
}

$domains = @($routerDomains.Values | Sort-Object id)
$folders = New-Object System.Collections.Generic.List[object]
foreach ($file in $responseFiles) {
    $domainId = $responseDomainByFile[$file.Name]
    $domain = $domains | Where-Object { $_.id -eq $domainId } | Select-Object -First 1
    $routerStatus = if ($domain) { $domain.routerStatus } else { "not_wired" }
    foreach ($folder in (Get-FoldersFromResponseYaml -Path $file.FullName -DomainId $domainId -RouterStatus $routerStatus)) {
        $folders.Add($folder)
    }
}

$knownGaps = New-Object System.Collections.Generic.List[object]
foreach ($domain in $domains) {
    if ($domain.routerStatus -eq "missing_yaml") {
        $knownGaps.Add([ordered]@{
            id          = "missing_$($domain.id)_yaml"
            severity    = "high"
            title       = "Create $($domain.label) response YAML"
            yamlFile    = $domain.yamlFile
            description = $domain.notes
        })
    }
    if ($domain.routerStatus -eq "not_wired") {
        $knownGaps.Add([ordered]@{
            id          = "$($domain.id)_not_wired"
            severity    = "medium"
            title       = "Wire $($domain.label) route"
            yamlFile    = "Cidy_Intent_Router.yaml"
            description = "Response YAML exists or is expected, but the router does not currently call it."
        })
    }
}
if ($folders | Where-Object { $_.mappingStatus -eq "mapped_needs_topic_area_alignment" }) {
    $knownGaps.Add([ordered]@{
        id          = "rptc_topic_area_alignment"
        severity    = "high"
        title       = "Align RPTC topic-area values"
        yamlFile    = "Cidy_Intent.yaml; Cidy_Intent_Clarifier.yaml; Formulate_Response_RPTC.yaml"
        description = "RPTC response topic-area conditions differ from classifier/clarifier topic-area values."
    })
}
if ($folders | Where-Object { $_.mappingStatus -eq "review_required" }) {
    $knownGaps.Add([ordered]@{
        id          = "programme_development_sources_review"
        severity    = "medium"
        title       = "Review Programme Development source IDs"
        yamlFile    = "Formulate_Response_Programme_Development.yaml"
        description = "Programme Development YAML has folders/sources that require human validation."
    })
}

$managerUpdates = @()
if ($overrides -and $overrides.managerUpdates) {
    $managerUpdates = @($overrides.managerUpdates)
} elseif ($previous -and $previous.managerUpdates) {
    $managerUpdates = @($previous.managerUpdates)
}

$domainOverrides = if ($overrides) { @($overrides.domainOverrides) } else { @() }
$folderOverrides = if ($overrides) { @($overrides.folderOverrides) } else { @() }
$domains = Merge-ById -Generated $domains -Overrides $domainOverrides -Fields @("label", "fundingStream", "notes", "ownerUnit")
$folderArray = Merge-ById -Generated @($folders.ToArray()) -Overrides $folderOverrides -Fields @("folderName", "ownerUnit", "instructions", "mappingStatus", "notes")

$inventory = [ordered]@{
    schemaVersion  = "1.1"
    generatedAt    = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssK")
    generatedFrom  = @("Cidy_Intent_Router.yaml") + @($responseFiles.Name)
    domains        = $domains
    folders        = $folderArray
    knownGaps      = @($knownGaps.ToArray() | Sort-Object id)
    managerUpdates = $managerUpdates
}

$json = $inventory | ConvertTo-Json -Depth 20
Set-Utf8NoBom -Path $inventoryPath -Value ($json + [Environment]::NewLine)

if (-not $NoHtmlEmbed -and (Test-Path $htmlPath)) {
    $html = Get-Content -Raw $htmlPath
    $replacement = "<script id=""embeddedInventory"" type=""application/json"">`r`n$json`r`n  </script>"
    $html = [regex]::Replace($html, '(?s)<script id="embeddedInventory" type="application/json">.*?</script>', [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $replacement })
    Set-Utf8NoBom -Path $htmlPath -Value $html
}

Write-Host "Updated documentation/cidy_knowledge_inventory.json"
if (-not $NoHtmlEmbed) {
    Write-Host "Updated embedded inventory in documentation/cidy_knowledge_control_center.html"
}

param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$TestCasesPath = "documentation/Cidy_Intent_Test_Cases_60.json",
    [string]$InventoryPath = "documentation/cidy_knowledge_inventory.json",
    [string]$ResultsPath = "documentation/cidy_intent_test_results.json",
    [string]$FailuresPath = "documentation/cidy_intent_test_failures.json"
)

$ErrorActionPreference = "Stop"

function Set-Utf8NoBom {
    param([string]$Path, [string]$Value)
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Value, $encoding)
}

function ConvertTo-Slug {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return "" }
    return (($Value.Trim().ToLowerInvariant() -replace "&", " and " -replace "[^a-z0-9]+", "_").Trim("_"))
}

function Add-Failure {
    param(
        [System.Collections.Generic.List[object]]$Failures,
        [string]$Type,
        [string]$Point,
        [string]$Message
    )
    $Failures.Add([ordered]@{
        type    = $Type
        point   = $Point
        message = $Message
    })
}

function Get-RoutePathText {
    param([object[]]$Trace)
    $topics = @($Trace | ForEach-Object { $_.topic } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    return ($topics -join " > ")
}

function First-Match {
    param(
        [string]$Text,
        [string[]]$Patterns
    )
    foreach ($pattern in $Patterns) {
        if ($Text -match $pattern) { return $Matches[1] }
    }
    return ""
}

function Infer-Domain {
    param(
        [string]$Scenario,
        [string]$Question,
        [string]$Expected,
        [string]$Clarification
    )
    $text = "$Scenario $Question $Expected $Clarification".ToLowerInvariant()
    $explicit = First-Match $Expected @('knowledge[_ ]domain\s*=\s*([a-z0-9_]+)')
    if ($explicit) { return $explicit }

    if ($text -match "out_of_scope|out of scope|weather|world cup|poem|laptop|stock") { return "out_of_scope" }
    if ($text -match "project evaluation evidence|routes? to project evaluation evidence|routes? directly to formulate response project evaluation evidence|evaluations say|evaluations said|evaluation reports say|lessons learned|recommendations from project evaluations|past project evaluations") { return "programme_development" }
    if ($text -match "formulate response da|routes? (directly )?to da|routes? (directly )?to formulate response da") { return "da" }
    if ($text -match "formulate response rptc|routes? (directly )?to rptc") { return "rptc" }
    if ($text -match "formulate response pdf|routes? (directly )?to pdf") { return "pdf" }
    if ($text -match "programme development|steering committee|tag meeting|tag materials|capacity development strategy") { return "programme_development" }
    if ($text -match "about cidy|how does cidy work|knowledge sources does cidy|maintains cidy") { return "about_cidy" }
    if ($text -match "unpdf|pdf|peace and development") { return "pdf" }
    if ($text -match "rptc|regular programme") { return "rptc" }
    if ($text -match "\bda\b|development account|section 35") { return "da" }
    if ($text -match "general_cd") { return "general_cd" }
    return "unclear"
}

function Infer-FundingStream {
    param(
        [string]$Expected,
        [string]$Clarification,
        [string]$Domain
    )
    $explicit = First-Match $Expected @('funding[_ ]stream\s*=\s*([A-Z]+)')
    if ($explicit) { return $explicit }
    $text = "$Expected $Clarification".ToLowerInvariant()
    if ($Domain -eq "da" -or $text -match "\bda\b|development account") { return "DA" }
    if ($Domain -eq "rptc" -or $text -match "rptc|regular programme") { return "RPTC" }
    if ($Domain -eq "pdf" -or $text -match "unpdf|pdf") { return "PDF" }
    return "UNCLEAR"
}

function Infer-TopicAreas {
    param(
        [string]$Scenario,
        [string]$Question,
        [string]$Expected,
        [string]$Clarification,
        [string]$Domain
    )
    $text = "$Scenario $Question $Expected $Clarification".ToLowerInvariant()
    $areas = New-Object System.Collections.Generic.List[string]
    foreach ($match in [regex]::Matches($Expected, 'topic[_ ]area\s*=\s*([a-z0-9_]+)')) {
        $areas.Add($match.Groups[1].Value)
    }
    if ($text -match "eligibility_budget") { $areas.Add("eligibility_budget") }
    if ($text -match "project_planning_design|concept note|project document|project design|reviewing concept notes|new da project") { $areas.Add("project_planning_design") }
    if ($text -match "monitoring_reporting|monitoring and reporting|progress report") { $areas.Add("monitoring_reporting") }
    if ($text -match "budget_finance|budget and finance|travel costs|eligible") { $areas.Add("budget_finance") }
    if ($text -match "evaluation_design|terminal evaluation|evaluation report template|designing an evaluation|evaluation template|management response") { $areas.Add("evaluation_design") }
    if ($text -match "templates|template") { $areas.Add("templates") }
    if ($text -match "recommendations") { $areas.Add("recommendations") }
    if ($text -match "lessons_learned|lessons learned") { $areas.Add("lessons_learned") }
    if ($text -match "evaluation_evidence|actual evaluation evidence|recurring findings|evaluations said|evaluations say|evaluation reports say|partnerships|project evaluation evidence|project evaluations|lessons learned") { $areas.Add("projects_evaluations") }
    if ($text -match "cd_strategy|capacity development strategy") { $areas.Add("cd_strategy") }
    if ($text -match "steering_committee|steering committee") { $areas.Add("steering_committee") }
    if ($text -match "tag_meetings|tag meeting|tag materials") { $areas.Add("tag_meetings") }
    if ($text -match "governance_roles|governance|roles and responsibilities") { $areas.Add("governance_roles") }
    if ($text -match "programme_design_standards|programme design standards") { $areas.Add("programme_design_standards") }
    if ($text -match "evaluation_criteria|evaluation criteria") { $areas.Add("evaluation_criteria") }
    if ($text -match "\breports\b|reporting requirements|guidance on rptc reports") { $areas.Add("reports") }
    if ($text -match "policy_guidance_compliance") { $areas.Add("policy_guidance_compliance") }
    if ($text -match "general") { $areas.Add("general") }

    if ($areas.Count -eq 0) {
        if ($Domain -eq "out_of_scope") { return @("out_of_scope") }
        return @("unclear")
    }
    return @($areas.ToArray() | Select-Object -Unique)
}

function Infer-ClarificationType {
    param(
        [string]$Scenario,
        [string]$Question,
        [string]$Expected,
        [string]$Clarification
    )
    $text = "$Scenario $Question $Expected".ToLowerInvariant()
    if ($text -match "requires[_ ]clarification\s*=\s*no|no clarification") { return "none" }
    if ($text -match "requires[_ ]clarification\s*=\s*yes|classifier asks|should ask|clarification path|vague path") {
        if ($text -match "fund clarification|clarification_type=fund|\bfund\b") { return "fund" }
        if ($text -match "domain clarification|clarification_type=domain|\bdomain\b") { return "domain" }
        if ($text -match "artifact clarification|clarification_type=artifact|\bartifact\b|template|document type") { return "artifact" }
        if ($Clarification -match "Development Account|RPTC|UNPDF|PDF|DA|Not sure") { return "fund_or_domain" }
        return "unknown"
    }
    if ([string]::IsNullOrWhiteSpace($Clarification)) { return "none" }
    return "unknown"
}

function Apply-Clarification {
    param(
        [string]$Clarification,
        [string]$Domain,
        [string]$FundingStream,
        [string[]]$TopicAreas
    )
    $result = [ordered]@{
        domain        = $Domain
        fundingStream = $FundingStream
        topicAreas    = @($TopicAreas)
        outcome       = "not_applicable"
    }
    if ([string]::IsNullOrWhiteSpace($Clarification)) { return $result }
    $clar = $Clarification.ToLowerInvariant()
    $result.outcome = "applied"

    if ($clar -match "attempt 1.*invalid.*attempt 2.*development account") {
        $result.domain = "da"
        $result.fundingStream = "DA"
        $result.outcome = "second_attempt_succeeds"
        return $result
    }
    if ($clar -match "attempt 1.*random.*attempt 2.*random|still random") {
        $result.domain = "dead_end"
        $result.fundingStream = "UNCLEAR"
        $result.outcome = "max_attempts_dead_end"
        return $result
    }
    if ($clar -match "development account|\bda\b") {
        $result.domain = "da"
        $result.fundingStream = "DA"
    } elseif ($clar -match "rptc|regular programme") {
        $result.domain = "rptc"
        $result.fundingStream = "RPTC"
    } elseif ($clar -match "unpdf|pdf|peace and development") {
        $result.domain = "pdf"
        $result.fundingStream = "PDF"
    } elseif ($clar -match "programme development") {
        $result.domain = "programme_development"
        $result.fundingStream = "UNCLEAR"
    } elseif ($clar -match "project evaluations|lessons learned") {
        $result.domain = "programme_development"
        $result.fundingStream = "UNCLEAR"
        $result.topicAreas = @("projects_evaluations")
    } elseif ($clar -match "about cidy") {
        $result.domain = "about_cidy"
        $result.fundingStream = "UNCLEAR"
        $result.topicAreas = @("about_cidy")
    } elseif ($clar -match "concept note") {
        $result.topicAreas = @("project_planning_design")
    } elseif ($clar -match "evaluation report|management response") {
        $result.topicAreas = @("evaluation_design")
    } elseif ($clar -match "progress report") {
        $result.topicAreas = @("monitoring_reporting")
    } elseif ($clar -match "not sure") {
        $result.domain = "general_cd"
        $result.fundingStream = "UNCLEAR"
        $result.topicAreas = @("general")
    }
    return $result
}

function Get-Route {
    param(
        [string]$Domain,
        [string]$FundingStream,
        [object[]]$Domains
    )
    if ($Domain -eq "dead_end") {
        return [ordered]@{
            routingTarget = "User Feedback"
            routerDialog  = "copilots_header_3141e.topic.UserFeedback2"
            yamlFile      = ""
            routerStatus  = "dead_end"
            finalTopic    = "user_feedback.yaml"
        }
    }
    if ($Domain -eq "out_of_scope") {
        return [ordered]@{
            routingTarget = "User Feedback"
            routerDialog  = "copilots_header_3141e.topic.UserFeedback2"
            yamlFile      = ""
            routerStatus  = "out_of_scope"
            finalTopic    = "user_feedback.yaml"
        }
    }
    $domainObj = $Domains | Where-Object { $_.id -eq $Domain } | Select-Object -First 1
    if (-not $domainObj -and $FundingStream -eq "DA") { $domainObj = $Domains | Where-Object { $_.id -eq "da" } | Select-Object -First 1 }
    if (-not $domainObj -and $FundingStream -eq "RPTC") { $domainObj = $Domains | Where-Object { $_.id -eq "rptc" } | Select-Object -First 1 }
    if (-not $domainObj -and $FundingStream -eq "PDF") { $domainObj = $Domains | Where-Object { $_.id -eq "pdf" } | Select-Object -First 1 }
    if (-not $domainObj) {
        return [ordered]@{
            routingTarget = "Unknown"
            routerDialog  = ""
            yamlFile      = ""
            routerStatus  = "topic_not_found"
            finalTopic    = ""
        }
    }
    return [ordered]@{
        routingTarget = "Formulate Response $($domainObj.label)"
        routerDialog  = $domainObj.routerDialog
        yamlFile      = $domainObj.yamlFile
        routerStatus  = $domainObj.routerStatus
        finalTopic    = $domainObj.yamlFile
    }
}

function Test-TopicAreaMapped {
    param(
        [string]$Domain,
        [string[]]$TopicAreas,
        [object[]]$Folders
    )
    if ($Domain -in @("out_of_scope", "dead_end", "about_cidy", "pdf")) {
        return [ordered]@{ mapped = $true; matched = @(); unmapped = @() }
    }
    $domainFolders = @($Folders | Where-Object { $_.domain -eq $Domain })
    $mappedAreas = @($domainFolders | ForEach-Object { $_.topicArea } | Select-Object -Unique)
    $unmapped = New-Object System.Collections.Generic.List[string]
    $matched = New-Object System.Collections.Generic.List[string]
    foreach ($area in $TopicAreas) {
        if ($area -in @("unclear", "out_of_scope")) { continue }
        if ($mappedAreas -contains $area) { $matched.Add($area) }
        else { $unmapped.Add($area) }
    }
    if ($matched.Count -gt 0) {
        return [ordered]@{
            mapped   = $true
            matched  = @($matched.ToArray())
            unmapped = @($unmapped.ToArray())
        }
    }
    return [ordered]@{
        mapped   = ($unmapped.Count -eq 0)
        matched  = @($matched.ToArray())
        unmapped = @($unmapped.ToArray())
    }
}

$testPath = Join-Path $Root $TestCasesPath
$inventoryFile = Join-Path $Root $InventoryPath
$resultsFile = Join-Path $Root $ResultsPath
$failuresFile = Join-Path $Root $FailuresPath

$testData = Get-Content -Raw $testPath | ConvertFrom-Json
$inventory = Get-Content -Raw $inventoryFile | ConvertFrom-Json
$domains = @($inventory.domains)
$folders = @($inventory.folders)

$results = New-Object System.Collections.Generic.List[object]
$failuresOnly = New-Object System.Collections.Generic.List[object]
$index = 0

foreach ($case in $testData.testCases) {
    $index++
    $scenario = $case.Scenario
    $question = $case.'Test question'
    $clarification = $case.Clarification
    $expected = $case.'Expected behavior'
    $caseFailures = New-Object System.Collections.Generic.List[object]

    $initialDomain = Infer-Domain -Scenario $scenario -Question $question -Expected $expected -Clarification ""
    $initialFunding = Infer-FundingStream -Expected $expected -Clarification "" -Domain $initialDomain
    $initialAreas = Infer-TopicAreas -Scenario $scenario -Question $question -Expected $expected -Clarification "" -Domain $initialDomain
    $clarificationType = Infer-ClarificationType -Scenario $scenario -Question $question -Expected $expected -Clarification $clarification

    if ($initialDomain -eq "unclear" -and $clarificationType -eq "none") {
        Add-Failure $caseFailures "classification_failed" "Intent Classifier" "Could not infer intended domain from expected behavior."
    }

    $afterClarification = Apply-Clarification -Clarification $clarification -Domain $initialDomain -FundingStream $initialFunding -TopicAreas $initialAreas
    $awaitingClarification = ($clarificationType -ne "none" -and [string]::IsNullOrWhiteSpace($clarification))
    if ($awaitingClarification) {
        $afterClarification.domain = "awaiting_clarification"
        $afterClarification.fundingStream = $initialFunding
        $afterClarification.topicAreas = @($initialAreas)
        $afterClarification.outcome = "awaiting_user_clarification"
    }
    $finalDomain = $afterClarification.domain
    $finalFunding = $afterClarification.fundingStream
    $finalAreas = @($afterClarification.topicAreas)

    if ($clarificationType -ne "none" -and [string]::IsNullOrWhiteSpace($clarification) -and $expected.ToLowerInvariant() -notmatch "should not route directly|should ask|not route until|classifier should ask") {
        Add-Failure $caseFailures "missing_clarification" "Intent Clarifier" "Expected clarification path but test case does not provide a clarification value."
    }

    if ($awaitingClarification) {
        $route = [ordered]@{
            routingTarget = "Awaiting Clarification"
            routerDialog  = ""
            yamlFile      = ""
            routerStatus  = "awaiting_clarification"
            finalTopic    = "Cidy_Intent_Clarifier.yaml"
        }
    } else {
        $route = Get-Route -Domain $finalDomain -FundingStream $finalFunding -Domains $domains
    }
    if ($route.routerStatus -eq "topic_not_found") {
        $missingTopicParts = New-Object System.Collections.Generic.List[string]
        if ($finalDomain -and $finalDomain -ne "unclear") { $missingTopicParts.Add($finalDomain) }
        if ($finalFunding -and $finalFunding -ne "UNCLEAR") { $missingTopicParts.Add($finalFunding) }
        foreach ($area in @($finalAreas)) {
            if ($area -and $area -notin @("unclear", "out_of_scope")) { $missingTopicParts.Add($area) }
        }
        $missingTopicSource = ($missingTopicParts.ToArray() -join " ")
        if ([string]::IsNullOrWhiteSpace($missingTopicSource)) {
            $missingTopicSource = ($scenario -replace "^(Happy path|Clarification path|Vague path|Out of scope)\s*-\s*", "")
        }
        $missingTopic = ConvertTo-Slug $missingTopicSource
        if ([string]::IsNullOrWhiteSpace($missingTopic)) { $missingTopic = "unknown_topic" }
        Add-Failure $caseFailures "topic_not_found_=_$missingTopic" "Intent Router" "No domain route found for $finalDomain / $finalFunding."
    }
    if ($route.routerStatus -eq "missing_yaml") {
        Add-Failure $caseFailures "Formulate_Response_YAML_not_found" "Intent Router" "Expected YAML not found: $($route.yamlFile)."
    }
    if ($route.routerStatus -eq "not_wired") {
        Add-Failure $caseFailures "Topic_not_developed" "Intent Router" "Domain is recognized but router currently sends a not-developed message or does not call $($route.yamlFile)."
    }

    $yamlExists = $false
    if ($route.yamlFile) { $yamlExists = Test-Path (Join-Path $Root $route.yamlFile) }
    if ($route.yamlFile -and -not $yamlExists -and $route.routerStatus -ne "missing_yaml") {
        Add-Failure $caseFailures "Formulate_Response_YAML_not_found" "Formulate Response" "Route references $($route.yamlFile), but the file does not exist."
    }

    $topicAreaStatus = Test-TopicAreaMapped -Domain $finalDomain -TopicAreas $finalAreas -Folders $folders
    if (-not $topicAreaStatus.mapped -and $route.routerStatus -eq "wired") {
        Add-Failure $caseFailures "topic_area_not_mapped" "Formulate Response" "Topic area(s) not mapped in $($route.yamlFile): $($topicAreaStatus.unmapped -join ', ')."
    }

    $trace = @(
        [ordered]@{
            topic    = "user_inquiry.yaml"
            output   = "Captures user question"
            decision = "Begin Cidy_Intent.yaml"
        },
        [ordered]@{
            topic    = "Cidy_Intent.yaml"
            output   = [ordered]@{
                knowledgeDomain        = $initialDomain
                fundingStream          = $initialFunding
                topicAreas             = @($initialAreas)
                requiresClarification  = if ($clarificationType -eq "none") { "No" } else { "Yes" }
                clarificationType      = $clarificationType
            }
            decision = if ($clarificationType -eq "none") { "Bypass clarification" } else { "Begin Cidy_Intent_Clarifier.yaml" }
        },
        [ordered]@{
            topic    = "Cidy_Intent_Clarifier.yaml"
            output   = [ordered]@{
                clarificationInput = $clarification
                outcome            = $afterClarification.outcome
                knowledgeDomain    = $finalDomain
                fundingStream      = $finalFunding
                topicAreas         = @($finalAreas)
            }
            decision = if ($finalDomain -eq "dead_end") { "Route to User Feedback" } else { "Begin Cidy_Intent_Router.yaml" }
        },
        [ordered]@{
            topic    = "Cidy_Intent_Router.yaml"
            output   = [ordered]@{
                routingTarget = $route.routingTarget
                routerDialog  = $route.routerDialog
                routerStatus  = $route.routerStatus
                yamlFile      = $route.yamlFile
            }
            decision = if ($route.yamlFile) { "Begin $($route.yamlFile)" } else { "Begin $($route.finalTopic)" }
        }
    )

    if ($route.yamlFile) {
        $trace += [ordered]@{
            topic    = $route.yamlFile
            output   = [ordered]@{
                yamlExists      = $yamlExists
                topicAreaStatus = $topicAreaStatus
            }
            decision = if ($yamlExists -and $topicAreaStatus.mapped) { "Begin assess_confidence.yaml" } elseif ($yamlExists) { "Use fallback or update topic-area mapping" } else { "Stop: YAML not found" }
        }
    }
    $routePath = @($trace | ForEach-Object { $_.topic })
    $routePathText = Get-RoutePathText -Trace $trace

    $status = if ($caseFailures.Count -eq 0) { "pass" } else { "fail" }
    $result = [ordered]@{
        id                  = "TC{0:D2}" -f $index
        scenario            = $scenario
        question            = $question
        clarification       = $clarification
        expectedBehavior    = $expected
        status              = $status
        finalRoute          = $route
        finalClassification = [ordered]@{
            knowledgeDomain = $finalDomain
            fundingStream   = $finalFunding
            topicAreas      = @($finalAreas)
        }
        routePath           = @($routePath)
        routePathText       = $routePathText
        routeTrace          = $trace
        failures            = @($caseFailures.ToArray())
    }
    $results.Add($result)
    if ($status -eq "fail") {
        $failuresOnly.Add([ordered]@{
            id               = $result.id
            scenario         = $scenario
            question         = $question
            finalRoute       = $route
            routePath        = @($routePath)
            routePathText    = $routePathText
            failures         = @($caseFailures.ToArray())
            routeTraceSummary = @($trace | ForEach-Object { [ordered]@{ topic = $_.topic; decision = $_.decision } })
        })
    }
}

$summary = [ordered]@{
    generatedAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssK")
    runner      = "tools/run_intent_test_cases.ps1"
    note        = "Structural route simulation based on expected-behavior fields and current YAML inventory; does not execute Copilot Studio AI classification."
    total       = $results.Count
    passed      = @($results | Where-Object { $_.status -eq "pass" }).Count
    failed      = @($results | Where-Object { $_.status -eq "fail" }).Count
}

$resultsDoc = [ordered]@{
    summary = $summary
    results = @($results.ToArray())
}
$failuresDoc = [ordered]@{
    summary = $summary
    failures = @($failuresOnly.ToArray())
}

Set-Utf8NoBom -Path $resultsFile -Value (($resultsDoc | ConvertTo-Json -Depth 30) + [Environment]::NewLine)
Set-Utf8NoBom -Path $failuresFile -Value (($failuresDoc | ConvertTo-Json -Depth 30) + [Environment]::NewLine)

Write-Host "Wrote $ResultsPath"
Write-Host "Wrote $FailuresPath"
Write-Host "Total: $($summary.total), Passed: $($summary.passed), Failed: $($summary.failed)"

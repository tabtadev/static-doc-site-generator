$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$projectRoot = Split-Path $scriptDir -Parent
$configFile   = "$scriptDir\nav_config.json"
$templateFile = "$scriptDir\nav_template.html"

# ═══════════════════════════════════════════════════════════════════════
#  Generate nav_template.html from nav_config.json
# ═══════════════════════════════════════════════════════════════════════
function Build-NavTemplate {
    $json = Get-Content -Path $configFile -Raw -Encoding UTF8
    $config = $json | ConvertFrom-Json

    # Ensure a value is always iterable as an array
    function As-Array { param($v) if ($v -is [System.Array]) { return ,$v } elseif ($null -eq $v) { return ,@() } else { return ,@($v) } }

    function Render-Items {
        param($items, [int]$indent = 3)
        $pad = "    " * $indent
        $html = ""
        foreach ($item in (As-Array $items)) {
            $childrenArr = As-Array $item.children
            $hasChildren = $childrenArr.Count -gt 0
            $hasHref     = $item.PSObject.Properties.Name -contains 'href' -and $item.href

            if ($hasChildren) {
                # dropdown (category with sub-items)
                $html += "$pad<li class=`"dropdown`">`r`n"
                if ($hasHref) {
                    $html += "$pad    <a href=`"{HOME_PATH}$($item.href)`">$($item.label)</a>`r`n"
                } else {
                    $html += "$pad    <a href=`"#`">$($item.label)</a>`r`n"
                }
                $html += "$pad    <div class=`"dropdown-content`">`r`n"
                foreach ($child in $childrenArr) {
                    $subArr = As-Array $child.children
                    $childHasChildren = $subArr.Count -gt 0
                    $childHasHref     = $child.PSObject.Properties.Name -contains 'href' -and $child.href
                    if ($childHasChildren) {
                        # sub-category heading + its children as links
                        $html += "$pad        <strong class=`"dropdown-heading`">$($child.label)</strong>`r`n"
                        foreach ($sub in $subArr) {
                            $html += "$pad        <a href=`"{HOME_PATH}$($sub.href)`">$($sub.label)</a>`r`n"
                        }
                    } elseif ($childHasHref) {
                        $html += "$pad        <a href=`"{HOME_PATH}$($child.href)`">$($child.label)</a>`r`n"
                    }
                }
                $html += "$pad    </div>`r`n"
                $html += "$pad</li>`r`n"
            } else {
                # simple link
                $html += "$pad<li><a href=`"{HOME_PATH}$($item.href)`">$($item.label)</a></li>`r`n"
            }
        }
        return $html
    }

    $inner = Render-Items -items $config.items
    $template = @"
    <nav>
        <ul>
$inner            <li><button id="theme-toggle" aria-label="Toggle dark mode">&#127769;</button></li>
        </ul>
    </nav>
"@
    Set-Content -Path $templateFile -Value $template -Encoding UTF8
    Write-Output "Generated nav_template.html from nav_config.json"
}

# Generate the template first
Build-NavTemplate

# ═══════════════════════════════════════════════════════════════════════
#  Deploy nav into every HTML file
# ═══════════════════════════════════════════════════════════════════════
function Update-Nav {
    param (
        [string]$filePath,
        [int]$depth
    )

    $homePath = ""
    if ($depth -gt 0) {
        $homePath = ("../" * $depth).TrimEnd("/") + "/"
    }

    Write-Output "Processing: $filePath (depth=$depth)"

    $navContent = Get-Content -Path $templateFile -Raw -Encoding UTF8
    $navContent = $navContent -replace "\{HOME_PATH\}", $homePath

    $fileContent = Get-Content -Path $filePath -Raw -Encoding UTF8

    if ($fileContent -match "(?s)<nav.*?</nav>") {
        # Replace nav and collapse surrounding blank lines
        $updatedContent = $fileContent -replace "(?s)\s*<nav.*?</nav>\s*", "`r`n$navContent`r`n"
        Set-Content -Path $filePath -Value $updatedContent -Encoding UTF8
        Write-Output "  Updated <nav> in $filePath"
    } else {
        Write-Output "  Warning: No <nav> found in $filePath"
    }
}

# Deploy to all HTML files except nav_template.html
Write-Output "Deploying navigation..."

Get-ChildItem -Path $projectRoot -Recurse -Filter "*.html" | Where-Object {
    $_.Name -ne "nav_template.html"
} | ForEach-Object {
    $filePath = $_.FullName
    $relativePath = $filePath.Substring($projectRoot.Length + 1)
    $depth = ($relativePath -split "\\").Count - 1
    Update-Nav -filePath $filePath -depth $depth
}

Write-Output "Navigation deployed to all HTML files."

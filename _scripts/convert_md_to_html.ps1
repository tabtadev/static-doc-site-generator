# ============================================================
# TabtaDev Markdown to HTML Converter
# Converts .md files to .html with frontmatter, TOC, syntax
# highlighting, dynamic CSS paths, and article index generation
# ============================================================

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$projectRoot = Split-Path $scriptDir -Parent
$navTemplateFile = "$scriptDir\nav_template.html"

# ── Helper: Convert inline markdown to HTML ──
function Convert-InlineMarkdown {
    param([string]$text)
    $text = [regex]::Replace($text, '`([^`]+)`', '<code>$1</code>')
    $text = $text -replace '!\[(.*?)\]\((.+?)\)', '<img src="$2" alt="$1">'
    $text = $text -replace '\[([^\]]+)\]\(([^)]+)\)', '<a href="$2">$1</a>'
    $text = $text -replace '\*\*(.+?)\*\*', '<strong>$1</strong>'
    $text = $text -replace '(?<![*])\*(?![*])(.+?)(?<![*])\*(?![*])', '<em>$1</em>'
    $text = $text -replace '~~(.+?)~~', '<del>$1</del>'
    return $text
}

# ── Helper: Generate URL-friendly slug from header text ──
function Get-Slug {
    param([string]$text)
    $slug = $text.ToLower().Trim()
    $slug = [regex]::Replace($slug, '<[^>]+>', '')
    $slug = [regex]::Replace($slug, '[^\w\s-]', '')
    $slug = [regex]::Replace($slug, '\s+', '-')
    $slug = $slug.Trim('-')
    return $slug
}

# ── Helper: Parse YAML frontmatter ──
function Parse-Frontmatter {
    param([string]$content)
    $meta = @{}
    $body = $content

    if ($content -match '(?s)^---\s*\r?\n(.+?)\r?\n---\s*\r?\n?(.*)$') {
        $yamlBlock = $matches[1]
        $body = $matches[2]
        foreach ($yamlLine in ($yamlBlock -split "`r?`n")) {
            $yamlLine = $yamlLine.Trim()
            if ($yamlLine -match '^([\w-]+)\s*:\s*(.+)$') {
                $key = $matches[1]
                $val = $matches[2].Trim()
                if ($val -match '^\[(.+)\]$') {
                    $val = ($matches[1] -split ',') | ForEach-Object { $_.Trim().Trim('"').Trim("'") }
                }
                elseif ($val -match '^["''](.+)["'']$') {
                    $val = $matches[1]
                }
                $meta[$key] = $val
            }
        }
    }
    return @{ Meta = $meta; Body = $body }
}

# ── Helper: Flush all open block-level state ──
function Close-OpenState {
    param(
        [System.Text.StringBuilder]$sb,
        [System.Collections.ArrayList]$paraLines,
        [hashtable]$state
    )
    if ($paraLines.Count -gt 0) {
        $pText = ($paraLines.ToArray() -join ' ').Trim()
        if ($pText) { [void]$sb.AppendLine("<p>$(Convert-InlineMarkdown $pText)</p>") }
        $paraLines.Clear()
    }
    if ($state.InUL) { [void]$sb.AppendLine("</ul>"); $state.InUL = $false }
    if ($state.InOL) { [void]$sb.AppendLine("</ol>"); $state.InOL = $false }
    if ($state.InBQ) { [void]$sb.AppendLine("</blockquote>"); $state.InBQ = $false }
    if ($state.InTable) { [void]$sb.AppendLine("</tbody></table>"); $state.InTable = $false; $state.TblHead = $false }
}

# ── Main markdown-to-HTML conversion ──
function Convert-MarkdownToHtml {
    param(
        [string]$markdownBody,
        [string]$title,
        [hashtable]$meta,
        [string]$homePath,
        [string]$navHtml
    )

    $lines = $markdownBody -split "`r?`n"
    $sb = [System.Text.StringBuilder]::new()
    $toc = [System.Collections.ArrayList]::new()

    $st = @{ InUL = $false; InOL = $false; InBQ = $false; InTable = $false; TblHead = $false }
    $para = [System.Collections.ArrayList]::new()

    $inCode = $false
    $codeLang = ""
    $codeLines = [System.Collections.ArrayList]::new()

    foreach ($rawLine in $lines) {
        $t = $rawLine.TrimEnd()

        # ── Code block delimiter ──
        if ($t -match '^```(.*)$') {
            if ($inCode) {
                $escaped = ($codeLines -join "`n").Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;')
                if ($codeLang) {
                    [void]$sb.AppendLine("<pre><code class=`"language-$codeLang`">$escaped</code></pre>")
                } else {
                    [void]$sb.AppendLine("<pre><code>$escaped</code></pre>")
                }
                $inCode = $false; $codeLines.Clear(); $codeLang = ""
            } else {
                Close-OpenState -sb $sb -paraLines $para -state $st
                $inCode = $true; $codeLang = $matches[1].Trim()
            }
            continue
        }
        if ($inCode) { [void]$codeLines.Add($rawLine); continue }

        # ── Blank line ──
        if ($t -eq '') { Close-OpenState -sb $sb -paraLines $para -state $st; continue }

        # ── Horizontal rule ──
        if ($t -match '^[-*_]{3,}$' -and $t -notmatch '[a-zA-Z0-9]') {
            Close-OpenState -sb $sb -paraLines $para -state $st
            [void]$sb.AppendLine("<hr>")
            continue
        }

        # ── Header ──
        if ($t -match '^(#{1,6})\s+(.+)$') {
            Close-OpenState -sb $sb -paraLines $para -state $st
            $lvl = $matches[1].Length
            $hText = $matches[2].Trim()
            $slug = Get-Slug $hText
            [void]$sb.AppendLine("<h$lvl id=`"$slug`">$(Convert-InlineMarkdown $hText)</h$lvl>")
            [void]$toc.Add(@{ Level = $lvl; Text = $hText; Slug = $slug })
            continue
        }

        # ── Unordered list item ──
        if ($t -match '^[-*+]\s+(.+)$') {
            if ($para.Count -gt 0) {
                $pText = ($para.ToArray() -join ' ').Trim()
                if ($pText) { [void]$sb.AppendLine("<p>$(Convert-InlineMarkdown $pText)</p>") }
                $para.Clear()
            }
            if ($st.InOL) { [void]$sb.AppendLine("</ol>"); $st.InOL = $false }
            if ($st.InBQ) { [void]$sb.AppendLine("</blockquote>"); $st.InBQ = $false }
            if ($st.InTable) { [void]$sb.AppendLine("</tbody></table>"); $st.InTable = $false }
            if (-not $st.InUL) { [void]$sb.AppendLine("<ul>"); $st.InUL = $true }

            $itemText = $matches[1]
            if ($itemText -match '^\[([ xX])\]\s+(.+)$') {
                $checkChar = $matches[1]
                $taskText = $matches[2]
                $chk = if ($checkChar -eq 'x' -or $checkChar -eq 'X') { ' checked' } else { '' }
                [void]$sb.AppendLine("<li><input type=`"checkbox`" disabled$chk> $(Convert-InlineMarkdown $taskText)</li>")
            } else {
                [void]$sb.AppendLine("<li>$(Convert-InlineMarkdown $itemText)</li>")
            }
            continue
        }

        # ── Ordered list item ──
        if ($t -match '^\d+\.\s+(.+)$') {
            if ($para.Count -gt 0) {
                $pText = ($para.ToArray() -join ' ').Trim()
                if ($pText) { [void]$sb.AppendLine("<p>$(Convert-InlineMarkdown $pText)</p>") }
                $para.Clear()
            }
            if ($st.InUL) { [void]$sb.AppendLine("</ul>"); $st.InUL = $false }
            if ($st.InBQ) { [void]$sb.AppendLine("</blockquote>"); $st.InBQ = $false }
            if ($st.InTable) { [void]$sb.AppendLine("</tbody></table>"); $st.InTable = $false }
            if (-not $st.InOL) { [void]$sb.AppendLine("<ol>"); $st.InOL = $true }
            [void]$sb.AppendLine("<li>$(Convert-InlineMarkdown $matches[1])</li>")
            continue
        }

        # ── Blockquote ──
        if ($t -match '^>\s*(.*)$') {
            if ($para.Count -gt 0) {
                $pText = ($para.ToArray() -join ' ').Trim()
                if ($pText) { [void]$sb.AppendLine("<p>$(Convert-InlineMarkdown $pText)</p>") }
                $para.Clear()
            }
            if ($st.InUL) { [void]$sb.AppendLine("</ul>"); $st.InUL = $false }
            if ($st.InOL) { [void]$sb.AppendLine("</ol>"); $st.InOL = $false }
            if ($st.InTable) { [void]$sb.AppendLine("</tbody></table>"); $st.InTable = $false }
            if (-not $st.InBQ) { [void]$sb.AppendLine("<blockquote>"); $st.InBQ = $true }
            $bqText = $matches[1]
            if ($bqText) { [void]$sb.AppendLine("<p>$(Convert-InlineMarkdown $bqText)</p>") }
            continue
        }

        # ── Table row ──
        if ($t -match '^\|(.+)\|$') {
            if ($para.Count -gt 0) {
                $pText = ($para.ToArray() -join ' ').Trim()
                if ($pText) { [void]$sb.AppendLine("<p>$(Convert-InlineMarkdown $pText)</p>") }
                $para.Clear()
            }
            if ($st.InUL) { [void]$sb.AppendLine("</ul>"); $st.InUL = $false }
            if ($st.InOL) { [void]$sb.AppendLine("</ol>"); $st.InOL = $false }
            if ($st.InBQ) { [void]$sb.AppendLine("</blockquote>"); $st.InBQ = $false }

            $cells = ($matches[1] -split '\|') | ForEach-Object { $_.Trim() }

            if (-not $st.InTable) {
                [void]$sb.AppendLine("<table><thead><tr>")
                foreach ($c in $cells) { [void]$sb.AppendLine("<th>$(Convert-InlineMarkdown $c)</th>") }
                [void]$sb.AppendLine("</tr></thead><tbody>")
                $st.InTable = $true; $st.TblHead = $false
            }
            elseif (-not $st.TblHead) {
                $isSep = $true
                foreach ($c in $cells) { if ($c -notmatch '^[:\-\s]+$') { $isSep = $false; break } }
                if ($isSep) { $st.TblHead = $true }
                else {
                    $st.TblHead = $true
                    [void]$sb.AppendLine("<tr>")
                    foreach ($c in $cells) { [void]$sb.AppendLine("<td>$(Convert-InlineMarkdown $c)</td>") }
                    [void]$sb.AppendLine("</tr>")
                }
            }
            else {
                [void]$sb.AppendLine("<tr>")
                foreach ($c in $cells) { [void]$sb.AppendLine("<td>$(Convert-InlineMarkdown $c)</td>") }
                [void]$sb.AppendLine("</tr>")
            }
            continue
        }

        # ── Regular text: accumulate for paragraph ──
        if ($st.InUL) { [void]$sb.AppendLine("</ul>"); $st.InUL = $false }
        if ($st.InOL) { [void]$sb.AppendLine("</ol>"); $st.InOL = $false }
        if ($st.InBQ) { [void]$sb.AppendLine("</blockquote>"); $st.InBQ = $false }
        if ($st.InTable) { [void]$sb.AppendLine("</tbody></table>"); $st.InTable = $false; $st.TblHead = $false }
        [void]$para.Add($t)
    }

    # Final flush
    Close-OpenState -sb $sb -paraLines $para -state $st
    if ($inCode) {
        $escaped = ($codeLines -join "`n").Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;')
        [void]$sb.AppendLine("<pre><code>$escaped</code></pre>")
    }

    # ── Build Table of Contents ──
    $tocHtml = ""
    if ($toc.Count -gt 1) {
        $tocSb = [System.Text.StringBuilder]::new()
        [void]$tocSb.AppendLine('<div class="toc">')
        [void]$tocSb.AppendLine('<details open><summary>Table of Contents</summary><ul>')
        foreach ($entry in $toc) {
            [void]$tocSb.AppendLine("<li class=`"toc-level-$($entry.Level)`"><a href=`"#$($entry.Slug)`">$($entry.Text)</a></li>")
        }
        [void]$tocSb.AppendLine('</ul></details></div>')
        $tocHtml = $tocSb.ToString()
    }

    # ── Article metadata (date, tags) ──
    $metaHtml = ""
    $metaParts = @()
    if ($meta -and $meta.ContainsKey('date')) {
        $metaParts += "<time class=`"article-date`">$($meta['date'])</time>"
    }
    if ($meta -and $meta.ContainsKey('tags')) {
        $tags = $meta['tags']
        if ($tags -is [array]) {
            $tagSpans = ($tags | ForEach-Object { "<span class=`"tag`">$_</span>" }) -join ' '
        } else {
            $tagSpans = "<span class=`"tag`">$tags</span>"
        }
        $metaParts += "<div class=`"article-tags`">$tagSpans</div>"
    }
    if ($metaParts.Count -gt 0) {
        $metaHtml = "<div class=`"article-meta`">$($metaParts -join "`n")</div>"
    }

    $bodyHtml = $sb.ToString()
    $desc = if ($meta -and $meta.ContainsKey('description')) { $meta['description'] } else { "" }
    $year = Get-Date -Format 'yyyy'

    $fullHtml = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$title - TabtaDev</title>
    <meta name="description" content="$desc">
    <link rel="stylesheet" href="${homePath}css/style.css">
    <link id="hljs-theme" rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github.min.css">
    <script src="${homePath}js/main.js"></script>
</head>
<body>
$navHtml
<main>
$metaHtml
$tocHtml
$bodyHtml
</main>
<footer>
    <p>&copy; $year TabtaDev. All rights reserved.</p>
</footer>
<script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>
<script>hljs.highlightAll();</script>
</body>
</html>
"@

    return $fullHtml
}

# ── Generate article index page ──
function Build-ArticleIndex {
    param(
        [array]$articles,
        [string]$navHtml
    )

    $year = Get-Date -Format 'yyyy'
    $sorted = $articles | Sort-Object { $_.Date } -Descending

    $cardsSb = [System.Text.StringBuilder]::new()
    foreach ($a in $sorted) {
        $tagsHtml = ""
        if ($a.Tags) {
            $tagItems = if ($a.Tags -is [array]) { $a.Tags } else { @($a.Tags) }
            $tagsHtml = ($tagItems | ForEach-Object { "<span class=`"tag`">$_</span>" }) -join ' '
        }
        $dateHtml = if ($a.Date) { "<time class=`"article-date`">$($a.Date)</time>" } else { "" }
        $descHtml = if ($a.Description) { "<p>$($a.Description)</p>" } else { "" }

        [void]$cardsSb.AppendLine(@"
        <article class="article-card">
            <h3><a href="$($a.Url)">$($a.Title)</a></h3>
            $dateHtml
            $descHtml
            <div class="article-tags">$tagsHtml</div>
        </article>
"@)
    }

    $cardsHtml = $cardsSb.ToString()

    $indexHtml = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Articles - TabtaDev</title>
    <link rel="stylesheet" href="css/style.css">
    <link id="hljs-theme" rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github.min.css">
</head>
<body>
$navHtml
<main>
    <h1>Articles</h1>
    <div class="article-list">
$cardsHtml
    </div>
</main>
<footer>
    <p>&copy; $year TabtaDev. All rights reserved.</p>
</footer>
<script src="js/main.js"></script>
</body>
</html>
"@

    return $indexHtml
}

# ═══════════════════════════════════════════════════════════════
# Main Execution
# ═══════════════════════════════════════════════════════════════

Write-Output "TabtaDev Build - Starting..."

$navTemplate = Get-Content -Path $navTemplateFile -Raw -Encoding UTF8
$articles = @()

Get-ChildItem -Path $projectRoot -Recurse -Filter "*.md" |
    Where-Object { $_.Name -ne "README.md" } |
    ForEach-Object {
        $mdFile = $_.FullName
        $htmlFile = [System.IO.Path]::ChangeExtension($mdFile, "html")
        # Lowercase the filename to avoid case-sensitivity issues on Linux/GitHub Pages
        $htmlDir = [System.IO.Path]::GetDirectoryName($htmlFile)
        $htmlName = [System.IO.Path]::GetFileName($htmlFile).ToLower()
        $htmlFile = [System.IO.Path]::Combine($htmlDir, $htmlName)

        # Calculate depth and home path
        $relativePath = $mdFile.Substring($projectRoot.Length + 1)
        $depth = ($relativePath -split "\\").Count - 1
        $homePath = if ($depth -gt 0) { ("../" * $depth) } else { "" }

        # Parse frontmatter
        $rawContent = Get-Content -Path $mdFile -Raw -Encoding UTF8
        $parsed = Parse-Frontmatter -content $rawContent
        $meta = $parsed.Meta
        $body = $parsed.Body

        # Determine title
        $title = if ($meta.ContainsKey('title')) { $meta['title'] }
                 elseif ($body -match '(?m)^#\s+(.+)') { $matches[1] }
                 else { "Untitled" }

        # Prepare nav with correct paths
        $navHtml = $navTemplate -replace "\{HOME_PATH\}", $homePath

        # Convert and save
        $htmlContent = Convert-MarkdownToHtml -markdownBody $body -title $title -meta $meta -homePath $homePath -navHtml $navHtml
        Set-Content -Path $htmlFile -Value $htmlContent -Encoding UTF8
        Write-Output "Converted: $relativePath"

        # Collect metadata for article index (articles/ folder only)
        if ($relativePath -like "articles\*") {
            $relHtmlPath = $relativePath.Replace('\', '/').Replace('.md', '.html').ToLower()
            $articles += @{
                Title       = $title
                Date        = if ($meta.ContainsKey('date')) { $meta['date'] } else { "" }
                Tags        = if ($meta.ContainsKey('tags')) { $meta['tags'] } else { @() }
                Description = if ($meta.ContainsKey('description')) { $meta['description'] } else { "" }
                Url         = $relHtmlPath
            }
        }
    }

# Generate articles index page
if ($articles.Count -gt 0) {
    $rootNav = $navTemplate -replace "\{HOME_PATH\}", ""
    $indexContent = Build-ArticleIndex -articles $articles -navHtml $rootNav
    Set-Content -Path "$projectRoot\articles.html" -Value $indexContent -Encoding UTF8
    Write-Output "Generated: articles.html ($($articles.Count) articles indexed)"
}

Write-Output "TabtaDev Build - Completed!"
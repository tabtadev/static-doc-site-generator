# Define the root directory of your project
$projectRoot = (Get-Location).Path

# Load navigation template
$navTemplate = Get-Content -Path "$projectRoot\nav_template.html" -Raw

# Footer content (you can adjust this as needed)
$footerContent = @"
<footer>
    <p>&copy; 2024 TabtaDev. All rights reserved.</p>
</footer>
"@

# Function to convert markdown to HTML content
function Convert-MarkdownToHtml {
    param (
        [string]$markdownContent,
        [string]$title
    )

    # Replace headers
    $htmlContent = $markdownContent -replace '(^|\n)###### (.+)', '<h6>$2</h6>'
    $htmlContent = $htmlContent -replace '(^|\n)##### (.+)', '<h5>$2</h5>'
    $htmlContent = $htmlContent -replace '(^|\n)#### (.+)', '<h4>$2</h4>'
    $htmlContent = $htmlContent -replace '(^|\n)### (.+)', '<h3>$2</h3>'
    $htmlContent = $htmlContent -replace '(^|\n)## (.+)', '<h2>$2</h2>'
    $htmlContent = $htmlContent -replace '(^|\n)# (.+)', '<h1>$2</h1>'

    # Bold, italics, strikethrough
    $htmlContent = $htmlContent -replace '\*\*(.+?)\*\*', '<strong>$1</strong>'
    $htmlContent = $htmlContent -replace '\*(.+?)\*', '<em>$1</em>'
    $htmlContent = $htmlContent -replace '~~(.+?)~~', '<del>$1</del>'

    # Links and images
    $htmlContent = $htmlContent -replace '!\[(.*?)\]\((.+?)\)', '<img src="$2" alt="$1">'
    $htmlContent = $htmlContent -replace '\[(.+?)\]\((.+?)\)', '<a href="$2">$1</a>'

    # Inline and block code
    $htmlContent = $htmlContent -replace '```([^`]+?)```', '<pre><code>$1</code></pre>'
    $htmlContent = $htmlContent -replace '`(.+?)`', '<code>$1</code>'

    # Lists
    $htmlContent = $htmlContent -replace '^- (.+)', '<ul><li>$1</li></ul>'
    $htmlContent = $htmlContent -replace '^\d+\. (.+)', '<ol><li>$1</li></ol>'

    # Task lists
    $htmlContent = $htmlContent -replace '- \[ \] (.+)', '<li><input type="checkbox" disabled> $1</li>'
    $htmlContent = $htmlContent -replace '- \[x\] (.+)', '<li><input type="checkbox" checked disabled> $1</li>'

    # Blockquotes
    $htmlContent = $htmlContent -replace '^> (.+)', '<blockquote>$1</blockquote>'

    # Horizontal rules
    $htmlContent = $htmlContent -replace '^---$', '<hr>'

    # Tables (basic)
    $htmlContent = $htmlContent -replace '^\|(.+?)\|$', '<tr><td>$1</td></tr>'
    $htmlContent = $htmlContent -replace '\|', '</td><td>'

    # Convert double newlines to <p> tags to create paragraphs
    $htmlContent = $htmlContent -replace '(\n\s*\n)+', '</p><p>'

    # Wrap content in full HTML structure
    $htmlContent = @"
<!DOCTYPE html>
<html lang='en'>
<head>
    <meta charset='UTF-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>$title</title>
    <link rel='stylesheet' href='../../css/style.css'>
</head>
<body>
$navTemplate
<main>
<p>$htmlContent</p>
</main>
$footerContent
</body>
</html>
"@

    return $htmlContent
}

# Process all .md files in the project directory recursively
Get-ChildItem -Path $projectRoot -Recurse -Filter "*.md" | ForEach-Object {
    $mdFile = $_.FullName
    $htmlFile = [System.IO.Path]::ChangeExtension($mdFile, "html")

    # Read the markdown content
    $markdownContent = Get-Content -Path $mdFile -Raw

    # Extract the first line as the title or set a default
    if ($markdownContent -match '^# (.+)$') {
        $title = $matches[1]
    } else {
        $title = "Converted Markdown"
    }

    # Convert markdown to HTML
    $htmlContent = Convert-MarkdownToHtml -markdownContent $markdownContent -title $title

    # Save the converted content as an .html file
    Set-Content -Path $htmlFile -Value $htmlContent

    # Log the conversion
    Write-Output "Converted $mdFile to $htmlFile"
}

Write-Output "Markdown to HTML conversion completed successfully."

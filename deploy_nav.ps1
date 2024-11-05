$templateFile = "nav_template.html"
$projectRoot = (Get-Location).Path

function Update-Nav {
    param (
        [string]$filePath,
        [int]$depth
    )

    # Set the home path based on file depth and add a trailing slash
    $homePath = ""
    if ($depth -gt 0) {
        $homePath = ("../" * $depth).TrimEnd("/") + "/"
    }

    # Log the home path for this file
    Write-Output "Processing file: ${filePath} (Depth: ${depth}, Home Path: '${homePath}')"

    # Read the template and replace placeholders
    $navContent = Get-Content -Path $templateFile -Raw

    # Log initial template content before replacement
    Write-Output "Original nav template content for ${filePath}:"
    Write-Output "${navContent}"

    # Attempt to replace {HOME_PATH} with calculated homePath
    $navContent = $navContent -replace "\{HOME_PATH\}", $homePath

    # Log modified navigation content after replacement
    Write-Output "Modified navigation content after {HOME_PATH} replacement for ${filePath}:"
    Write-Output "${navContent}"

    # Use regex to replace <nav> section in the HTML file
    $fileContent = Get-Content -Path $filePath -Raw

    # Updated regex pattern to capture entire <nav> section more flexibly
    if ($fileContent -match "(?s)<nav.*?</nav>") {
        $updatedContent = $fileContent -replace "(?s)<nav.*?</nav>", $navContent
        Set-Content -Path $filePath -Value $updatedContent

        # Log successful replacement
        Write-Output "Successfully updated <nav> section in ${filePath}."
    } else {
        Write-Output "Warning: No <nav> section found in ${filePath}. Skipping replacement."
    }
}

# Start processing all HTML files, excluding nav_template.html
Write-Output "Starting navigation update for HTML files in ${projectRoot}..."

# Find and process all HTML files except nav_template.html
Get-ChildItem -Path $projectRoot -Recurse -Filter "*.html" | Where-Object {
    $_.Name -ne "nav_template.html"
} | ForEach-Object {
    $filePath = $_.FullName
    $relativePath = $filePath.Substring($projectRoot.Length + 1)

    # Calculate depth based on the number of directories in relative path
    $depth = ($relativePath -split "\\").Count - 1

    # Update the navigation section in each file and log progress
    Update-Nav -filePath $filePath -depth $depth
}

Write-Output "Navigation update completed successfully for all HTML files, excluding nav_template.html."

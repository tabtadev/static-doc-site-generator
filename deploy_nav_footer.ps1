param (
    [string]$FooterText = "&copy; 2024 TabtaDev. All rights reserved."
)

$projectRoot = (Get-Location).Path

# Function to generate navigation HTML with proper indentation
function Generate-Nav {
    param (
        [int]$depth
    )

    # Calculate home path based on depth
    $homePath = ""
    if ($depth -gt 0) {
        $homePath = ("../" * $depth).TrimEnd("/") + "/"
    }

    # Build the navigation structure with indentation
    $navContent = @"
        <nav>
            <ul>
                <li><a href="${homePath}index.html">Home</a></li>
                <li><a href="${homePath}about.html">About</a></li>
                <li class="dropdown">
                    <a href="${homePath}articles.html">Articles</a>
                    <div class="dropdown-content">
"@

    # Find all HTML files in the articles directory to populate dropdown
    $articlesDir = Join-Path -Path $projectRoot -ChildPath "articles"
    Get-ChildItem -Path $articlesDir -Recurse -Filter "*.html" | ForEach-Object {
        $articlePath = $_.FullName.Substring($projectRoot.Length + 1) -replace '\\', '/'
        $articleTitle = [System.IO.Path]::GetFileNameWithoutExtension($_.Name) -replace '-', ' '

        # Add each article link to the dropdown with proper indentation
        $navContent += "                        <a href=""${homePath}${articlePath}"">${articleTitle}</a>`n"
    }

    # Close dropdown and main nav structure with indentation
    $navContent += @"
                    </div>
                </li>
            </ul>
        </nav>
"@

    return $navContent
}

# Function to update or insert the <nav> and <footer> sections
function Update-Page {
    param (
        [string]$filePath,
        [int]$depth
    )

    # Generate navigation and footer content
    $navContent = Generate-Nav -depth $depth
    $footerContent = @"
    <footer>
        <p>$FooterText</p>
    </footer>
"@

    # Read the content of the file
    $fileContent = Get-Content -Path $filePath -Raw

    # Check and update <nav> section
    if ($fileContent -match "(?s)<nav.*?</nav>") {
        # Replace existing <nav> section
        $fileContent = $fileContent -replace "(?s)<nav.*?</nav>", $navContent
        Write-Output "Updated <nav> section in ${filePath}."
    } else {
        # Insert <nav> section after <body> tag if <nav> is missing
        $fileContent = $fileContent -replace "(?i)<body>", "<body>`n${navContent}"
        Write-Output "Inserted <nav> section in ${filePath}."
    }

    # Check and update <footer> section
    if ($fileContent -match "(?s)<footer.*?</footer>") {
        # Replace existing <footer> section
        $fileContent = $fileContent -replace "(?s)<footer.*?</footer>", $footerContent
        Write-Output "Updated <footer> section in ${filePath}."
    } else {
        # Add <footer> section at the end of <body> if <footer> is missing
        $fileContent = $fileContent -replace "(?i)</body>", "${footerContent}`n</body>"
        Write-Output "Inserted <footer> section in ${filePath}."
    }

    # Save updated content to the file
    Set-Content -Path $filePath -Value $fileContent
}

# Start processing all HTML files, excluding any template files
Write-Output "Starting navigation and footer update for HTML files in ${projectRoot}..."

Get-ChildItem -Path $projectRoot -Recurse -Filter "*.html" | ForEach-Object {
    $filePath = $_.FullName
    $relativePath = $filePath.Substring($projectRoot.Length + 1)
    
    # Calculate depth based on the number of directories in relative path
    $depth = ($relativePath -split "\\").Count - 1

    # Update the navigation and footer in each file
    Update-Page -filePath $filePath -depth $depth
}

Write-Output "Navigation and footer update completed successfully for all HTML files."
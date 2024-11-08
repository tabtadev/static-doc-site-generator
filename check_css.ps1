# Define the target directory
$rootDir = (Get-Location).Path

# Define the CSS path to look for and update
$cssFileName = "css/style.css"

# Function to calculate the relative path based on folder depth
function Get-RelativeCSSPath {
    param (
        [int]$depth
    )
    $relativePath = ("../" * $depth) + $cssFileName
    return $relativePath
}

# Iterate through all .html files in the directory and subdirectories
Get-ChildItem -Path $rootDir -Filter *.html -Recurse | ForEach-Object {
    $filePath = $_.FullName
    $relativeDepth = ($filePath -replace [regex]::Escape($rootDir), "") -split "\\"
    $relativePath = Get-RelativeCSSPath ($relativeDepth.Count - 2)  # Adjust for base directory level

    # Read the file contents
    $content = Get-Content -Path $filePath -Raw

    # Define the link tag to insert or update with indentation
    $cssLinkTag = "`t<link rel='stylesheet' href='$relativePath'>"

    # Check if a CSS link already exists
    if ($content -match "<link\s+rel=['\""]stylesheet['\""]\s+href=['\""][^'\""]*css/style.css['\""]") {
        # Update the existing link to the correct relative path
        $updatedContent = $content -replace "(<link\s+rel=['\""]stylesheet['\""]\s+href=['\""])[^'\""]*css/style.css(['\""])", "`$1$relativePath`$2"
    }
    else {
        # Insert the CSS link tag right after <head>, if <head> exists
        if ($content -match "<head>") {
            $updatedContent = $content -replace "(<head>)", "`$1`n$cssLinkTag"
        }
        # If no <head>, try inserting before </head>
        elseif ($content -match "</head>") {
            $updatedContent = $content -replace "(</head>)", "$cssLinkTag`n$1"
        }
        # If <head> and </head> are missing, insert at the start of the file
        else {
            $updatedContent = "$cssLinkTag`n$content"
        }
    }

    # Write the updated content back to the file
    Set-Content -Path $filePath -Value $updatedContent
}

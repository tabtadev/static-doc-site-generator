# Define the footer text argument
$FooterText = "&copy; 2024 TabtaDev. All rights reserved."

# Path to the scripts
$convertScript = ".\convert_md_to_html.ps1"
$deployNavFooterScript = ".\deploy_nav_footer.ps1"
$checkCssScript = ".\check_css.ps1"

# Check if each script exists before running
if (Test-Path $convertScript) {
    Write-Host "Running convert_md_to_html.ps1..."
    & $convertScript
} else {
    Write-Host "Error: convert_md_to_html.ps1 not found."
}

if (Test-Path $deployNavFooterScript) {
    Write-Host "Running deploy_nav_footer.ps1 with FooterText argument..."
    & $deployNavFooterScript -FooterText $FooterText
} else {
    Write-Host "Error: deploy_nav_footer.ps1 not found."
}

if (Test-Path $checkCssScript) {
    Write-Host "Running check_css.ps1..."
    & $checkCssScript
} else {
    Write-Host "Error: check_css.ps1 not found."
}

Write-Host "Deployment completed."

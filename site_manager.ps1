###############################################################################
#  TabtaDev Site Manager
#  Interface simple pour gerer votre blog / site statique
###############################################################################
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic

$projectRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$scriptsDir  = "$projectRoot\_scripts"
Set-Location $projectRoot

[System.Windows.Forms.Application]::EnableVisualStyles()

# ── Palette ──────────────────────────────────────────────────────────
$colSidebar     = [System.Drawing.Color]::FromArgb( 28,  32,  44)
$colSidebarHi   = [System.Drawing.Color]::FromArgb( 40,  46,  62)
$colSidebarAct  = [System.Drawing.Color]::FromArgb( 50,  58,  78)
$colBg          = [System.Drawing.Color]::FromArgb(248, 249, 252)
$colCard        = [System.Drawing.Color]::White
$colBorder      = [System.Drawing.Color]::FromArgb(228, 230, 240)
$colWhite       = [System.Drawing.Color]::White
$colGreen       = [System.Drawing.Color]::FromArgb( 34, 197, 94)
$colGreenDark   = [System.Drawing.Color]::FromArgb( 22, 163, 74)
$colBlue        = [System.Drawing.Color]::FromArgb( 59, 130, 246)
$colBlueDark    = [System.Drawing.Color]::FromArgb( 37, 99,  235)
$colRed         = [System.Drawing.Color]::FromArgb(239,  68,  68)
$colRedDark     = [System.Drawing.Color]::FromArgb(220,  38,  38)
$colOrange      = [System.Drawing.Color]::FromArgb(249, 115,  22)
$colTextDark    = [System.Drawing.Color]::FromArgb( 30,  41,  59)
$colTextMuted   = [System.Drawing.Color]::FromArgb(100, 116, 139)
$colTextLight   = [System.Drawing.Color]::FromArgb(203, 213, 225)
$colTextSidebar = [System.Drawing.Color]::FromArgb(160, 170, 195)
$colConsoleBg   = [System.Drawing.Color]::FromArgb( 15,  23,  42)
$colConsoleFg   = [System.Drawing.Color]::FromArgb(203, 213, 225)

$fontBrand    = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$fontSection  = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$fontSubtitle = New-Object System.Drawing.Font("Segoe UI", 9)
$fontSideBtn  = New-Object System.Drawing.Font("Segoe UI", 10)
$fontBtn      = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$fontBtnSmall = New-Object System.Drawing.Font("Segoe UI", 9)
$fontBtnBig   = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$fontConsole  = New-Object System.Drawing.Font("Cascadia Mono,Consolas", 9)
$fontList     = New-Object System.Drawing.Font("Segoe UI", 9.5)
$fontLabel    = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
$fontLabelBig = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)

# ── Console helper ───────────────────────────────────────────────────
function Write-Console {
    param([string]$Text, [System.Drawing.Color]$Color = $colConsoleFg)
    $rtb = $script:consoleBox
    $rtb.SelectionStart  = $rtb.TextLength
    $rtb.SelectionLength = 0
    $rtb.SelectionColor  = $Color
    $rtb.AppendText("$Text`r`n")
    $rtb.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

# ── Bouton helper ────────────────────────────────────────────────────
function New-FlatButton {
    param([string]$Text, [int]$X, [int]$Y, [int]$W, [int]$H,
          [System.Drawing.Color]$Bg = $colBlue,
          [System.Drawing.Color]$Fg = $colWhite,
          [System.Drawing.Color]$HoverBg = [System.Drawing.Color]::Empty,
          [System.Drawing.Font]$Font = $fontBtn,
          [string]$Tip = "",
          [System.Drawing.ContentAlignment]$Align = [System.Drawing.ContentAlignment]::MiddleCenter)
    $b = New-Object System.Windows.Forms.Button
    $b.Text      = $Text
    $b.TextAlign = $Align
    $b.Location  = New-Object System.Drawing.Point($X, $Y)
    $b.Size      = New-Object System.Drawing.Size($W, $H)
    $b.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $b.FlatAppearance.BorderSize = 0
    $b.BackColor = $Bg
    $b.ForeColor = $Fg
    $b.Font      = $Font
    $b.Cursor    = [System.Windows.Forms.Cursors]::Hand
    if ($Tip) {
        $toolTip = New-Object System.Windows.Forms.ToolTip
        $toolTip.SetToolTip($b, $Tip)
    }
    $hc = if ($HoverBg -ne [System.Drawing.Color]::Empty) { $HoverBg } else {
        [System.Drawing.Color]::FromArgb(
            [Math]::Min(255, [int]$Bg.R + 25),
            [Math]::Min(255, [int]$Bg.G + 25),
            [Math]::Min(255, [int]$Bg.B + 25))
    }
    $b.Tag = @($Bg, $hc)
    $b.Add_MouseEnter({ $this.BackColor = ($this.Tag)[1] })
    $b.Add_MouseLeave({ $this.BackColor = ($this.Tag)[0] })
    return $b
}

# ── Sidebar button helper ────────────────────────────────────────────
function New-SidebarButton {
    param([string]$Text, [int]$Y, [string]$Tip = "")
    $b = New-Object System.Windows.Forms.Button
    $b.Text      = $Text
    $b.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $b.Location  = New-Object System.Drawing.Point(0, $Y)
    $b.Size      = New-Object System.Drawing.Size(220, 44)
    $b.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $b.FlatAppearance.BorderSize = 0
    $b.BackColor = $colSidebar
    $b.ForeColor = $colTextSidebar
    $b.Font      = $fontSideBtn
    $b.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $b.Padding   = New-Object System.Windows.Forms.Padding(18, 0, 0, 0)
    if ($Tip) {
        $toolTip = New-Object System.Windows.Forms.ToolTip
        $toolTip.SetToolTip($b, $Tip)
    }
    $b.Add_MouseEnter({ if ($this.Tag -ne "active") { $this.BackColor = $colSidebarHi } })
    $b.Add_MouseLeave({ if ($this.Tag -ne "active") { $this.BackColor = $colSidebar } })
    return $b
}

# ═════════════════════════════════════════════════════════════════════
#  FENETRE PRINCIPALE
# ═════════════════════════════════════════════════════════════════════
$form = New-Object System.Windows.Forms.Form
$form.Text            = "TabtaDev"
$form.Size            = New-Object System.Drawing.Size(1120, 750)
$form.StartPosition   = "CenterScreen"
$form.BackColor       = $colBg
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox     = $false
$form.Font            = $fontBtnSmall

# ═════════════════════════════════════════════════════════════════════
#  SIDEBAR GAUCHE
# ═════════════════════════════════════════════════════════════════════
$sidebar = New-Object System.Windows.Forms.Panel
$sidebar.Location  = New-Object System.Drawing.Point(0, 0)
$sidebar.Size      = New-Object System.Drawing.Size(220, 750)
$sidebar.BackColor = $colSidebar
$form.Controls.Add($sidebar)

# ── Logo ─────────────────────────────────────────────────────────────
$lblBrand = New-Object System.Windows.Forms.Label
$lblBrand.Text      = "TabtaDev"
$lblBrand.Font      = $fontBrand
$lblBrand.ForeColor = $colWhite
$lblBrand.Location  = New-Object System.Drawing.Point(20, 20)
$lblBrand.AutoSize  = $true
$sidebar.Controls.Add($lblBrand)

$lblBrandSub = New-Object System.Windows.Forms.Label
$lblBrandSub.Text      = "Mon Blog"
$lblBrandSub.Font      = $fontSubtitle
$lblBrandSub.ForeColor = $colTextSidebar
$lblBrandSub.Location  = New-Object System.Drawing.Point(22, 50)
$lblBrandSub.AutoSize  = $true
$sidebar.Controls.Add($lblBrandSub)

# ── Separateur sidebar ──────────────────────────────────────────────
$sepSide = New-Object System.Windows.Forms.Label
$sepSide.Location  = New-Object System.Drawing.Point(18, 78)
$sepSide.Size      = New-Object System.Drawing.Size(184, 1)
$sepSide.BackColor = $colSidebarHi
$sidebar.Controls.Add($sepSide)

# ── Navigation sidebar ──────────────────────────────────────────────
$sideNavArticles = New-SidebarButton "   Mes articles"    92
$sideNavMenu     = New-SidebarButton "   Menu du site"   140

$sidebar.Controls.AddRange(@($sideNavArticles, $sideNavMenu))

# ── Separateur 2 ────────────────────────────────────────────────────
$sepSide2 = New-Object System.Windows.Forms.Label
$sepSide2.Location  = New-Object System.Drawing.Point(18, 200)
$sepSide2.Size      = New-Object System.Drawing.Size(184, 1)
$sepSide2.BackColor = $colSidebarHi
$sidebar.Controls.Add($sepSide2)

# ── Actions sidebar ─────────────────────────────────────────────────
$sideNewArticle = New-SidebarButton "   Nouvel article"  216 -Tip "Creer un nouvel article Markdown"
$sidePreview    = New-SidebarButton "   Voir mon site"   264 -Tip "Ouvrir le site dans le navigateur"

$sidebar.Controls.AddRange(@($sideNewArticle, $sidePreview))

# ── Bouton PUBLIER (bas de sidebar) ─────────────────────────────────
$btnPublish = New-Object System.Windows.Forms.Button
$btnPublish.Text      = "Publier mon site"
$btnPublish.Location  = New-Object System.Drawing.Point(15, 645)
$btnPublish.Size      = New-Object System.Drawing.Size(190, 50)
$btnPublish.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnPublish.FlatAppearance.BorderSize = 0
$btnPublish.BackColor = $colGreen
$btnPublish.ForeColor = $colWhite
$btnPublish.Font      = $fontBtnBig
$btnPublish.Cursor    = [System.Windows.Forms.Cursors]::Hand
$btnPublish.Tag       = @($colGreen, $colGreenDark)
$btnPublish.Add_MouseEnter({ $this.BackColor = ($this.Tag)[1] })
$btnPublish.Add_MouseLeave({ $this.BackColor = ($this.Tag)[0] })
$publishTip = New-Object System.Windows.Forms.ToolTip
$publishTip.SetToolTip($btnPublish, "Convertit vos articles et met a jour tout le site")
$sidebar.Controls.Add($btnPublish)

# ═════════════════════════════════════════════════════════════════════
#  ZONE CONTENU (droite de la sidebar)
# ═════════════════════════════════════════════════════════════════════
$contentX = 240
$contentW = 845

# ── En-tete section ─────────────────────────────────────────────────
$lblSectionTitle = New-Object System.Windows.Forms.Label
$lblSectionTitle.Text      = "Mes articles"
$lblSectionTitle.Font      = $fontSection
$lblSectionTitle.ForeColor = $colTextDark
$lblSectionTitle.Location  = New-Object System.Drawing.Point($contentX, 18)
$lblSectionTitle.AutoSize  = $true
$form.Controls.Add($lblSectionTitle)

$lblSectionHint = New-Object System.Windows.Forms.Label
$lblSectionHint.Text      = "Double-cliquez sur un article pour l'ouvrir et le modifier."
$lblSectionHint.Font      = $fontSubtitle
$lblSectionHint.ForeColor = $colTextMuted
$lblSectionHint.Location  = New-Object System.Drawing.Point(($contentX + 2), 42)
$lblSectionHint.AutoSize  = $true
$form.Controls.Add($lblSectionHint)

# ═════════════════════════════════════════════════════════════════════
#  PANNEAU ARTICLES (card)
# ═════════════════════════════════════════════════════════════════════
$panelArticles = New-Object System.Windows.Forms.Panel
$panelArticles.Location  = New-Object System.Drawing.Point($contentX, 68)
$panelArticles.Size      = New-Object System.Drawing.Size($contentW, 460)
$panelArticles.BackColor = $colCard
$form.Controls.Add($panelArticles)

$listView = New-Object System.Windows.Forms.ListView
$listView.Location      = New-Object System.Drawing.Point(1, 1)
$listView.Size          = New-Object System.Drawing.Size(843, 458)
$listView.View          = [System.Windows.Forms.View]::Details
$listView.FullRowSelect = $true
$listView.GridLines     = $false
$listView.Font          = $fontList
$listView.BackColor     = $colCard
$listView.ForeColor     = $colTextDark
$listView.BorderStyle   = [System.Windows.Forms.BorderStyle]::None
$listView.Columns.Add("Titre", 400)   | Out-Null
$listView.Columns.Add("Date",  140)   | Out-Null
$listView.Columns.Add("Dossier", 280) | Out-Null
$panelArticles.Controls.Add($listView)

# ═════════════════════════════════════════════════════════════════════
#  PANNEAU MENU DU SITE (card, cache au demarrage)
# ═════════════════════════════════════════════════════════════════════
$panelNav = New-Object System.Windows.Forms.Panel
$panelNav.Location  = New-Object System.Drawing.Point($contentX, 68)
$panelNav.Size      = New-Object System.Drawing.Size($contentW, 460)
$panelNav.BackColor = $colCard
$panelNav.Visible   = $false
$form.Controls.Add($panelNav)

$treeView = New-Object System.Windows.Forms.TreeView
$treeView.Location      = New-Object System.Drawing.Point(1, 1)
$treeView.Size          = New-Object System.Drawing.Size(843, 390)
$treeView.Font          = $fontList
$treeView.BackColor     = $colCard
$treeView.ForeColor     = $colTextDark
$treeView.BorderStyle   = [System.Windows.Forms.BorderStyle]::None
$treeView.HideSelection = $false
$treeView.ItemHeight    = 28
$panelNav.Controls.Add($treeView)

# ── Barre d'actions nav (dans le card) ──────────────────────────────
$navActionsY = 400
$btnNavAddCat  = New-FlatButton "Ajouter une categorie" 10  $navActionsY 190 36 -Bg $colGreen   -HoverBg $colGreenDark -Font $fontBtnSmall -Tip "Ajouter un groupe dans le menu"
$btnNavAddLink = New-FlatButton "Ajouter une page"      210 $navActionsY 170 36 -Bg $colBlue    -HoverBg $colBlueDark  -Font $fontBtnSmall -Tip "Choisir une page a ajouter"
$btnNavRemove  = New-FlatButton "Supprimer"              390 $navActionsY 100 36 -Bg $colRed     -HoverBg $colRedDark   -Font $fontBtnSmall -Tip "Supprimer l'element selectionne"
$btnNavUp      = New-FlatButton "Haut"                   506 $navActionsY 55  36 -Bg ([System.Drawing.Color]::FromArgb(100, 116, 139)) -Font $fontBtnSmall -Tip "Monter"
$btnNavDown    = New-FlatButton "Bas"                    566 $navActionsY 55  36 -Bg ([System.Drawing.Color]::FromArgb(100, 116, 139)) -Font $fontBtnSmall -Tip "Descendre"
$btnNavSave    = New-FlatButton "Enregistrer le menu"    640 $navActionsY 195 36 -Bg $colGreen   -HoverBg $colGreenDark -Font $fontBtn -Tip "Sauvegarder et appliquer"

$panelNav.Controls.AddRange(@($btnNavAddCat, $btnNavAddLink, $btnNavRemove, $btnNavUp, $btnNavDown, $btnNavSave))

# ═════════════════════════════════════════════════════════════════════
#  JOURNAL (bas)
# ═════════════════════════════════════════════════════════════════════
$journalY = 536
$lblConsole = New-Object System.Windows.Forms.Label
$lblConsole.Text      = "JOURNAL"
$lblConsole.Font      = $fontLabel
$lblConsole.ForeColor = $colTextMuted
$lblConsole.Location  = New-Object System.Drawing.Point($contentX, $journalY)
$lblConsole.AutoSize  = $true
$form.Controls.Add($lblConsole)

$btnClear = New-FlatButton "Effacer" 1020 $journalY 65 18 -Bg $colBg -Fg $colTextMuted -HoverBg $colBorder -Font $fontBtnSmall
$form.Controls.Add($btnClear)

$script:consoleBox = New-Object System.Windows.Forms.RichTextBox
$consoleBox.Location    = New-Object System.Drawing.Point($contentX, ($journalY + 20))
$consoleBox.Size        = New-Object System.Drawing.Size($contentW, 150)
$consoleBox.ReadOnly    = $true
$consoleBox.BackColor   = $colConsoleBg
$consoleBox.ForeColor   = $colConsoleFg
$consoleBox.Font        = $fontConsole
$consoleBox.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$consoleBox.WordWrap    = $true
$form.Controls.Add($consoleBox)

# ── Barre de statut ─────────────────────────────────────────────────
$statusBar = New-Object System.Windows.Forms.StatusStrip
$statusBar.BackColor = $colBg
$statusBar.SizingGrip = $false
$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text      = "Pret"
$statusLabel.ForeColor = $colTextMuted
$statusBar.Items.Add($statusLabel) | Out-Null
$form.Controls.Add($statusBar)

# ═════════════════════════════════════════════════════════════════════
#  NAVIGATION SIDEBAR : changer de section
# ═════════════════════════════════════════════════════════════════════
$script:currentSection = "articles"
$allSideButtons = @($sideNavArticles, $sideNavMenu)

function Set-ActiveSection {
    param([string]$Section)
    $script:currentSection = $Section
    foreach ($sb in $allSideButtons) {
        $sb.BackColor = $colSidebar
        $sb.ForeColor = $colTextSidebar
        $sb.Tag       = $null
    }
    switch ($Section) {
        "articles" {
            $sideNavArticles.BackColor = $colSidebarAct
            $sideNavArticles.ForeColor = $colWhite
            $sideNavArticles.Tag       = "active"
            $panelArticles.Visible     = $true
            $panelNav.Visible          = $false
            $lblSectionTitle.Text      = "Mes articles"
            $lblSectionHint.Text       = "Double-cliquez sur un article pour l'ouvrir et le modifier."
        }
        "nav" {
            $sideNavMenu.BackColor     = $colSidebarAct
            $sideNavMenu.ForeColor     = $colWhite
            $sideNavMenu.Tag           = "active"
            $panelArticles.Visible     = $false
            $panelNav.Visible          = $true
            $lblSectionTitle.Text      = "Menu du site"
            $lblSectionHint.Text       = "Organisez les liens qui apparaissent dans le menu de navigation."
        }
    }
}

$sideNavArticles.Add_Click({ Set-ActiveSection "articles" })
$sideNavMenu.Add_Click({ Set-ActiveSection "nav" })
Set-ActiveSection "articles"

# ═════════════════════════════════════════════════════════════════════
#  Fonctions utilitaires
# ═════════════════════════════════════════════════════════════════════

function Refresh-ArticleList {
    $listView.Items.Clear()
    $mdFiles = Get-ChildItem -Path "$projectRoot\articles" -Recurse -Filter "*.md" -ErrorAction SilentlyContinue
    foreach ($f in $mdFiles) {
        $title = $f.BaseName
        $date  = ""
        $lines = Get-Content $f.FullName -TotalCount 10 -Encoding UTF8 -ErrorAction SilentlyContinue
        if ($lines -and $lines[0] -eq '---') {
            foreach ($ln in $lines[1..9]) {
                if ($ln -eq '---') { break }
                if ($ln -match '^title:\s*(.+)') { $title = $Matches[1].Trim() }
                if ($ln -match '^date:\s*(.+)')  { $date  = $Matches[1].Trim() }
            }
        }
        $rel = $f.FullName.Substring($projectRoot.Length + 1)
        $folder = Split-Path $rel -Parent
        $item = New-Object System.Windows.Forms.ListViewItem($title)
        $item.SubItems.Add($date)   | Out-Null
        $item.SubItems.Add($folder) | Out-Null
        $item.Tag = $f.FullName
        $listView.Items.Add($item) | Out-Null
    }
    $statusLabel.Text = "$($listView.Items.Count) article(s)"
}

$navConfigPath = "$scriptsDir\nav_config.json"

function Load-NavTree {
    $treeView.Nodes.Clear()
    if (-not (Test-Path $navConfigPath)) { return }
    $json = Get-Content -Path $navConfigPath -Raw -Encoding UTF8
    $config = $json | ConvertFrom-Json

    function Add-Items {
        param($items, $parentNode)
        foreach ($item in $items) {
            $node = New-Object System.Windows.Forms.TreeNode($item.label)
            $hasHref = $item.PSObject.Properties.Name -contains 'href' -and $item.href
            $hasChildren = $item.PSObject.Properties.Name -contains 'children' -and $item.children.Count -gt 0
            if ($hasHref) { $node.Tag = $item.href }
            if ($hasChildren) {
                $node.Tag = if ($hasHref) { $item.href } else { "__category__" }
                Add-Items -items $item.children -parentNode $node
            }
            if ($null -eq $parentNode) {
                $treeView.Nodes.Add($node) | Out-Null
            } else {
                $parentNode.Nodes.Add($node) | Out-Null
            }
        }
    }
    Add-Items -items $config.items -parentNode $null
    $treeView.ExpandAll()
}

function Save-NavConfig {
    function Export-Nodes {
        param($nodes)
        $list = [System.Collections.ArrayList]::new()
        foreach ($node in $nodes) {
            $obj = @{ label = $node.Text }
            if ($node.Tag -and $node.Tag -ne "__category__") {
                $obj.href = $node.Tag
            }
            if ($node.Nodes.Count -gt 0) {
                $obj.children = Export-Nodes -nodes $node.Nodes
            }
            $list.Add($obj) | Out-Null
        }
        return ,$list.ToArray()
    }
    $items = Export-Nodes -nodes $treeView.Nodes
    $config = @{ items = $items }
    $json = $config | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($navConfigPath, $json, [System.Text.UTF8Encoding]::new($false))
}

# Charger au demarrage
Refresh-ArticleList
Load-NavTree

# ═════════════════════════════════════════════════════════════════════
#  Actions des boutons
# ═════════════════════════════════════════════════════════════════════

# ── PUBLIER MON SITE (build + deploy nav : tout-en-un) ───────────────
$btnPublish.Add_Click({
    Write-Console "--- Publication en cours... ---" $colGreen
    $statusLabel.Text = "Publication en cours..."
    $ok = $true

    # Sauvegarder le menu avant de publier
    Save-NavConfig

    # Etape 1 : Convertir les articles Markdown en HTML
    Write-Console "" $colConsoleFg
    Write-Console "[1/2] Conversion des articles..." $colGreen
    try {
        $output = & "$scriptsDir\convert_md_to_html.ps1" 2>&1
        foreach ($line in $output) { Write-Console "  $line" }
    } catch {
        Write-Console "Erreur : $_" $colRed
        $ok = $false
    }

    # Etape 2 : Mettre a jour le menu de navigation
    Write-Console "" $colConsoleFg
    Write-Console "[2/2] Mise a jour du menu..." $colGreen
    try {
        $output = & "$scriptsDir\deploy_nav.ps1" 2>&1
        foreach ($line in $output) { Write-Console "  $line" }
    } catch {
        Write-Console "Erreur : $_" $colRed
        $ok = $false
    }

    if ($ok) {
        Write-Console "" $colConsoleFg
        Write-Console "Votre site est pret ! Cliquez sur 'Voir mon site' pour le tester." $colGreen
        $statusLabel.Text = "Site publie avec succes"
    } else {
        Write-Console "Des erreurs sont survenues. Verifiez le journal ci-dessus." $colRed
        $statusLabel.Text = "Erreurs lors de la publication"
    }
    Refresh-ArticleList
})

# ── VOIR MON SITE ────────────────────────────────────────────────────
$sidePreview.Add_Click({
    $indexPath = "$projectRoot\index.html"
    if (Test-Path $indexPath) {
        Start-Process $indexPath
        Write-Console "Site ouvert dans le navigateur." $colGreen
        $statusLabel.Text = "Apercu ouvert"
    } else {
        Write-Console "Le fichier index.html n'existe pas encore. Publiez d'abord votre site." $colRed
    }
})

# ── NOUVEL ARTICLE ───────────────────────────────────────────────────
$sideNewArticle.Add_Click({
    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text            = "Nouvel article"
    $dlg.Size            = New-Object System.Drawing.Size(460, 380)
    $dlg.StartPosition   = "CenterParent"
    $dlg.BackColor       = $colBg
    $dlg.FormBorderStyle = "FixedDialog"
    $dlg.MaximizeBox     = $false
    $dlg.MinimizeBox     = $false
    $dlg.Font            = $fontBtnSmall

    $y = 20
    foreach ($pair in @(
        @{L="CATEGORIE (dossier sous articles/)"; N="txtFolder"; D="intro"},
        @{L="NOM DU FICHIER (sans .md)";          N="txtFile";   D="mon-article"},
        @{L="TITRE DE L'ARTICLE";                 N="txtTitle";  D="Mon nouvel article"},
        @{L="TAGS (separes par des virgules)";     N="txtTags";   D="tag1, tag2"}
    )) {
        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text = $pair.L; $lbl.Font = $fontLabel; $lbl.ForeColor = $colTextMuted
        $lbl.Location = New-Object System.Drawing.Point(20, $y); $lbl.AutoSize = $true
        $dlg.Controls.Add($lbl)
        $y += 20
        $txt = New-Object System.Windows.Forms.TextBox
        $txt.Name = $pair.N; $txt.Text = $pair.D
        $txt.Location = New-Object System.Drawing.Point(20, $y)
        $txt.Size = New-Object System.Drawing.Size(400, 28)
        $dlg.Controls.Add($txt)
        $y += 42
    }

    $btnCreate = New-FlatButton "Creer l'article" 150 ($y + 5) 160 40 -Bg $colGreen
    $btnCreate.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $dlg.AcceptButton = $btnCreate
    $dlg.Controls.Add($btnCreate)

    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $folder = $dlg.Controls["txtFolder"].Text.Trim()
        $file   = $dlg.Controls["txtFile"].Text.Trim()
        $title  = $dlg.Controls["txtTitle"].Text.Trim()
        $tags   = $dlg.Controls["txtTags"].Text.Trim()

        if (-not $folder -or -not $file -or -not $title) {
            Write-Console "Veuillez remplir la categorie, le nom du fichier et le titre." $colRed
            $dlg.Dispose(); return
        }

        $dir  = "$projectRoot\articles\$folder"
        $path = "$dir\$file.md"
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

        if (Test-Path $path) {
            Write-Console "Ce fichier existe deja : $path" $colRed
            $dlg.Dispose(); return
        }

        $today   = Get-Date -Format "yyyy-MM-dd"
        $tagList = ($tags -split ',\s*' | ForEach-Object { $_.Trim() }) -join ', '

        $content = @"
---
title: $title
date: $today
tags: [$tagList]
description: $title
---

# $title

Ecrivez votre contenu ici en Markdown.
"@
        Set-Content -Path $path -Value $content -Encoding UTF8
        Write-Console "Article cree : $path" $colGreen
        Write-Console "Ouvrez-le avec un editeur de texte, ecrivez, puis cliquez sur 'Publier mon site'." $colGreen
        $statusLabel.Text = "Article cree"
        Refresh-ArticleList
    }
    $dlg.Dispose()
})

# ── EFFACER LE JOURNAL ───────────────────────────────────────────────
$btnClear.Add_Click({ $consoleBox.Clear() })

# ── Double-clic sur article -> ouvrir ────────────────────────────────
$listView.Add_DoubleClick({
    if ($listView.SelectedItems.Count -gt 0) {
        $filePath = $listView.SelectedItems[0].Tag
        if (Test-Path $filePath) {
            Start-Process $filePath
            Write-Console "Ouvert : $filePath"
        }
    }
})

# ═════════════════════════════════════════════════════════════════════
#  Actions du menu de navigation
# ═════════════════════════════════════════════════════════════════════

$btnNavAddCat.Add_Click({
    $name = [Microsoft.VisualBasic.Interaction]::InputBox("Nom de la categorie :", "Ajouter une categorie", "Nouvelle categorie")
    if (-not $name) { return }
    $node = New-Object System.Windows.Forms.TreeNode($name)
    $node.Tag = "__category__"
    $sel = $treeView.SelectedNode
    if ($sel) { $sel.Nodes.Add($node) | Out-Null; $sel.Expand() }
    else      { $treeView.Nodes.Add($node) | Out-Null }
    Write-Console "Categorie ajoutee : $name" $colGreen
})

$btnNavAddLink.Add_Click({
    # Chercher toutes les pages HTML du projet
    $htmlFiles = Get-ChildItem -Path $projectRoot -Recurse -Filter "*.html" -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '\\nav_template\.html$' } |
        Sort-Object FullName

    # Construire la liste : titre lisible + chemin relatif
    $pageList = @()
    foreach ($hf in $htmlFiles) {
        $rel = $hf.FullName.Substring($projectRoot.Length + 1).Replace('\', '/')
        # Essayer de lire le <title> pour un nom lisible
        $displayName = $hf.BaseName
        $headContent = Get-Content $hf.FullName -TotalCount 15 -Encoding UTF8 -ErrorAction SilentlyContinue
        if ($headContent) {
            $joined = $headContent -join ' '
            if ($joined -match '<title>([^<]+)</title>') {
                $displayName = $Matches[1].Trim()
                if ($displayName -match '(.*?)\s*[-|]') { $displayName = $Matches[1].Trim() }
            }
        }
        $pageList += @{ Display = "$displayName  ($rel)"; Href = $rel; Title = $displayName }
    }

    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = "Ajouter une page au menu"
    $dlg.Size = New-Object System.Drawing.Size(480, 430)
    $dlg.StartPosition = "CenterParent"
    $dlg.BackColor = $colBg
    $dlg.FormBorderStyle = "FixedDialog"
    $dlg.MaximizeBox = $false; $dlg.MinimizeBox = $false
    $dlg.Font = $fontBtnSmall

    $l1 = New-Object System.Windows.Forms.Label
    $l1.Text = "CHOISISSEZ UNE PAGE"; $l1.Font = $fontLabel; $l1.ForeColor = $colTextMuted
    $l1.Location = New-Object System.Drawing.Point(15, 12); $l1.AutoSize = $true
    $dlg.Controls.Add($l1)

    $lb = New-Object System.Windows.Forms.ListBox
    $lb.Name = "lbPages"
    $lb.Location = New-Object System.Drawing.Point(15, 32)
    $lb.Size = New-Object System.Drawing.Size(435, 240)
    $lb.Font = $fontList
    $lb.BackColor = $colWhite
    $lb.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    foreach ($p in $pageList) { $lb.Items.Add($p.Display) | Out-Null }
    $dlg.Controls.Add($lb)

    $l2 = New-Object System.Windows.Forms.Label
    $l2.Text = "NOM AFFICHE DANS LE MENU"; $l2.Font = $fontLabel; $l2.ForeColor = $colTextMuted
    $l2.Location = New-Object System.Drawing.Point(15, 282); $l2.AutoSize = $true
    $dlg.Controls.Add($l2)

    $t1 = New-Object System.Windows.Forms.TextBox; $t1.Name = "txtLabel"
    $t1.Location = New-Object System.Drawing.Point(15, 302); $t1.Size = New-Object System.Drawing.Size(435, 24)
    $dlg.Controls.Add($t1)

    # Auto-remplir le nom quand on selectionne une page
    $lb.Add_SelectedIndexChanged({
        $idx = $lb.SelectedIndex
        if ($idx -ge 0) {
            $t1.Text = $pageList[$idx].Title
        }
    })

    $bOk = New-FlatButton "Ajouter au menu" 155 345 160 36 -Bg $colGreen
    $bOk.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $dlg.AcceptButton = $bOk
    $dlg.Controls.Add($bOk)

    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $idx   = $lb.SelectedIndex
        $label = $t1.Text.Trim()
        if ($idx -lt 0 -or -not $label) {
            Write-Console "Selectionnez une page et donnez-lui un nom." $colRed
            $dlg.Dispose(); return
        }
        $href = $pageList[$idx].Href
        $node = New-Object System.Windows.Forms.TreeNode($label)
        $node.Tag = $href
        $sel = $treeView.SelectedNode
        if ($sel) { $sel.Nodes.Add($node) | Out-Null; $sel.Expand() }
        else      { $treeView.Nodes.Add($node) | Out-Null }
        Write-Console "Page ajoutee au menu : $label" $colGreen
    }
    $dlg.Dispose()
})

$btnNavRemove.Add_Click({
    $sel = $treeView.SelectedNode
    if (-not $sel) { Write-Console "Selectionnez un element a supprimer." $colRed; return }
    $sel.Remove()
    Write-Console "Element supprime du menu." $colGreen
})

$btnNavUp.Add_Click({
    $sel = $treeView.SelectedNode; if (-not $sel) { return }
    $idx = $sel.Index
    if ($idx -gt 0) {
        $parent = $sel.Parent
        $clone = $sel.Clone()
        $sel.Remove()
        if ($parent) { $parent.Nodes.Insert($idx - 1, $clone) }
        else         { $treeView.Nodes.Insert($idx - 1, $clone) }
        $treeView.SelectedNode = $clone
    }
})

$btnNavDown.Add_Click({
    $sel = $treeView.SelectedNode; if (-not $sel) { return }
    $idx = $sel.Index
    $parent = $sel.Parent
    $count = if ($parent) { $parent.Nodes.Count } else { $treeView.Nodes.Count }
    if ($idx -lt ($count - 1)) {
        $clone = $sel.Clone()
        $sel.Remove()
        if ($parent) { $parent.Nodes.Insert($idx + 1, $clone) }
        else         { $treeView.Nodes.Insert($idx + 1, $clone) }
        $treeView.SelectedNode = $clone
    }
})

$btnNavSave.Add_Click({
    Save-NavConfig
    Write-Console "Menu enregistre." $colGreen
    try {
        $output = & "$scriptsDir\deploy_nav.ps1" 2>&1
        foreach ($line in $output) { Write-Console "  $line" }
        Write-Console "Le menu a ete applique a toutes les pages." $colGreen
        $statusLabel.Text = "Menu mis a jour"
    } catch {
        Write-Console "Erreur : $_" $colRed
    }
})

# ═════════════════════════════════════════════════════════════════════
#  Demarrage
# ═════════════════════════════════════════════════════════════════════
Write-Console "Bienvenue dans TabtaDev !" $colGreen
Write-Console "Projet : $projectRoot" $colTextMuted
Write-Console ""
Write-Console "Pour commencer :" $colConsoleFg
Write-Console "  1. Creez ou modifiez vos articles (onglet 'Mes articles')" $colConsoleFg
Write-Console "  2. Organisez votre menu (onglet 'Menu du site')" $colConsoleFg
Write-Console "  3. Cliquez sur 'Publier mon site' quand c'est pret !" $colConsoleFg
Write-Console ""

$form.Add_Shown({ $form.Activate() })
[System.Windows.Forms.Application]::Run($form)

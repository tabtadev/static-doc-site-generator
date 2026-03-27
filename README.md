# TabtaDev- Static Blog Generator

A lightweight static site generator built with PowerShell. No dependencies, no frameworks- just scripts that convert Markdown to HTML and deploy a fully navigable blog to GitHub Pages.

**Live site:** [tabtadev.github.io](https://tabtadev.github.io/index.html)

## Why?

Most static site generators (Jekyll, Hugo, etc.) require installing runtimes, package managers, and config files. This project takes a different approach: everything runs on PowerShell, which is already on every Windows machine. Write Markdown, click publish, done.

## Features

- **Markdown → HTML**- Custom converter supporting frontmatter (title, date, tags), table of contents, code blocks with syntax highlighting (highlight.js), tables, blockquotes, task lists
- **Navigation management**- JSON-based menu config with categories, subcategories, and auto-deployment to all pages
- **Dark/light mode**- CSS custom properties + localStorage persistence, follows OS preference
- **Desktop GUI**- WinForms interface for managing articles, editing the nav tree, and one-click publishing
- **Article index**- Auto-generated article listing page, sorted by date, with tags and descriptions
- **Responsive**- Mobile-friendly layout with media queries

## Quick Start

```powershell
# Clone the repo
git clone https://github.com/tabtadev/tabtadev.github.io.git
cd tabtadev.github.io

# Launch the site manager (GUI)
.\site_manager.ps1

# Or use the VBS launcher (hides the PowerShell console)
# Double-click TabtaDev.vbs
```

### Writing an article

1. Create a `.md` file in `articles/` with YAML frontmatter:

```markdown
---
title: My Article
date: 2026-01-15
tags: powershell, web
description: A short summary.
---

Your content here. Supports **bold**, *italic*, `code`, lists, tables, etc.
```

2. Click **Publier mon site** in the GUI (or run the scripts manually).
3. The HTML is generated, navigation updated, and the site is ready to push.

### Manual build (no GUI)

```powershell
# Convert all .md files to .html + build article index
powershell -File _scripts\convert_md_to_html.ps1

# Generate nav from config and deploy to all pages
powershell -File _scripts\deploy_nav.ps1
```

## Project Structure

```
├── index.html              # Homepage
├── about.html              # About page
├── articles.html           # Auto-generated article index
├── site_manager.ps1        # Desktop GUI (WinForms)
├── TabtaDev.vbs            # Console-less launcher
├── css/style.css           # Stylesheet (light + dark mode)
├── js/main.js              # Theme toggle logic
├── articles/               # Markdown sources + generated HTML
│   └── intro/
│       ├── Intro.md
│       └── intro.html
├── images/                 # Site assets
└── _scripts/               # Build pipeline
    ├── convert_md_to_html.ps1   # Markdown converter
    ├── deploy_nav.ps1           # Nav generator + deployer
    └── nav_config.json          # Menu structure
```

## How It Works

1. **`convert_md_to_html.ps1`** parses each `.md` file- extracts YAML frontmatter, converts Markdown to semantic HTML, generates a table of contents from headings, injects the navigation template, and builds the `articles.html` index page.

2. **`deploy_nav.ps1`** reads `nav_config.json` (the menu tree), generates `nav_template.html`, then replaces the `<nav>` block in every HTML file- adjusting relative paths based on each file's directory depth.

3. **`site_manager.ps1`** ties it all together in a WinForms GUI: article management, nav tree editing, and a publish button that runs both scripts in sequence.

## Requirements

- Windows with PowerShell 5.1+ (pre-installed on Windows 10/11)
- That's it.

## License

MIT

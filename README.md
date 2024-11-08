# TabtaDev (tabtadev.github.io)

TabtaDev is a static website hosted on GitHub Pages, created as a side project to share beginner-friendly programming tutorials. Built entirely from scratch without frameworks like Jekyll or Hugo.

## Project Overview

The main goals of TabtaDev are to provide:

- **Programming Tutorials**: Simple content aimed at those interested in starting with programming.
- **Markdown-to-HTML Conversion**: A custom PowerShell script that converts Markdown files into HTML, enabling flexible content management.
- **Automated Navigation and Styling**: Scripts automatically manage the navigation bar, footers, and CSS links, ensuring a consistent look across the site.

## Features

- **Static Hosting on GitHub Pages**: A quick and reliable hosting solution using GitHub Pages.
- **Custom Markdown Conversion**: A PowerShell script, `convert_md_to_html.ps1`, processes `.md` files into HTML, supporting standard Markdown syntax such as headers, lists, code blocks, images, and links.
- **Automated Navigation and Footer Deployment**:
  - **Navigation**: The `deploy_nav_footer.ps1` script dynamically updates navigation links across all pages, including adding new article links as they are created.
  - **Footer Customization**: The script also supports footer customization, providing a consistent footer across the site.
- **CSS Link Management**: The `check_css.ps1` script ensures all pages are linked to the correct CSS stylesheet path based on folder depth.
- **Modern, Minimal Design**: A clean design that provides a focused reading experience.

## Setup & Deployment

### Prerequisites

Ensure you have PowerShell installed to run the deployment and conversion scripts.

### Clone the Repository

Clone this repository to your local machine: `git clone https://github.com/tabtadev/tabtadev.github.io.git`

### Adding New Articles

1. Write your content in a Markdown file (e.g., `my-article.md`).
2. Save the Markdown file in the appropriate directory.

### Deployment Steps

1. **Convert Markdown to HTML**: Run the `convert_md_to_html.ps1` script to convert all `.md` files to `.html`.
2. **Update Navigation and Footer**: Run the `deploy_nav_footer.ps1` script with the footer argument to update navigation and footer content on all pages:
   - `.\deploy_nav_footer.ps1 -FooterText "© 2024 TabtaDev. All rights reserved."`
3. **Check CSS Links**: Run the `check_css.ps1` script to verify that each HTML file is linked to the correct CSS path based on its folder depth.
4. **Automate the Deployment Process**: Alternatively, run the `deploy.ps1` script to execute all the above steps in sequence:
   - `.\deploy.ps1`

## Folder Structure

- `articles/`: Contains Markdown and HTML files for tutorials and articles.
- `css/`: Contains the main stylesheet (`style.css`) for the site.
- `scripts/`: PowerShell scripts used for Markdown conversion, navigation/footer deployment, and CSS path verification.

## Scripts Overview

- **convert_md_to_html.ps1**: Converts Markdown files in `articles/` to HTML.
- **deploy_nav_footer.ps1**: Deploys navigation and footer across all HTML pages. Accepts a `FooterText` parameter to customize the footer text.
- **check_css.ps1**: Verifies and updates CSS link paths in all HTML files according to their directory depth.
- **deploy.ps1**: Automates the conversion, navigation, footer, and CSS path verification steps in one command.

## Future Development

Potential improvements for this side project include:

- **Multi-language support** for a wider audience.
- **SEO Enhancements** to improve search engine visibility.
- **Advanced Markdown Formatting** for additional flexibility in article layout.
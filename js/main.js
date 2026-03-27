/* ═══ TabtaDev - Dark Mode Toggle ═══ */
(function () {
    'use strict';

    var LIGHT_SHEET = 'https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github.min.css';
    var DARK_SHEET  = 'https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github-dark.min.css';

    function setTheme(theme) {
        document.documentElement.setAttribute('data-theme', theme);
        localStorage.setItem('theme', theme);

        // Update highlight.js stylesheet if present
        var hljsLink = document.getElementById('hljs-theme');
        if (hljsLink) {
            hljsLink.href = (theme === 'dark') ? DARK_SHEET : LIGHT_SHEET;
        }

        // Update button icon
        var btn = document.getElementById('theme-toggle');
        if (btn) {
            btn.textContent = (theme === 'dark') ? '\u2600\uFE0F' : '\uD83C\uDF19';
        }
    }

    // Determine initial theme: saved > OS preference > light
    var saved = localStorage.getItem('theme');
    if (!saved) {
        saved = (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches)
            ? 'dark' : 'light';
    }
    setTheme(saved);

    // Listen for OS preference changes
    if (window.matchMedia) {
        window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', function (e) {
            if (!localStorage.getItem('theme')) {
                setTheme(e.matches ? 'dark' : 'light');
            }
        });
    }

    // Toggle button click
    document.addEventListener('DOMContentLoaded', function () {
        var btn = document.getElementById('theme-toggle');
        if (btn) {
            btn.addEventListener('click', function () {
                var current = document.documentElement.getAttribute('data-theme') || 'light';
                setTheme(current === 'dark' ? 'light' : 'dark');
            });
        }
    });
})();

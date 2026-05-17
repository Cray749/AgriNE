import re, os

DIR = r'D:\AgriReeti\website'

# ── 1. Fix missing pt-[64px] on all body tags ──────────────────────────────
html_files = [f for f in os.listdir(DIR) if f.endswith('.html')]
for fname in html_files:
    path = os.path.join(DIR, fname)
    with open(path, 'r', encoding='utf-8') as f:
        html = f.read()

    # Add pt-[64px] to body class if not present
    if 'pt-[64px]' not in html and 'pt-24' not in html:
        html = re.sub(
            r'(<body\s+class=")',
            r'\1pt-[64px] ',
            html
        )
        print(f'  Fixed padding: {fname}')
    elif 'pt-24' in html:
        html = html.replace('pt-24', 'pt-[64px]')
        print(f'  Fixed pt-24 -> pt-[64px]: {fname}')
    else:
        print(f'  OK (already has padding): {fname}')

    with open(path, 'w', encoding='utf-8') as f:
        f.write(html)

print('\nAll padding fixes applied!')

import re, os

OUT_DIR = r'D:\AgriReeti\website'

# Full nav links
NAV_LINKS = [
    ('index.html',          'Home'),
    ('recommendation.html', 'Recommendation Tool'),
    ('science.html',        'Science & Methodology'),
    ('features.html',       'Features'),
    ('markets.html',        'Markets'),
    ('advisory.html',       'Advisory'),
    ('analytics.html',      'Analytics'),
    ('maps.html',           'Map View'),
    ('resources.html',      'Resources'),
    ('report.html',         'Regional Report'),
]

# Pages already built that need nav updated
EXISTING = {
    'index.html':          'Home',
    'recommendation.html': 'Recommendation Tool',
    'science.html':        'Science & Methodology',
    'features.html':       'Features',
    'download.html':       None,  # no active link
}

def make_desktop_nav(active_label):
    items = []
    for href, label in NAV_LINKS:
        if label == active_label:
            items.append(
                f'<li><a class="nav-link text-primary font-bold border-b-2 border-primary pb-1 px-2" href="{href}">{label}</a></li>'
            )
        else:
            items.append(
                f'<li><a class="nav-link text-on-surface-variant hover:text-primary px-2 py-1 rounded-md hover:bg-surface-container-low/60" href="{href}">{label}</a></li>'
            )
    return '<ul class="hidden md:flex gap-4 items-center text-body-md flex-wrap">\n' + '\n'.join(items) + '\n</ul>'

def make_mobile_nav(active_label):
    items = []
    for href, label in NAV_LINKS:
        cls = 'text-primary font-bold' if label == active_label else 'text-on-surface-variant'
        items.append(f'  <a href="{href}" class="block py-2 {cls}">{label}</a>')
    items.append('  <a href="download.html" class="block py-2 text-secondary font-bold">Download App</a>')
    return (
        '<div id="mobile-menu" class="hidden md:hidden bg-surface border-t border-outline-variant/20 px-4 py-3 space-y-1">\n'
        + '\n'.join(items)
        + '\n</div>'
    )

for filename, active_label in EXISTING.items():
    path = os.path.join(OUT_DIR, filename)
    if not os.path.exists(path):
        print(f'Skip (not found): {filename}')
        continue

    with open(path, 'r', encoding='utf-8') as f:
        c = f.read()

    # Replace desktop nav <ul>
    c = re.sub(
        r'<ul class="hidden md:flex[^"]*"[^>]*>.*?</ul>',
        make_desktop_nav(active_label),
        c, flags=re.DOTALL
    )

    # Replace mobile menu div
    c = re.sub(
        r'<div id="mobile-menu"[^>]*>.*?</div>(?=\s*</nav>)',
        make_mobile_nav(active_label),
        c, flags=re.DOTALL
    )

    with open(path, 'w', encoding='utf-8') as f:
        f.write(c)
    print(f'Updated nav: {filename}')

print('Done.')

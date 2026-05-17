import re, os

STITCH_DIR = r'D:\AgriReeti\stitch_agrisutra_ne_landing_page'
OUT_DIR    = r'D:\AgriReeti\website'

# Map: stitch folder -> (output filename, active nav label, page title)
PAGES = {
    'juraiva_markets_final':               ('markets.html',  'Markets',              'Markets | AgriSutra NE'),
    'juraiva_advisory_final':              ('advisory.html', 'Advisory',             'Advisory | AgriSutra NE'),
    'juraiva_analytics_final':             ('analytics.html','Analytics',            'Analytics | AgriSutra NE'),
    'juraiva_detailed_regional_report_final': ('report.html','Regional Report',     'Regional Report | AgriSutra NE'),
    'juraiva_map_view_final':              ('maps.html',     'Map View',             'Map View | AgriSutra NE'),
    'juraiva_resources_final':             ('resources.html','Resources',            'Resources | AgriSutra NE'),
}

# Full nav links for all pages
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

def build_nav(active_label):
    items = []
    for href, label in NAV_LINKS:
        if label == active_label:
            items.append(
                f'<a class="text-primary font-bold border-b-2 border-primary pb-1 font-body-md text-body-md px-2" href="{href}">{label}</a>'
            )
        else:
            items.append(
                f'<a class="text-on-surface-variant hover:text-primary font-body-md text-body-md px-2 py-1 rounded-md hover:bg-surface-container-low/60 transition-colors" href="{href}">{label}</a>'
            )
    nav_html = (
        '<div class="hidden md:flex gap-4 items-center flex-wrap">\n'
        + '\n'.join(items)
        + '\n</div>\n'
        + '<a href="download.html" class="bg-[#69F0AE] text-[#1B2E1B] px-5 py-2 rounded-full font-label-caps text-label-caps flex items-center gap-2 hover:-translate-y-0.5 transition-transform shadow-sm whitespace-nowrap"><span class="material-symbols-outlined text-[16px]" style="font-variation-settings:\'FILL\' 1;">android</span>Download App</a>'
    )
    return nav_html

def build_mobile_nav(active_label):
    items = []
    for href, label in NAV_LINKS:
        cls = 'text-primary font-bold' if label == active_label else 'text-on-surface-variant'
        items.append(f'<a href="{href}" class="block py-2 {cls}">{label}</a>')
    items.append('<a href="download.html" class="block py-2 text-secondary font-bold">Download App</a>')
    return (
        '<div id="mobile-menu" class="hidden md:hidden bg-surface border-t border-outline-variant/20 px-4 py-3 space-y-1">\n'
        + '\n'.join(items)
        + '\n</div>'
    )

def patch_page(src_path, out_path, active_label, page_title):
    with open(src_path, 'r', encoding='utf-8') as f:
        c = f.read()

    # Replace screen references
    c = re.sub(r'{{DATA:SCREEN:[^}]+}}', '#', c)

    # Fix title
    c = re.sub(r'<title>[^<]*</title>', f'<title>{page_title}</title>', c)

    # Brand name
    c = c.replace('>Juraiva<', '>AgriSutra NE<')
    c = c.replace('2024 Juraiva', '2024 AgriSutra NE')
    c = c.replace('Juraiva.', 'AgriSutra NE.')
    c = c.replace('Eco-Minimalism for Northeast India', '© 2024 AgriSutra NE · ICAR')

    # Fix footer links (href="#")
    c = c.replace('href="#"', 'href="index.html"')

    # Build new logo/brand link
    logo = '<a href="index.html" class="font-headline-md text-headline-md font-bold text-primary dark:text-primary-fixed flex items-center gap-2"><span class="material-symbols-outlined text-[#69F0AE]" style="font-variation-settings:\'FILL\' 1;">eco</span>AgriSutra NE</a>'

    # Replace old brand div with link
    c = re.sub(
        r'<div class="font-headline-md text-headline-md font-bold text-primary[^"]*"[^>]*>[^<]*(?:Juraiva|AgriSutra NE)[^<]*</div>',
        logo, c
    )

    # Add mobile menu button to nav if not present
    mobile_btn = '<button id="mobile-menu-btn" class="md:hidden text-primary"><span class="material-symbols-outlined">menu</span></button>'

    # Replace nav inner content (between logo and end of nav closing div)
    nav_new = build_nav(active_label)
    mob_nav = build_mobile_nav(active_label)

    # Replace the hidden md:flex nav section + sign-in button
    c = re.sub(
        r'<div class="hidden md:flex[^"]*"[^>]*>.*?</div>\s*<(?:button|a)[^>]*>(?:\s*Sign In\s*|[^<]*Download[^<]*)</(?:button|a)>',
        nav_new + '\n' + mobile_btn,
        c, flags=re.DOTALL
    )

    # Insert mobile menu after </nav>
    c = c.replace('</nav>', '</nav>\n' + mob_nav, 1)

    # Add mobile menu JS before </body>
    mobile_js = '''<script>
var mb = document.getElementById('mobile-menu-btn');
if (mb) mb.addEventListener('click', function() {
  document.getElementById('mobile-menu').classList.toggle('hidden');
});
</script>'''
    c = c.replace('</body>', mobile_js + '\n</body>')

    with open(out_path, 'w', encoding='utf-8') as f:
        f.write(c)
    print(f'  Created: {os.path.basename(out_path)}')

print('Building missing pages...')
for folder, (out_file, active_label, page_title) in PAGES.items():
    src = os.path.join(STITCH_DIR, folder, 'code.html')
    out = os.path.join(OUT_DIR, out_file)
    if not os.path.exists(src):
        print(f'  MISSING source: {src}')
        continue
    patch_page(src, out, active_label, page_title)

print('Done.')

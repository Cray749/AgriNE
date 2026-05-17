import re, os, shutil

DIR = r'D:\AgriReeti\website'

# ── Standard nav (same on every page) ──────────────────────────────────────
NAV = '''<!-- TopNavBar - Jurivya NE -->
<header class="bg-surface/90 backdrop-blur-md fixed top-0 w-full border-b border-outline-variant/30 z-50">
  <div class="flex justify-between items-center px-4 md:px-12 py-3 max-w-[1280px] mx-auto gap-4">
    <a href="index.html" class="flex items-center gap-2 flex-shrink-0">
      <img src="logo.png" alt="Jurivya NE" class="h-10 w-auto object-contain"/>
    </a>
    <nav class="hidden md:flex items-center gap-0.5 flex-nowrap">
      <a class="nav-link px-2.5 py-1.5 rounded-md text-sm text-on-surface-variant hover:text-primary hover:bg-surface-container-low/60 transition-all whitespace-nowrap" href="index.html">Home</a>
      <a class="nav-link px-2.5 py-1.5 rounded-md text-sm text-on-surface-variant hover:text-primary hover:bg-surface-container-low/60 transition-all whitespace-nowrap" href="recommendation.html">Recommendation</a>
      <a class="nav-link px-2.5 py-1.5 rounded-md text-sm text-on-surface-variant hover:text-primary hover:bg-surface-container-low/60 transition-all whitespace-nowrap" href="science.html">Science</a>
      <a class="nav-link px-2.5 py-1.5 rounded-md text-sm text-on-surface-variant hover:text-primary hover:bg-surface-container-low/60 transition-all whitespace-nowrap" href="features.html">Features</a>
      <a class="nav-link px-2.5 py-1.5 rounded-md text-sm text-on-surface-variant hover:text-primary hover:bg-surface-container-low/60 transition-all whitespace-nowrap" href="advisory.html">Advisory</a>
      <a class="nav-link px-2.5 py-1.5 rounded-md text-sm text-on-surface-variant hover:text-primary hover:bg-surface-container-low/60 transition-all whitespace-nowrap" href="maps.html">Map View</a>
      <!-- Resources dropdown -->
      <div class="relative group">
        <button class="nav-link px-2.5 py-1.5 rounded-md text-sm text-on-surface-variant hover:text-primary hover:bg-surface-container-low/60 transition-all whitespace-nowrap flex items-center gap-1">
          Resources <span class="material-symbols-outlined" style="font-size:14px;line-height:1;">expand_more</span>
        </button>
        <div class="absolute top-full left-0 mt-1 w-44 bg-surface-container-lowest border border-outline-variant/30 rounded-xl shadow-lg py-1 opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-200 z-50">
          <a href="markets.html" class="flex items-center gap-2 px-4 py-2.5 text-sm text-on-surface-variant hover:text-primary hover:bg-surface-container-low transition-colors whitespace-nowrap">
            <span class="material-symbols-outlined" style="font-size:16px;">storefront</span>Markets
          </a>
          <a href="analytics.html" class="flex items-center gap-2 px-4 py-2.5 text-sm text-on-surface-variant hover:text-primary hover:bg-surface-container-low transition-colors whitespace-nowrap">
            <span class="material-symbols-outlined" style="font-size:16px;">analytics</span>Analytics
          </a>
          <a href="resources.html" class="flex items-center gap-2 px-4 py-2.5 text-sm text-on-surface-variant hover:text-primary hover:bg-surface-container-low transition-colors whitespace-nowrap">
            <span class="material-symbols-outlined" style="font-size:16px;">library_books</span>All Resources
          </a>
        </div>
      </div>
      <!-- Regional Report – hidden until triggered from Map View -->
      <a id="nav-report-link" class="nav-link px-2.5 py-1.5 rounded-md text-sm text-primary font-bold bg-[#69F0AE]/20 hover:bg-[#69F0AE]/40 transition-all whitespace-nowrap hidden" href="report.html">Regional Report</a>
    </nav>
    <div class="flex items-center gap-2 flex-shrink-0">
      <a href="download.html" class="hidden md:flex bg-[#69F0AE] text-[#1B2E1B] px-4 py-2 rounded-full text-xs font-bold items-center gap-1.5 hover:-translate-y-0.5 transition-transform shadow-sm whitespace-nowrap">
        <span class="material-symbols-outlined" style="font-size:14px;font-variation-settings:'FILL' 1;">android</span>
        Download App
      </a>
      <button id="mobile-menu-btn" class="md:hidden text-primary p-1">
        <span class="material-symbols-outlined">menu</span>
      </button>
    </div>
  </div>
  <!-- Mobile menu -->
  <div id="mobile-menu" class="hidden md:hidden bg-surface border-t border-outline-variant/20 px-4 py-3 space-y-1">
    <a href="index.html" class="block py-2 text-on-surface-variant hover:text-primary">Home</a>
    <a href="recommendation.html" class="block py-2 text-on-surface-variant hover:text-primary">Recommendation</a>
    <a href="science.html" class="block py-2 text-on-surface-variant hover:text-primary">Science &amp; Methodology</a>
    <a href="features.html" class="block py-2 text-on-surface-variant hover:text-primary">Features</a>
    <a href="advisory.html" class="block py-2 text-on-surface-variant hover:text-primary">Advisory</a>
    <a href="maps.html" class="block py-2 text-on-surface-variant hover:text-primary">Map View</a>
    <a href="markets.html" class="block py-2 text-on-surface-variant hover:text-primary">Markets</a>
    <a href="analytics.html" class="block py-2 text-on-surface-variant hover:text-primary">Analytics</a>
    <a href="resources.html" class="block py-2 text-on-surface-variant hover:text-primary">Resources</a>
    <a id="nav-report-mobile" href="report.html" class="hidden py-2 text-primary font-bold block">Regional Report</a>
    <a href="download.html" class="block py-2 text-secondary font-bold">Download App</a>
  </div>
</header>'''

NAV_JS = '''<script>
(function(){
  // Mobile menu
  var btn=document.getElementById('mobile-menu-btn');
  if(btn) btn.addEventListener('click',function(){
    document.getElementById('mobile-menu').classList.toggle('hidden');
  });
  // Show Regional Report link only if navigated from Map View
  if(sessionStorage.getItem('jurivya_from_map')){
    var d=document.getElementById('nav-report-link');
    if(d) d.classList.remove('hidden');
    var m=document.getElementById('nav-report-mobile');
    if(m) m.classList.remove('hidden');
  }
})();
</script>'''

# ── Helper: find first complete block of a tag (handles nesting) ───────────
def find_tag_block(html, tag):
    op = re.compile(r'<' + tag + r'[\s>\/]', re.I)
    cl = re.compile(r'<\/' + tag + r'>', re.I)
    m = op.search(html)
    if not m:
        return None, None
    start = m.start(); pos = start; depth = 0
    while pos < len(html):
        om = op.search(html, pos)
        cm = cl.search(html, pos)
        if om and (not cm or om.start() < cm.start()):
            depth += 1; pos = om.end()
        elif cm:
            depth -= 1; pos = cm.end()
            if depth == 0:
                return start, pos
        else:
            break
    return None, None

# ── Replace nav block in one file ──────────────────────────────────────────
def replace_nav(html, fname):
    comment = html.find('<!-- TopNavBar')
    # Decide anchor point
    if comment >= 0:
        search_from = comment
    else:
        # try right after <body ...>
        bm = re.search(r'<body[^>]*>', html, re.I)
        search_from = bm.end() if bm else 0

    chunk = html[search_from:]

    # prefer <header>, fall back to <nav>
    hs, he = find_tag_block(chunk, 'header')
    ns, ne = find_tag_block(chunk, 'nav')

    if hs is not None:
        blk_start = search_from + hs
        blk_end   = search_from + he
    elif ns is not None:
        blk_start = search_from + ns
        blk_end   = search_from + ne
    else:
        print(f'  WARNING: no nav/header found in {fname}')
        return html

    # If there was a comment, start replacement from comment
    rep_start = comment if comment >= 0 and comment < blk_start else blk_start
    return html[:rep_start] + NAV + '\n' + html[blk_end:]

# ── Remove any old mobile-menu script blocks, add fresh NAV_JS ────────────
old_script_pattern = re.compile(
    r'<script>\s*(?:var mb|document\.getElementById\([\'"]mobile-menu)[^\<]*?</script>',
    re.S)

def fix_scripts(html):
    html = old_script_pattern.sub('', html)
    html = html.replace('</body>', NAV_JS + '\n</body>', 1)
    return html

# ── Process every HTML file ───────────────────────────────────────────────
html_files = [f for f in os.listdir(DIR) if f.endswith('.html')]
for fname in html_files:
    path = os.path.join(DIR, fname)
    with open(path, 'r', encoding='utf-8') as f:
        html = f.read()

    # 1. Rebrand name everywhere
    html = html.replace('AgriSutra NE', 'Jurivya NE')

    # 2. Fix pt-20 / pt-[72px] body padding (nav height is ~64px)
    html = re.sub(r'pt-\[72px\]', 'pt-[64px]', html)
    html = re.sub(r'\bpt-20\b', 'pt-[64px]', html)

    # 3. Replace nav block
    html = replace_nav(html, fname)

    # 4. Fix scripts
    html = fix_scripts(html)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(html)
    print(f'  Done: {fname}')

# ── maps.html – wire up "Generate Detailed Report" button ─────────────────
maps_path = os.path.join(DIR, 'maps.html')
with open(maps_path, 'r', encoding='utf-8') as f:
    maps = f.read()

# Replace the existing "Generate Detailed Report" anchor/button
maps = re.sub(
    r'<a[^>]*href=["\'](?:index|report)\.html["\'][^>]*>[\s\S]*?Generate Detailed Report[\s\S]*?</a>',
    '''<a class="mt-8 w-full bg-[#69F0AE] text-[#1B2E1B] py-3 px-4 rounded-lg text-body-md font-medium hover:bg-[#5CE0A0] transition-colors hover:-translate-y-[2px] duration-200 flex justify-center items-center gap-2 cursor-pointer" href="report.html" onclick="sessionStorage.setItem('jurivya_from_map','1')">
  <span class="material-symbols-outlined">summarize</span> Generate Detailed Report
</a>''',
    maps)

with open(maps_path, 'w', encoding='utf-8') as f:
    f.write(maps)
print('  Patched maps.html Generate Detailed Report button')

# ── Copy logo if "jurivya ne_logo.png" exists anywhere nearby ────────────
search_roots = [
    os.path.join(os.path.expanduser('~'), 'Downloads'),
    os.path.join(os.path.expanduser('~'), 'Desktop'),
    r'D:\AgriReeti',
]
logo_dst = os.path.join(DIR, 'logo.png')
found = False
for root in search_roots:
    if not os.path.isdir(root):
        continue
    for dirpath, _, files in os.walk(root):
        for fn in files:
            if 'jurivya' in fn.lower() and fn.lower().endswith('.png'):
                shutil.copy2(os.path.join(dirpath, fn), logo_dst)
                print(f'  Copied logo from {os.path.join(dirpath, fn)}')
                found = True
                break
        if found:
            break
    if found:
        break

if not found:
    print('  Logo "jurivya ne_logo.png" not found in common locations.')
    print('  Please copy it manually to D:\\AgriReeti\\website\\logo.png')

print('\nAll done!')

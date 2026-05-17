import re

with open(r'D:\AgriReeti\stitch_agrisutra_ne_landing_page\juraiva_science_methodology_final\code.html', 'r', encoding='utf-8') as f:
    c = f.read()

c = re.sub(r'{{DATA:SCREEN:[^}]+}}', '#', c)
c = c.replace('Science &amp; Methodology - Juraiva', 'Science &amp; Methodology | AgriSutra NE')
c = c.replace('>Juraiva<', '>AgriSutra NE<')
c = c.replace('2024 Juraiva', '2024 AgriSutra NE')

nav_new = '''<div class="hidden md:flex gap-gutter items-center">
<a class="text-on-surface-variant hover:text-primary font-body-md text-body-md" href="index.html">Home</a>
<a class="text-on-surface-variant hover:text-primary font-body-md text-body-md" href="recommendation.html">Recommendation Tool</a>
<a class="text-primary font-bold border-b-2 border-primary pb-1 font-body-md text-body-md" href="science.html">Science &amp; Methodology</a>
<a class="text-on-surface-variant hover:text-primary font-body-md text-body-md" href="features.html">Features</a>
</div>
<a href="download.html" class="bg-[#69F0AE] text-[#1B2E1B] font-body-md text-body-md px-6 py-2 rounded-full hover:-translate-y-0.5 transition-transform shadow-sm">Download App</a>'''

c = re.sub(r'<div class="hidden md:flex gap-gutter items-center">.*?</button>', nav_new, c, flags=re.DOTALL)

with open(r'D:\AgriReeti\website\science.html', 'w', encoding='utf-8') as f:
    f.write(c)

# --- features.html ---
with open(r'D:\AgriReeti\stitch_agrisutra_ne_landing_page\juraiva_features_final\code.html', 'r', encoding='utf-8') as f:
    c2 = f.read()

c2 = re.sub(r'{{DATA:SCREEN:[^}]+}}', '#', c2)
c2 = c2.replace('>Juraiva<', '>AgriSutra NE<')
c2 = c2.replace('2024 Juraiva', '2024 AgriSutra NE')
c2 = c2.replace('Juraiva - Features', 'Features | AgriSutra NE')
c2 = c2.replace('Juraiva - ', 'AgriSutra NE - ')

nav_feat = '''<div class="hidden md:flex gap-gutter items-center">
<a class="text-on-surface-variant hover:text-primary font-body-md text-body-md" href="index.html">Home</a>
<a class="text-on-surface-variant hover:text-primary font-body-md text-body-md" href="recommendation.html">Recommendation Tool</a>
<a class="text-on-surface-variant hover:text-primary font-body-md text-body-md" href="science.html">Science &amp; Methodology</a>
<a class="text-primary font-bold border-b-2 border-primary pb-1 font-body-md text-body-md" href="features.html">Features</a>
</div>
<a href="download.html" class="bg-[#69F0AE] text-[#1B2E1B] font-body-md text-body-md px-6 py-2 rounded-full hover:-translate-y-0.5 transition-transform shadow-sm">Download App</a>'''

c2 = re.sub(r'<div class="hidden md:flex gap-gutter items-center">.*?</button>', nav_feat, c2, flags=re.DOTALL)

with open(r'D:\AgriReeti\website\features.html', 'w', encoding='utf-8') as f:
    f.write(c2)

print('science.html and features.html created OK')

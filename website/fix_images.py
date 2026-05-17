import re
import os

DIR = r'D:\AgriReeti\website'

# Unsplash placeholder images matching the context
PLACEHOLDERS = [
    'https://images.unsplash.com/photo-1596422846543-75c6fc197f07?auto=format&fit=crop&w=1200&q=80', # Landscape
    'https://images.unsplash.com/photo-1625246333195-78d9c38ad449?auto=format&fit=crop&w=1200&q=80', # Farming
    'https://images.unsplash.com/photo-1589923188900-85dae523342b?auto=format&fit=crop&w=1200&q=80', # Plants/Tea
    'https://images.unsplash.com/photo-1464226184884-fa280b87c399?auto=format&fit=crop&w=1200&q=80', # Crop field
]

html_files = [f for f in os.listdir(DIR) if f.endswith('.html')]

import random

for fname in html_files:
    path = os.path.join(DIR, fname)
    with open(path, 'r', encoding='utf-8') as f:
        html = f.read()

    # Find all googleusercontent image URLs
    pattern = re.compile(r'https://lh3\.googleusercontent\.com/[^\s"\'<>]+')
    matches = pattern.findall(html)
    
    if matches:
        for match in matches:
            ph = random.choice(PLACEHOLDERS)
            html = html.replace(match, ph)
            
        with open(path, 'w', encoding='utf-8') as f:
            f.write(html)
        print(f'Fixed {len(matches)} broken image(s) in {fname}')
    else:
        print(f'No broken images in {fname}')

print('\nDone fixing placeholder images!')

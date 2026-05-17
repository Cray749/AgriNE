import re
files = ['markets.html','advisory.html','analytics.html','maps.html','resources.html','report.html']
for f in files:
    with open(r'D:\AgriReeti\website\\' + f, encoding='utf-8') as fh:
        c = fh.read()
    has_rec = 'recommendation.html' in c[:4000]
    has_mob = 'mobile-menu' in c
    has_brand = 'AgriSutra NE' in c
    stitch_refs = len(re.findall(r'DATA:SCREEN', c))
    print(f + ': brand=' + str(has_brand) + ', rec_link=' + str(has_rec) + ', mobile=' + str(has_mob) + ', stitch_refs=' + str(stitch_refs))

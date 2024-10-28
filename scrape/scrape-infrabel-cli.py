# %%
import cloudscraper
from bs4 import BeautifulSoup
import pandas as pd
import geopandas as gpd

# %%
url = 'https://infrabel.be/fr/contact?page={page}'

# %%
scraper = cloudscraper.create_scraper()

# %%
r = scraper.get(url.format(page=0))
r.status_code

# %%
html_doc = r.text
soup = BeautifulSoup(html_doc)

# %%
# building a set using {} to avoid duplicates
pages = sorted(list({
    int(item['href'].replace('?page=', ''))
    for item in soup.select('.pager.pager__items a.pager__link')
    if item['href'].startswith('?page=')
}))

# %%
def get_lcis(soup):
    """
    Returns list of LCIs from soup
    """
    return [
        {
            'name': item.select_one('h4').get_text().strip(),
            'address': item.select_one('.m-t-2.m-b-1.font-weight-bold').get_text().strip(),
            'lng': float(item.select_one('meta[property="longitude"]')['content']),
            'lat': float(item.select_one('meta[property="latitude"]')['content']),
        }
        for item in soup.select('.teaser-block')
    ]

# %%
lcis = []
for page in pages:
    r = scraper.get(url.format(page=page))
    html_doc = r.text
    soup = BeautifulSoup(html_doc)
    lcis += get_lcis(soup)

# %%
df = pd.DataFrame(lcis)
gdf = gpd.GeoDataFrame(df[[col for col in df.columns if col not in ['lng', 'lat']]], geometry=gpd.points_from_xy(df.lng, df.lat, crs='EPSG:4326'))
gdf

# %%
gdf.to_file("clis.json", driver="GeoJSON")

# %%




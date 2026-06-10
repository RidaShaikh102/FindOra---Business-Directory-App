To import OSM data into the app/Cloud Function, you have two options:

A) Live fetch (recommended for automation)
- The importer calls Overpass API directly.
- You do NOT need to place any export file.

B) Use an exported file (manual/offline)
1) In Overpass Turbo, export as JSON (Raw OSM JSON / JSON).
2) Save the downloaded file into:
   e:/findora/functions/data/
3) Example filenames:
   - osm-sukkur.json
   - osm-sukkur-places.json

Then we can update the importer to read from that local JSON file instead of calling Overpass.


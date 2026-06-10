import * as admin from 'firebase-admin';

admin.initializeApp();

type OverpassElement = {
  type: 'node' | 'way' | 'relation';
  id: number;
  lat?: number;
  lon?: number;
  tags?: Record<string, string>;
};

type OSMPlace = {
  osmType: 'node' | 'way' | 'relation';
  osmId: string; // "node/123" style
  name: string;
  category: string;
  subcategory: string;
  latitude: number;
  longitude: number;
  address: string;
  website?: string;
  phone?: string;
  liveLocation: string;
  timing?: string;
  description?: string;
};

const MAP = {
  cityName: 'Sukkur',
  // This is your app’s structure used in AddBusinessScreen
  // (see lib/screens/add_business_screen.dart)
  appCategories: [
    'Restaurants',
    'Shopping',
    'Health & Beauty',
    'Education',
    'Services',
    'Entertainment',
    'Online',
    'Others',
  ],
} as const;

function escapeOverpassString(s: string): string {
  // Minimal escaping for quoted string values in Overpass QL
  return s.split('"').join('\\"');
}

function asStr(v: unknown): string {
  if (v === null || v === undefined) return '';
  return String(v);
}

function getTag(tags: Record<string, string> | undefined, key: string): string {
  if (!tags) return '';
  return tags[key] ?? '';
}

function buildLiveLocation(lat: number, lon: number): string {
  return `https://www.google.com/maps?q=${lat},${lon}`;
}

function cleanAddress(addrParts: string[]): string {
  const filtered = addrParts
    .map((p) => p.trim())
    .filter((p) => p.length > 0);
  // Avoid super long strings but keep meaningful order
  const joined = filtered.join(', ');
  return joined.length > 500 ? joined.slice(0, 500) : joined;
}

function normalizeCategoryForApp(category: string, subcategory: string): {
  category: string;
  subcategory: string;
} {
  // Ensure category is one of app categories; fallback to Others.
  const valid = new Set<string>(MAP.appCategories as unknown as string[]);
  if (!valid.has(category)) return { category: 'Others', subcategory: 'Other' };

  // If subcategory is empty, make it safe.
  const sub = subcategory.trim().length > 0 ? subcategory : 'Other';
  return { category, subcategory: sub };
}

function mapPlaceToAppCategory(tags: Record<string, string> | undefined): {
  category: string;
  subcategory: string;
} {
  const amenity = getTag(tags, 'amenity').toLowerCase();
  const shop = getTag(tags, 'shop').toLowerCase();
  const tourism = getTag(tags, 'tourism').toLowerCase();
  const leisure = getTag(tags, 'leisure').toLowerCase();
  const craft = getTag(tags, 'craft').toLowerCase();

  // Restaurants
  if (['restaurant', 'cafe', 'fast_food', 'food_court'].includes(amenity)) {
    if (amenity === 'cafe') return { category: 'Restaurants', subcategory: 'Cafes' };
    if (amenity === 'fast_food') return { category: 'Restaurants', subcategory: 'Carts' };
    return { category: 'Restaurants', subcategory: 'Restaurants' };
  }

  // Bakeries
  if (shop === 'bakery') {
    return { category: 'Restaurants', subcategory: 'Bakeries' };
  }

  // Hotels
  if (amenity === 'hotel' || tourism === 'hotel') {
    return { category: 'Restaurants', subcategory: 'Hotels' };
  }

  // Shopping
  if (shop) {
    const shopToSub: Record<string, string> = {
      clothes: 'Clothing',
      clothing: 'Clothing',
      shoes: 'Clothing',
      electronics: 'Electronics',
      computer: 'Electronics',
      grocery: 'Grocery',
      supermarket: 'Grocery',
      bakery: 'Bakeries',
      gift: 'Gifts',
      'gift_shop': 'Gifts',
    };
    if (shopToSub[shop]) {
      const sub = shopToSub[shop];
      // keep bakeries in restaurant bucket
      if (sub === 'Bakeries') return { category: 'Restaurants', subcategory: 'Bakeries' };
      return { category: 'Shopping', subcategory: sub };
    }

    // Broad fallback into Shopping
    if (['department_store', 'variety_store', 'supermarket', 'convenience'].includes(shop)) {
      return { category: 'Shopping', subcategory: 'Grocery' };
    }

    // Default Shopping fallback
    return { category: 'Shopping', subcategory: 'Other' };
  }

  // Health & Beauty
  if (['clinic', 'hospital', 'dentist', 'doctors', 'doctors', 'pharmacy', 'dentistry'].includes(amenity) || amenity === 'pharmacy') {
    if (amenity === 'pharmacy') return { category: 'Health & Beauty', subcategory: 'Pharmacies' };
    if (amenity === 'clinic' || amenity === 'hospital') return { category: 'Health & Beauty', subcategory: 'Clinics' };
    if (amenity === 'dentist') return { category: 'Health & Beauty', subcategory: 'Clinics' };
    return { category: 'Health & Beauty', subcategory: 'Clinics' };
  }

  // Salons/Spas (often represented as shop/craft/amenity)
  if (shop === 'hairdresser' || craft === 'beauty' || craft === 'hairdresser' || amenity === 'barber_shop' || amenity === 'beauty_salon') {
    if (amenity === 'barber_shop') return { category: 'Health & Beauty', subcategory: 'Salons' };
    if (amenity === 'beauty_salon') return { category: 'Health & Beauty', subcategory: 'Salons' };
    if (craft.includes('spa') || shop.includes('spa')) return { category: 'Health & Beauty', subcategory: 'Spas' };
    return { category: 'Health & Beauty', subcategory: 'Salons' };
  }

  // Education
  if (['school', 'university', 'college'].includes(amenity) || amenity === 'library') {
    if (amenity === 'school') return { category: 'Education', subcategory: 'Schools' };
    if (amenity === 'college' || amenity === 'university') return { category: 'Education', subcategory: 'Colleges' };
    if (amenity === 'library') return { category: 'Education', subcategory: 'Libraries' };
    return { category: 'Education', subcategory: 'Schools' };
  }

  // Coaching centers (often "amenity=school" with additional tags; we keep simple)
  if (shop === 'tutoring' || amenity === 'training' || amenity === 'college') {
    return { category: 'Education', subcategory: 'Coaching Centers' };
  }

  // Entertainment
  if (amenity === 'cinema' || tourism === 'cinema') {
    return { category: 'Entertainment', subcategory: 'Cinemas' };
  }
  if (amenity === 'theatre' || amenity === 'theater') {
    return { category: 'Entertainment', subcategory: 'Events' };
  }
  if (leisure === 'park') {
    return { category: 'Entertainment', subcategory: 'Parks' };
  }

  // Services (generic fallback)
  if (amenity || craft || shop) {
    // Try common service-like amenities
    const amenityToSub: Record<string, string> = {
      'car_repair': 'Repair',
      'bicycle_repair_station': 'Repair',
      'laundry': 'Laundry',
      'photo': 'Photography',
      'photography': 'Photography',
      'delivery': 'Delivery',
    };

    if (amenity in amenityToSub) {
      return { category: 'Services', subcategory: amenityToSub[amenity] };
    }

    // craft/shop fallback
    if (craft.includes('repair') || shop.includes('repair')) return { category: 'Services', subcategory: 'Repair' };
    if (shop.includes('laundry') || amenity === 'laundry') return { category: 'Services', subcategory: 'Laundry' };
    if (shop.includes('photography') || craft.includes('photography') || amenity === 'photo') return { category: 'Services', subcategory: 'Photography' };
    return { category: 'Services', subcategory: 'Other' };
  }

  return { category: 'Others', subcategory: 'Other' };
}

function elementToOSMPlace(el: OverpassElement): OSMPlace | null {
  if (typeof el.lat !== 'number' || typeof el.lon !== 'number') return null;
  const tags = el.tags;
  const name = (getTag(tags, 'name') || '').trim();
  if (!name) return null;

  const latitude = el.lat;
  const longitude = el.lon;
  const { category, subcategory } = mapPlaceToAppCategory(tags);

  const addressParts: string[] = [];
  const housenumber = getTag(tags, 'addr:housenumber');
  const street = getTag(tags, 'addr:street');
  const subLocality = getTag(tags, 'addr:suburb');
  const locality = getTag(tags, 'addr:city');
  const postcode = getTag(tags, 'addr:postcode');
  const country = getTag(tags, 'addr:country');

  if (housenumber) addressParts.push(housenumber);
  if (street) addressParts.push(street);
  if (subLocality) addressParts.push(subLocality);
  if (locality) addressParts.push(locality);
  if (postcode) addressParts.push(postcode);
  if (country) addressParts.push(country);

  // Also accept general address: if present
  const addrFull = getTag(tags, 'addr:full');
  const address = cleanAddress(addrFull ? [addrFull] : addressParts);

  const website = getTag(tags, 'website');
  const phone = getTag(tags, 'phone') || getTag(tags, 'contact:phone');

  const osmId = `${el.type}/${el.id}`;

  const timing = getTag(tags, 'opening_hours');
  const description = getTag(tags, 'description');

  const liveLocation = buildLiveLocation(latitude, longitude);

  const cat = normalizeCategoryForApp(category, subcategory);

  return {
    osmType: el.type,
    osmId,
    name,
    category: cat.category,
    subcategory: cat.subcategory,
    latitude,
    longitude,
    address,
    website: website || undefined,
    phone: phone || undefined,
    liveLocation,
    timing: timing || undefined,
    description: description || undefined,
  };
}

async function overpassQuery(query: string): Promise<OverpassElement[]> {
  const url = 'https://overpass-api.de/api/interpreter';
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: `data=${encodeURIComponent(query)}`,
  });

  if (!res.ok) {
    throw new Error(`Overpass request failed: ${res.status} ${res.statusText}`);
  }

  const json = (await res.json()) as any;
  const elements: any[] = Array.isArray(json?.elements) ? json.elements : [];

  return elements
    .map((el) => {
      const type = el?.type;
      const id = Number(el?.id);
      const lat = typeof el?.lat === 'number' ? el.lat : undefined;
      const lon = typeof el?.lon === 'number' ? el.lon : undefined;
      const tags = typeof el?.tags === 'object' ? el.tags : undefined;
      if (
        (type !== 'node' && type !== 'way' && type !== 'relation') ||
        !Number.isFinite(id)
      ) {
        return null;
      }
      return {
        type,
        id,
        lat,
        lon,
        tags,
      } as OverpassElement;
    })
    .filter((x): x is OverpassElement => x !== null);
}

function buildSukkurAreaStatement(areaName: string): string {
  // Overpass: get administrative boundary by name (fallback if relation not found)
  // Note: This is best-effort; if you need stricter boundary, we can switch to explicit OSM relation id.
  return `(
    area["name"="${escapeOverpassString(areaName)}"]["boundary"="administrative"]["admin_level"]["type"="boundary"]; 
  );`;
}

function buildOverpassQueryForSukkur(): string {
  // We use around(2000) as a safety net in case area lookup by name fails.
  // Center is Sukkur approximation; can be refined later.
  const centerLat = 27.7017;
  const centerLon = 68.8599;
  const radiusMeters = 5000;

  // Common business tags in your app categories
  const query = `[
    out:json;
    timeout:120;
  ];
  (
    // Restaurants/cafes/fast food
    node(around:${radiusMeters},${centerLat},${centerLon})["amenity"~"^(restaurant|cafe|fast_food|food_court)$"];
    // Bakeries
    node(around:${radiusMeters},${centerLat},${centerLon})["shop"="bakery"];
    // Hotels
    node(around:${radiusMeters},${centerLat},${centerLon})["tourism"="hotel"];
    node(around:${radiusMeters},${centerLat},${centerLon})["amenity"="hotel"];

    // Shopping (broad)
    node(around:${radiusMeters},${centerLat},${centerLon})["shop"];

    // Health & Beauty
    node(around:${radiusMeters},${centerLat},${centerLon})["amenity"~"^(clinic|hospital|dentist|pharmacy)$"];
    node(around:${radiusMeters},${centerLat},${centerLon})["craft"~"^(beauty|hairdresser|spa)$"];
    node(around:${radiusMeters},${centerLat},${centerLon})["shop"~"^(hairdresser|spa)$"];

    // Education
    node(around:${radiusMeters},${centerLat},${centerLon})["amenity"~"^(school|college|university)$"];
    node(around:${radiusMeters},${centerLat},${centerLon})["amenity"="library"];
    node(around:${radiusMeters},${centerLat},${centerLon})["shop"="tutoring"];

    // Entertainment
    node(around:${radiusMeters},${centerLat},${centerLon})["amenity"~"^(cinema|theatre)$"];
    node(around:${radiusMeters},${centerLat},${centerLon})["leisure"="park"];
  );
  out center tags;`;

  return query;
}

async function getImportRunState(docId: string): Promise<any> {
  return admin.firestore().collection('imports').doc(docId).get();
}

function buildBusinessDoc(place: OSMPlace): Record<string, any> {
  return {
    // id will be set based on osmId
    osmId: place.osmId,
    image: '',
    name: place.name,
    address: place.address,
    contact: place.phone ?? '',
    whatsapp: place.phone ?? '',
    website: place.website ?? '',
    liveLocation: place.liveLocation,
    subcategory: place.subcategory,
    timing: place.timing ?? '',
    description: place.description ?? '',
    category: place.category,
    ownerEmail: '',
    instagram: '',
    facebook: '',
    latitude: place.latitude,
    longitude: place.longitude,
    status: 'pending',
    createdAt: Date.now(),
    updatedAt: Date.now(),
  };
}

export async function importOsmSukkurBusinesses(opts?: {
  force?: boolean;
}): Promise<{ inserted: number; skipped: number; total: number; }>{
  const force = opts?.force ?? false;
  const importDocId = 'osm_sukkur_v1';

  const importDocRef = admin.firestore().collection('imports').doc(importDocId);
  const importSnap = await importDocRef.get();
  if (!force && importSnap.exists) {
    const lastRunAt = importSnap.data()?.lastRunAt ?? 0;
    if (typeof lastRunAt === 'number' && lastRunAt > 0) {
      return { inserted: 0, skipped: 0, total: 0 };
    }
  }

  const query = buildOverpassQueryForSukkur();
  const elements = await overpassQuery(query);

  const places: OSMPlace[] = [];
  for (const el of elements) {
    const place = elementToOSMPlace(el);
    if (place) places.push(place);
  }

  // Deduplicate by osmId
  const uniqueByOsmId = new Map<string, OSMPlace>();
  for (const p of places) {
    uniqueByOsmId.set(p.osmId, p);
  }

  const placesUnique = Array.from(uniqueByOsmId.values());

  let inserted = 0;
  let skipped = 0;

  // Ensure max writes per batch (Firestore limit 500)
  const businessesRef = admin.firestore().collection('businesses');

  const batchSize = 450;
  for (let i = 0; i < placesUnique.length; i += batchSize) {
    const chunk = placesUnique.slice(i, i + batchSize);
    const batch = admin.firestore().batch();

    // Check existing by osmId
    // We don’t have an index for osmId yet, but we can check doc by deterministic id.
    for (const place of chunk) {
      // Firestore document IDs must not include path separators.
      // `osmId` can be like `node/0`, so sanitize to keep it a single segment.
      const deterministicId = `osm_${place.osmId.split('/').join('_')}`;

      const docRef = businessesRef.doc(deterministicId);

      const snapshot = await docRef.get();
      if (snapshot.exists) {
        skipped++;
        // Update sparse fields (idempotent update)
        batch.set(docRef, buildBusinessDoc(place), { merge: true });
      } else {
        inserted++;
        batch.set(docRef, buildBusinessDoc(place));
      }
    }

    await batch.commit();
  }

  await importDocRef.set(
    {
      lastRunAt: Date.now(),
      count: placesUnique.length,
      updatedAt: Date.now(),
      forced: force,
    },
    { merge: true },
  );

  return { inserted, skipped, total: placesUnique.length };
}



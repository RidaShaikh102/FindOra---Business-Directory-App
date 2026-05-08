/// Local marketplace hub for FindOra (phase 1: Sukkur-only sellers).
const String kMarketplaceLocalCity = 'Sukkur';

/// Default COD commission rate (10%). Applied when order status becomes `delivered`.
const double kDefaultCommissionRate = 0.10;

/// Delivery fee policy (phase 1). Stored on each order at checkout time.
const double kLocalDeliveryFee = 0.0;
const double kCourierDeliveryFee = 0.0;

String normalizeMarketplaceCity(String? raw) {
  if (raw == null) return '';
  return raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

bool citiesMatchForLocalDelivery(String? a, String? b) {
  final na = normalizeMarketplaceCity(a);
  final nb = normalizeMarketplaceCity(b);
  if (na.isEmpty || nb.isEmpty) return false;
  return na == nb;
}

bool isInLocalHub(String? city) {
  return normalizeMarketplaceCity(city) ==
      normalizeMarketplaceCity(kMarketplaceLocalCity);
}

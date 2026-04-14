class PhoneFormatter {
  static String clean(String phone) {
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  static String whatsappUrl(String phone) {
    final cleaned = clean(phone);
    return 'https://wa.me/$cleaned';
  }

  static String telUrl(String phone) {
    return 'tel:${clean(phone)}';
  }
}

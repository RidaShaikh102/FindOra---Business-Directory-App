import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();
  StreamSubscription? _sub;
  Function(Uri)? _onLinkReceived;

  void init(Function(Uri) onLinkReceived) {
    _onLinkReceived = onLinkReceived;

    if (kIsWeb) {
      // On web, app_links stream support is unavailable.
      // Use the current browser URL for initial routing.
      _handleDeepLink(Uri.base);
      return;
    }

    // Handle initial link when app is launched from deep link
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });

    // Handle deep links when app is already running
    _sub = _appLinks.uriLinkStream.listen((Uri uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    if (_onLinkReceived != null) {
      _onLinkReceived!(uri);
    }
  }

  void dispose() {
    _sub?.cancel();
  }

  // Generate deep link URLs for business pages
  static String generateBusinessDeepLink(String businessId) {
    return 'findora://business?id=$businessId';
  }

  static String generateBusinessWebLink(String businessId) {
    return 'https://findora.app/business/$businessId';
  }

  // Create a shareable link (prefer web link for better compatibility)
  static String generateShareableBusinessLink(String businessId) {
    return generateBusinessWebLink(businessId);
  }
}

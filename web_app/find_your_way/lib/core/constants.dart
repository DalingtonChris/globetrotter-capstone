import 'package:flutter/foundation.dart';

/// Base URL for the Find Your Way Phase 1 monolith API.
///
/// Local dev (Flutter web/desktop, Android emulator) talks to the Node
/// server on localhost with no extra setup. Production builds override
/// both values at compile time so the same code points at the real
/// domain, e.g.:
///
///   flutter build web --release \
///     --dart-define=API_BASE_URL=https://find-your-ways.duckdns.org/api \
///     --dart-define=ASSET_BASE_URL=https://find-your-ways.duckdns.org
const String _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');
const String _assetBaseUrlOverride = String.fromEnvironment('ASSET_BASE_URL');

String get apiBaseUrl {
  if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
  if (kIsWeb) return 'http://localhost:8999/api';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8999/api';
  }
  return 'http://localhost:8999/api';
}

String get assetBaseUrl {
  if (_assetBaseUrlOverride.isNotEmpty) return _assetBaseUrlOverride;
  if (kIsWeb) return 'http://localhost:8999';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8999';
  }
  return 'http://localhost:8999';
}

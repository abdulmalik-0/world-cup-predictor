import 'package:flutter/foundation.dart';

/// Redirect URL used for Supabase magic links (must match Supabase Dashboard).
String get authRedirectUrl {
  if (kIsWeb) {
    return Uri.base.origin;
  }
  return 'io.worldcuppredictor.app://login-callback';
}

bool get isAuthCallbackUrl {
  if (!kIsWeb) return false;
  final uri = Uri.base;
  return uri.queryParameters.containsKey('code') ||
      uri.fragment.contains('access_token') ||
      uri.queryParameters.containsKey('token_hash');
}

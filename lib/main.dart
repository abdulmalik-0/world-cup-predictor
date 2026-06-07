import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:world_cup_predictor/app.dart';
import 'package:world_cup_predictor/core/config/auth_redirect.dart';
import 'package:world_cup_predictor/core/config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // Give Supabase a moment to exchange the PKCE code from the email link.
  if (isAuthCallbackUrl) {
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  runApp(
    const ProviderScope(
      child: WorldCupPredictorApp(),
    ),
  );
}

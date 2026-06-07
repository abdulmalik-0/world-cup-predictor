import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:world_cup_predictor/app.dart';
import 'package:world_cup_predictor/core/config/auth_redirect.dart';
import 'package:world_cup_predictor/core/config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!SupabaseConfig.isConfigured) {
    runApp(const _MissingConfigApp());
    return;
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  if (isAuthCallbackUrl) {
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  runApp(
    const ProviderScope(
      child: WorldCupPredictorApp(),
    ),
  );
}

class _MissingConfigApp extends StatelessWidget {
  const _MissingConfigApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.settings_outlined, size: 64, color: Colors.orange),
                    SizedBox(height: 16),
                    Text(
                      'إعدادات Supabase ناقصة',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    Text(
                      '1. انسخ env.example.json إلى env.json\n'
                      '2. ضع SUPABASE_URL و SUPABASE_ANON_KEY\n'
                      '3. شغّل:\n'
                      'flutter run -d chrome --dart-define-from-file=env.json',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

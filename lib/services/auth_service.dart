import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:world_cup_predictor/core/config/auth_redirect.dart';
import 'package:world_cup_predictor/models/profile.dart';

class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sends a 6-digit OTP to the email. No redirect URL — works without Supabase Redirect URLs setup.
  Future<void> sendEmailOtp(String email) async {
    await _client.auth.signInWithOtp(
      email: email.trim(),
      shouldCreateUser: true,
    );
  }

  /// Optional: magic link with redirect (requires Redirect URLs in Supabase Dashboard).
  Future<void> sendMagicLink(String email) async {
    await _client.auth.signInWithOtp(
      email: email.trim(),
      shouldCreateUser: true,
      emailRedirectTo: kIsWeb ? authRedirectUrl : authRedirectUrl,
    );
  }

  Future<void> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    await _client.auth.verifyOTP(
      type: OtpType.email,
      email: email.trim(),
      token: token.trim(),
    );
  }

  bool profileNeedsSetup(Profile? profile) {
    if (profile == null) return true;
    return profile.fullName == 'موظف جديد' || profile.department == 'غير محدد';
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<Profile?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) return null;
    return Profile.fromJson(data);
  }

  Future<Profile> upsertProfile({
    required String fullName,
    required String department,
    String? avatarUrl,
  }) async {
    final user = currentUser!;
    final payload = {
      'id': user.id,
      'full_name': fullName.trim(),
      'department': department.trim(),
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };

    final data = await _client
        .from('profiles')
        .upsert(payload)
        .select()
        .single();

    return Profile.fromJson(data);
  }
}

String authErrorMessage(AuthException e) {
  final message = e.message.toLowerCase();

  if (e.statusCode == '429' || message.contains('rate') || message.contains('too many')) {
    return 'تم إرسال طلبات كثيرة. انتظر 5–10 دقائق ثم حاول مرة أخرى.';
  }

  if (message.contains('redirect') || message.contains('url')) {
    return 'رابط التوجيه غير مسموح في Supabase.\n'
        'أضف http://localhost:8080 في Redirect URLs.';
  }

  if (message.contains('invalid') && message.contains('api')) {
    return 'مفتاح Supabase غير صحيح.\n'
        'استخدم anon public key (JWT) من Settings → API.';
  }

  if (message.contains('otp') && message.contains('expired')) {
    return 'انتهت صلاحية الرمز. أرسل رمزاً جديداً.';
  }

  if (message.contains('otp') || message.contains('token')) {
    return 'الرمز غير صحيح. تحقق من الأرقام الستة في بريدك.';
  }

  if (message.contains('email') && message.contains('invalid')) {
    return 'البريد الإلكتروني غير صالح.';
  }

  if (message.contains('signup') && message.contains('disabled')) {
    return 'التسجيل مغلق حالياً. تواصل مع الإدارة.';
  }

  return e.message;
}

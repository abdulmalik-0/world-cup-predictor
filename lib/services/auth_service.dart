import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:world_cup_predictor/models/profile.dart';

class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signUpWithPassword({
    required String email,
    required String password,
    required String fullName,
    required String department,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        'department': department.trim(),
      },
    );

    if (response.user != null) {
      await upsertProfile(fullName: fullName, department: department);
    }
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

  if (message.contains('invalid login credentials') ||
      message.contains('invalid credentials')) {
    return 'البريد أو كلمة المرور غير صحيحة.';
  }

  if (message.contains('user already registered') ||
      message.contains('already been registered')) {
    return 'هذا البريد مسجّل مسبقاً. سجّل الدخول بدلاً من إنشاء حساب.';
  }

  if (message.contains('password') && message.contains('weak')) {
    return 'كلمة المرور ضعيفة. استخدم 6 أحرف على الأقل.';
  }

  if (message.contains('email') && message.contains('invalid')) {
    return 'البريد الإلكتروني غير صالح.';
  }

  if (message.contains('signup') && message.contains('disabled')) {
    return 'التسجيل مغلق حالياً. تواصل مع الإدارة.';
  }

  return e.message;
}

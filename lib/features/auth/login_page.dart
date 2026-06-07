import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:world_cup_predictor/providers/app_providers.dart';
import 'package:world_cup_predictor/services/auth_service.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _nameController = TextEditingController();
  final _departmentController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;
  bool _isRegister = true;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _departmentController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    final name = _nameController.text.trim();
    final department = _departmentController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'يرجى إدخال بريد إلكتروني صالح');
      return;
    }

    if (password.length < 6) {
      setState(() => _error = 'كلمة المرور 6 أحرف على الأقل');
      return;
    }

    if (_isRegister) {
      if (name.length < 2) {
        setState(() => _error = 'يرجى إدخال الاسم الكامل');
        return;
      }
      if (department.isEmpty) {
        setState(() => _error = 'يرجى إدخال القسم');
        return;
      }
      if (password != confirm) {
        setState(() => _error = 'كلمتا المرور غير متطابقتين');
        return;
      }
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      if (_isRegister) {
        await auth.signUpWithPassword(
          email: email,
          password: password,
          fullName: name,
          department: department,
        );
      } else {
        await auth.signInWithPassword(email: email, password: password);
      }
      ref.invalidate(currentProfileProvider);
    } on AuthException catch (e) {
      setState(() => _error = authErrorMessage(e));
    } catch (e) {
      setState(() => _error = 'تعذّر ${_isRegister ? 'إنشاء الحساب' : 'تسجيل الدخول'}.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.sports_soccer,
                      size: 72,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'تحدي مونديال الشركة',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isRegister
                          ? 'أنشئ حسابك من البداية'
                          : 'سجّل دخولك بالإيميل وكلمة المرور',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 32),
                    if (_isRegister) ...[
                      TextField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'الاسم الكامل',
                          hintText: 'مثال: أحمد محمد',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _departmentController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'القسم',
                          hintText: 'مثال: تقنية المعلومات',
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction:
                          _isRegister ? TextInputAction.next : TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        hintText: '6 أحرف على الأقل',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      onSubmitted: (_) => _isRegister ? null : _submit(),
                    ),
                    if (_isRegister) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'تأكيد كلمة المرور',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isRegister ? 'إنشاء حساب وابدأ' : 'تسجيل الدخول'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => setState(() {
                                _isRegister = !_isRegister;
                                _error = null;
                                _confirmPasswordController.clear();
                              }),
                      child: Text(
                        _isRegister
                            ? 'عندك حساب؟ سجّل الدخول'
                            : 'أول مرة؟ أنشئ حساب',
                      ),
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

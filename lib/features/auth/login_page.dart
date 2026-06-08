import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:world_cup_predictor/core/i18n/app_strings.dart';
import 'package:world_cup_predictor/core/widgets/auth_brand_header.dart';
import 'package:world_cup_predictor/core/widgets/grab_scroll.dart';
import 'package:world_cup_predictor/core/widgets/language_switcher.dart';
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

    final s = S.of(context);
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = s.errEmail);
      return;
    }

    if (password.length < 6) {
      setState(() => _error = s.errPassword);
      return;
    }

    if (_isRegister) {
      if (name.length < 2) {
        setState(() => _error = s.errName);
        return;
      }
      if (department.isEmpty) {
        setState(() => _error = s.errDept);
        return;
      }
      if (password != confirm) {
        setState(() => _error = s.errPasswordMatch);
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
      setState(() => _error = _isRegister ? s.errRegister : s.errSignIn);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Directionality(
      textDirection: s.ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: Center(
                child: GrabScrollSingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthBrandHeader(
                      subtitle:
                          _isRegister ? s.registerSubtitle : s.loginSubtitle,
                    ),
                    const SizedBox(height: 32),
                    if (_isRegister) ...[
                      TextField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: s.fullName,
                          hintText: s.fullNameHint,
                          prefixIcon: const Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _departmentController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: s.department,
                          hintText: s.departmentHint,
                          prefixIcon: const Icon(Icons.business_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: s.email,
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction:
                          _isRegister ? TextInputAction.next : TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: s.password,
                        hintText: s.passwordHint,
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
                        decoration: InputDecoration(
                          labelText: s.confirmPassword,
                          prefixIcon: const Icon(Icons.lock_outline),
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
                          : Text(_isRegister ? s.createAndStart : s.signIn),
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
                        _isRegister ? s.haveAccount : s.firstTime,
                      ),
                    ),
                  ],
                    ),
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 8,
              left: 12,
              child: SafeArea(child: LanguageSwitcherChip()),
            ),
          ],
        ),
      ),
    );
  }
}

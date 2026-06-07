import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:world_cup_predictor/providers/app_providers.dart';

class ProfileSetupPage extends ConsumerStatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  final _nameController = TextEditingController();
  final _departmentController = TextEditingController();
  bool _loading = false;
  bool _initialized = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  void _prefillFromProfile() {
    if (_initialized) return;
    final profile = ref.read(currentProfileProvider).valueOrNull;
    if (profile != null) {
      if (profile.fullName != 'موظف جديد') {
        _nameController.text = profile.fullName;
      }
      if (profile.department != 'غير محدد') {
        _departmentController.text = profile.department;
      }
    }
    _initialized = true;
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final dept = _departmentController.text.trim();

    if (name.length < 2) {
      setState(() => _error = 'يرجى إدخال الاسم الكامل');
      return;
    }
    if (dept.isEmpty) {
      setState(() => _error = 'يرجى إدخال القسم');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authServiceProvider).upsertProfile(
            fullName: name,
            department: dept,
          );
      ref.invalidate(currentProfileProvider);
      if (mounted) context.go('/dashboard');
    } catch (e) {
      setState(() => _error = 'تعذّر حفظ الملف الشخصي. حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _prefillFromProfile();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('أكمل ملفك الشخصي'),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'خطوة أخيرة قبل البدء!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'هذه المعلومات تظهر في جدول الترتيب وتوقعات الزملاء.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 32),
                    CircleAvatar(
                      radius: 48,
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 32),
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
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'القسم',
                        hintText: 'مثال: تقنية المعلومات',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                      onSubmitted: (_) => _save(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style:
                            TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _save,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('ابدأ التوقعات'),
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

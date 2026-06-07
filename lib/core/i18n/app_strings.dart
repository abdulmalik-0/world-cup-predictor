import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the active locale; the language button toggles it.
class LocaleController extends Notifier<Locale> {
  @override
  Locale build() => const Locale('ar');

  void toggle() =>
      state = state.languageCode == 'ar' ? const Locale('en') : const Locale('ar');
}

final localeProvider =
    NotifierProvider<LocaleController, Locale>(LocaleController.new);

/// Localized strings, resolved from the current locale.
class S {
  const S(this.ar);

  final bool ar;

  static S of(BuildContext context) =>
      S(Localizations.localeOf(context).languageCode == 'ar');

  String _p(String arText, String enText) => ar ? arText : enText;

  // ── Shell / general ─────────────────────────────────────────
  String get appName => _p('تحدي مونديال الشركة', 'Company World Cup');
  String get matches => _p('المباريات', 'Matches');
  String get standings => _p('الترتيب', 'Standings');
  String get myStats => _p('إحصائياتي', 'My Stats');
  String get adminPanel => _p('لوحة التحكم', 'Admin Panel');
  String get signOut => _p('تسجيل الخروج', 'Sign out');
  // The button shows the language you'll switch TO.
  String get switchLanguageLabel => _p('English', 'عربي');

  // ── Dashboard ───────────────────────────────────────────────
  String get upcomingMatches => _p('المباريات القادمة', 'Upcoming Matches');
  String get predictionHint => _p(
        'يُغلق التوقع قبل صافرة البداية بـ 15 دقيقة • مباريات العرب = نقاط مضاعفة 🔥',
        'Predictions lock 15 min before kickoff • Arab teams = double points 🔥',
      );
  String get noMatches => _p('لا توجد مباريات قادمة حالياً', 'No upcoming matches');
  String matchesCount(int n) => ar
      ? '$n ${n == 1 ? 'مباراة' : (n == 2 ? 'مباراتان' : 'مباريات')}'
      : '$n ${n == 1 ? 'match' : 'matches'}';

  // ── Match card ──────────────────────────────────────────────
  String get closed => _p('مغلق', 'Closed');
  String get dayUnit => _p('يوم', 'd');
  String get saveNew => _p('حفظ التوقع', 'Save pick');
  String get saveEdit => _p('حفظ التعديل', 'Save change');
  String get saved => _p('محفوظ ✓', 'Saved ✓');
  String get justSaved => _p('تم الحفظ ✓', 'Saved ✓');
  String get statusJustSaved => _p('تم حفظ توقعك', 'Your pick was saved');
  String get statusUnsaved =>
      _p('تعديل غير محفوظ — اضغط حفظ', 'Unsaved change — tap save');
  String get statusSaved => _p('توقعك محفوظ', 'Your pick is saved');
  String get result => _p('النتيجة', 'Result');
  String get yourPick => _p('توقعك', 'Your pick');
  String get notPredicted =>
      _p('لم تتوقع هذه المباراة', "You didn't predict this match");
  String points(int n) => _p('+$n نقطة', '+$n pts');
  String get doubleBadge => _p('دبل 🔥', 'Double 🔥');
  String get errWindow =>
      _p('انتهى وقت التوقع لهذه المباراة', 'Prediction window has closed');
  String get errRls => _p(
        'فشل الحفظ بسبب صلاحيات قاعدة البيانات (شغّل migration 004)',
        'Save failed: database permissions (run migration 004)',
      );
  String get errGeneric =>
      _p('تعذّر حفظ التوقع، حاول مجدداً', 'Could not save, please try again');

  // ── Leaderboard ─────────────────────────────────────────────
  String get liveStandings =>
      _p('الترتيب اللحظي — يتحدّث تلقائياً', 'Live standings — auto-updating');
  String get noParticipants => _p('لا يوجد مشاركون بعد', 'No participants yet');
  String get pts => _p('نقطة', 'pts');
  String predictionsMadeCount(int n) => ar ? '$n توقع' : '$n picks';

  // ── Stats ───────────────────────────────────────────────────
  String get totalPoints => _p('مجموع النقاط', 'Total points');
  String get predictionsCount => _p('عدد التوقعات', 'Predictions');
  String get accuracy => _p('دقة النتيجة', 'Accuracy');
  String get correctPredictions => _p('توقعات صحيحة', 'Exact picks');
  String get pointsProgress => _p('تطوّر نقاطك', 'Points progress');
  String get myHistory => _p('سجل توقعاتي', 'My history');
  String get noFinished =>
      _p('لا توجد مباريات منتهية بعد', 'No finished matches yet');
  String get exactBadge => _p('إصابة دقيقة', 'Exact');
  String get correctBadge => _p('نتيجة صحيحة', 'Correct');
  String get wrongBadge => _p('خطأ', 'Wrong');

  // ── Login ───────────────────────────────────────────────────
  String get registerSubtitle => _p('أنشئ حسابك من البداية', 'Create your account');
  String get loginSubtitle =>
      _p('سجّل دخولك بالإيميل وكلمة المرور', 'Sign in with email & password');
  String get fullName => _p('الاسم الكامل', 'Full name');
  String get fullNameHint => _p('مثال: أحمد محمد', 'e.g. John Smith');
  String get department => _p('القسم', 'Department');
  String get departmentHint => _p('مثال: تقنية المعلومات', 'e.g. IT');
  String get email => _p('البريد الإلكتروني', 'Email');
  String get password => _p('كلمة المرور', 'Password');
  String get passwordHint => _p('6 أحرف على الأقل', 'At least 6 characters');
  String get confirmPassword => _p('تأكيد كلمة المرور', 'Confirm password');
  String get createAndStart => _p('إنشاء حساب وابدأ', 'Create account & start');
  String get signIn => _p('تسجيل الدخول', 'Sign in');
  String get haveAccount =>
      _p('عندك حساب؟ سجّل الدخول', 'Have an account? Sign in');
  String get firstTime => _p('أول مرة؟ أنشئ حساب', 'First time? Create an account');
  String get errEmail => _p('يرجى إدخال بريد إلكتروني صالح', 'Enter a valid email');
  String get errPassword =>
      _p('كلمة المرور 6 أحرف على الأقل', 'Password must be 6+ characters');
  String get errName => _p('يرجى إدخال الاسم الكامل', 'Enter your full name');
  String get errDept => _p('يرجى إدخال القسم', 'Enter your department');
  String get errPasswordMatch =>
      _p('كلمتا المرور غير متطابقتين', 'Passwords do not match');
  String get errRegister => _p('تعذّر إنشاء الحساب.', 'Could not create account.');
  String get errSignIn => _p('تعذّر تسجيل الدخول.', 'Could not sign in.');

  // ── Profile setup ───────────────────────────────────────────
  String get completeProfile => _p('أكمل ملفك الشخصي', 'Complete your profile');
  String get lastStep =>
      _p('خطوة أخيرة قبل البدء!', 'One last step before you start!');
  String get profileHint => _p(
        'هذه المعلومات تظهر في جدول الترتيب وتوقعات الزملاء.',
        'This appears on the leaderboard and to colleagues.',
      );
  String get startPredicting => _p('ابدأ التوقعات', 'Start predicting');
  String get errSaveProfile => _p(
        'تعذّر حفظ الملف الشخصي. حاول مرة أخرى.',
        'Could not save profile. Try again.',
      );

  // ── Admin ───────────────────────────────────────────────────
  String get addMatch => _p('إضافة مباراة', 'Add match');
  String get adminOnly => _p('هذه الصفحة للمشرفين فقط', 'Admins only');
  String get noMatchesAdmin => _p('لا توجد مباريات', 'No matches');
  String get enterResult => _p('إدخال النتيجة', 'Enter result');
  String get delete => _p('حذف', 'Delete');
  String get cancel => _p('إلغاء', 'Cancel');
  String get deleteMatchQ => _p('حذف المباراة؟', 'Delete this match?');
  String get saveResult => _p('حفظ النتيجة', 'Save result');
  String get errSaveResult => _p('تعذّر حفظ النتيجة', 'Could not save result');
  String get statusScheduled => _p('مجدولة', 'Scheduled');
  String get statusLive => _p('مباشرة', 'Live');
  String get statusFinished => _p('منتهية', 'Finished');
  String get statusCancelled => _p('ملغاة', 'Cancelled');
  String get homeTeam => _p('الفريق المضيف', 'Home team');
  String get awayTeam => _p('الفريق الضيف', 'Away team');
  String get pickKickoff => _p('اختر وقت المباراة', 'Pick kickoff time');
  String get apiId =>
      _p('معرّف الـ API (اختياري — لمزامنة النتائج)', 'API id (optional — for sync)');
  String get pickBothTeams =>
      _p('اختر الفريقين ووقت المباراة', 'Pick both teams and kickoff');
  String get sameTeam =>
      _p('لا يمكن اختيار نفس الفريق', "Can't pick the same team");
  String get errAddMatch => _p('تعذّر إضافة المباراة', 'Could not add match');
}

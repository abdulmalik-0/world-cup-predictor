# تحدي مونديال الشركة (Company World Cup Predictor)

تطبيق ويب متجاوب (Flutter Web + Supabase) لزيادة تفاعل الموظفين خلال كأس العالم عبر توقع نتائج المباريات وجدول ترتيب لحظي وسجل شفافية للتعديلات.

## المتطلبات

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.16+)
- [Supabase](https://supabase.com) — مشروع جديد
- (اختياري) [Supabase CLI](https://supabase.com/docs/guides/cli)

## الإعداد السريع

### 1. Supabase

1. أنشئ مشروعاً على Supabase.
2. من **SQL Editor**، نفّذ الملف:
   - `supabase/migrations/001_initial_schema.sql`
3. (اختياري) نفّذ `supabase/seed.sql` لإضافة مباريات تجريبية.
4. من **Authentication → Providers**:
   - فعّل **Email**
   - فعّل **Email + Password**
   - **Confirm email = OFF** (دخول مباشر بدون رسالة تحقق)
5. انسخ **Project URL** و **anon public key**.

### 2. Flutter

```bash
# انسخ env.example.json إلى env.json وضع مفاتيح Supabase
cp env.example.json env.json

cd "World Cup Predictor"
flutter pub get
flutter run -d chrome --web-port=8080 --dart-define-from-file=env.json
```

للبناء للإنتاج:

```bash
flutter build web \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

## آلية النقاط (على السيرفر)

| الحالة | مباراة عادية | مباراة السعودية (دبل 🔥) |
|--------|-------------|----------------------|
| النتيجة بالظبط | 3 | 6 |
| الفائز / التعادل | 1 | 2 |
| خطأ | 0 | 0 |

- يُغلق التوقع **15 دقيقة** قبل صافرة البداية.
- التعديل مسموح قبل الإغلاق، ويُسجّل في `prediction_history`.
- بعد الإغلاق، تظهر توقعات الجميع في صفحة **الطقطقة**.

## هيكل المشروع

```
lib/
├── core/          # إعدادات، ثيم، توجيه، منطق مساعد
├── features/      # auth, dashboard, leaderboard, insights
├── models/
├── providers/     # Riverpod
└── services/      # Supabase API
supabase/
├── migrations/    # مخطط قاعدة البيانات + triggers + RLS
└── seed.sql
```

## المشرف (Admin)

1. نفّذ الترحيل `supabase/migrations/003_admin_and_sync.sql` (يضيف دور المشرف + صلاحيات RLS + عمود `external_ref`).
2. عيّن نفسك مشرفاً (مرة واحدة) من SQL Editor:

```sql
UPDATE public.profiles SET is_admin = true
WHERE id = (SELECT id FROM auth.users WHERE email = 'you@company.com');
```

3. بعد إعادة الدخول تظهر أيقونة **لوحة التحكم** في الشريط العلوي — منها تضيف المباريات وتُدخل النتائج مباشرة (يحسب المحفّز النقاط تلقائياً).

## مزامنة النتائج تلقائياً (API)

دالة `supabase/functions/sync-results` تجلب النتائج النهائية من مزوّد بيانات وتكتبها في الجدول.

> ⚠️ تستخدم مفتاح `service_role` من **جهة الخادم فقط** (سرّ في Supabase) — لا يوضع أبداً في تطبيق الويب.

```bash
# اربط مباريات الجدول بمعرّفات المزوّد عبر حقل "معرّف الـ API" في لوحة التحكم
supabase functions deploy sync-results
supabase secrets set FOOTBALL_API_KEY=YOUR_KEY
# SUPABASE_URL و SUPABASE_SERVICE_ROLE_KEY تُحقن تلقائياً
```

المزوّد الافتراضي [football-data.org](https://www.football-data.org). لتغييره عدّل `fetchProviderResult` في الدالة. جدوِل التشغيل (كل ١٠ دقائق مثلاً) عبر pg_cron أو أي cron خارجي يستدعي رابط الدالة.

## إدارة المباريات

أضف/حدّث المباريات من **لوحة التحكم داخل الموقع** (الأسهل)، أو من Supabase Dashboard / SQL:

```sql
INSERT INTO matches (home_team, away_team, home_team_code, away_team_code, kickoff_at)
VALUES ('السعودية', 'المكسيك', 'SA', 'MX', '2026-06-15 18:00:00+00');
```

عند انتهاء المباراة، حدّث النتيجة:

```sql
UPDATE matches
SET home_score = 2, away_score = 1, status = 'finished'
WHERE id = '...';
```

النقاط تُحسب تلقائياً عبر trigger على السيرفر.

## الجوائز

قسم الجوائز جاهز للإضافة لاحقاً من إدارة الشركة (يمكن ربطه بجدول `rewards` أو صفحة إدارية).

## الاختبارات

```bash
flutter test
```

## ملاحظات

- Flutter غير مثبت على هذا الجهاز حالياً — ثبّته ثم نفّذ `flutter pub get`.
- للإنتاج: فعّل RLS policies كما هي، واستخدم Service Role فقط من backend/admin.

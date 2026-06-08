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
flutter build web --release --dart-define-from-file=env.json
```

ثم ارفع **مجلد `build/web` كاملاً** (يحتوي `assets/assets/images/` للخلفية والشعار).

### صور التطبيق (مهم للنشر)

| الملف | الاستخدام |
|-------|-----------|
| `assets/images/wc26_logo.png` | شعار كأس العالم (تسجيل الدخول + بطاقة المباراة) |
| `assets/images/background.png` | خلفية الأعلام |

إذا لم تُضمَّن الصور في البناء → تظهر خلفية متدرّجة وأيقونة بديلة.

### Docker (على السيرفر)

```bash
cp .env.docker.example .env.docker
# عدّل SUPABASE_URL و SUPABASE_ANON_KEY في .env.docker

docker compose --env-file .env.docker up -d --build
```

الـ Dockerfile يبني Flutter داخل الحاوية ويضمّن الصور تلقائياً (لا يعتمد على `build/` المحلي).

## آلية النقاط (على السيرفر)

| الحالة | مباراة عادية | مباراة السعودية (دبل 🔥) |
|--------|-------------|----------------------|
| النتيجة بالظبط | 3 | 6 |
| الفائز / التعادل | 1 | 2 |
| خطأ | 0 | 0 |

- يُغلق التوقع **ساعة** قبل صافرة البداية.
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

دالة `supabase/functions/sync-results` تجلب مباريات **كأس العالم فقط** من [football-data.org](https://www.football-data.org) (`competitions/WC?season=2026`) وتربطها بجدول `matches` تلقائياً (حسب الفرق + وقت البداية)، ثم تحدّث النتائج عند انتهاء المباراة.

> ⚠️ مفتاح الـ API و `service_role` يبقيان **على الخادم فقط** (سرّ Supabase) — لا يوضعان في تطبيق الويب.

```powershell
# 1) انسخ supabase/.env.example إلى supabase/.env وضع مفتاحك
# 2) ارفع الأسرار وانشر الدالة:
powershell -ExecutionPolicy Bypass -File .\tool\set_football_secrets.ps1
supabase functions deploy sync-results
```

يمكن أيضاً ربط مباراة يدوياً بحقل **معرّف الـ API** في لوحة التحكم. جدوِل التشغيل (كل ١٠ دقائق مثلاً) عبر pg_cron أو cron خارجي يستدعي رابط الدالة.

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

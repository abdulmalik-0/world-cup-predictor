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
   - فعّل **Email** (Magic Link / OTP).
   - في **URL Configuration**، أضف عنوان تطبيقك (مثل `http://localhost:8080`).
5. انسخ **Project URL** و **anon public key**.

### 2. Flutter

```bash
cd "World Cup Predictor"
flutter pub get
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

للبناء للإنتاج:

```bash
flutter build web \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

## آلية النقاط (على السيرفر)

| الحالة | مباراة عادية | مباراة عربية (دبل 🔥) |
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

## إدارة المباريات

أضف/حدّث المباريات من Supabase Dashboard أو SQL:

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

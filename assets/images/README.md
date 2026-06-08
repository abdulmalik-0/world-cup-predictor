# صور التطبيق / App images

ضع الملفين التاليين هنا (بنفس الاسم بالضبط):

| الملف | الاستخدام | المواصفات |
|-------|-----------|-----------|
| `fifa-world-cup-2026--white.png` | شعار صفحة التسجيل/الدخول | شعار 2026 أبيض على خلفية داكنة |
| `wc26_logo.png` | شعار الوسط في شريط النتيجة | صورة طولية، خلفية بيضاء/شفافة |
| `background.png` | خلفية الموقع (تجميعة الأعلام) | صورة طولية كبيرة، خلفية كاملة |

- إن لم يوجد `wc26_logo.png` → يظهر بديل (كأس + 26).
- إن لم يوجد `background.png` → تظهر خلفية متدرّجة بديلة.
- بعد إضافة الصور: شغّل `flutter run` من جديد (الصور الجديدة تحتاج تشغيل كامل، مو Hot Reload).

Place `wc26_logo.png` (centre logo) and `background.png` (app background)
here. Both are optional — the app shows fallbacks if they're missing.

-- ===========================================================================
-- كأس العالم 2026 — مباريات الدول العربية + الأدوار الإقصائية
-- التوقيت: بتوقيت السعودية (+03)
-- ---------------------------------------------------------------------------
-- الدول العربية المشاركة: السعودية، الأردن، المغرب، تونس، مصر، الجزائر،
--                          العراق، قطر.
-- 🔥 دبل النقاط (×2) على: السعودية (SA) فقط.
--    (يُحسب تلقائياً عبر دالة is_arab_team_code — راجع migration 011)
-- ===========================================================================

TRUNCATE public.prediction_history, public.predictions, public.matches CASCADE;

-- ---------------------------------------------------------------------------
-- 1) دور المجموعات — مباريات الدول العربية فقط
-- ---------------------------------------------------------------------------
INSERT INTO public.matches (
  home_team, home_team_en, away_team, away_team_en,
  home_team_code, away_team_code, kickoff_at, status
)
VALUES
  -- الجولة الأولى
  ('قطر', 'Qatar', 'سويسرا', 'Switzerland', 'QA', 'CH', '2026-06-13 22:00:00+03', 'scheduled'),
  ('البرازيل', 'Brazil', 'المغرب', 'Morocco', 'BR', 'MA', '2026-06-14 01:00:00+03', 'scheduled'),
  ('السويد', 'Sweden', 'تونس', 'Tunisia', 'SE', 'TN', '2026-06-15 05:00:00+03', 'scheduled'),
  ('بلجيكا', 'Belgium', 'مصر', 'Egypt', 'BE', 'EG', '2026-06-15 22:00:00+03', 'scheduled'),
  ('أوروغواي', 'Uruguay', 'السعودية', 'Saudi Arabia', 'UY', 'SA', '2026-06-16 01:00:00+03', 'scheduled'),  -- 🔥 دبل
  ('العراق', 'Iraq', 'النرويج', 'Norway', 'IQ', 'NO', '2026-06-17 01:00:00+03', 'scheduled'),
  ('الأرجنتين', 'Argentina', 'الجزائر', 'Algeria', 'AR', 'DZ', '2026-06-17 04:00:00+03', 'scheduled'),
  ('النمسا', 'Austria', 'الأردن', 'Jordan', 'AT', 'JO', '2026-06-17 07:00:00+03', 'scheduled'),

  -- الجولة الثانية
  ('كندا', 'Canada', 'قطر', 'Qatar', 'CA', 'QA', '2026-06-19 01:00:00+03', 'scheduled'),
  ('اسكتلندا', 'Scotland', 'المغرب', 'Morocco', 'SF', 'MA', '2026-06-20 01:00:00+03', 'scheduled'),
  ('تونس', 'Tunisia', 'اليابان', 'Japan', 'TN', 'JP', '2026-06-21 07:00:00+03', 'scheduled'),
  ('إسبانيا', 'Spain', 'السعودية', 'Saudi Arabia', 'ES', 'SA', '2026-06-21 19:00:00+03', 'scheduled'),    -- 🔥 دبل
  ('نيوزيلندا', 'New Zealand', 'مصر', 'Egypt', 'NZ', 'EG', '2026-06-22 04:00:00+03', 'scheduled'),
  ('فرنسا', 'France', 'العراق', 'Iraq', 'FR', 'IQ', '2026-06-23 01:00:00+03', 'scheduled'),
  ('الأردن', 'Jordan', 'الجزائر', 'Algeria', 'JO', 'DZ', '2026-06-23 07:00:00+03', 'scheduled'),

  -- الجولة الثالثة
  ('المغرب', 'Morocco', 'هايتي', 'Haiti', 'MA', 'HT', '2026-06-24 22:00:00+03', 'scheduled'),
  ('البوسنة والهرسك', 'Bosnia', 'قطر', 'Qatar', 'BA', 'QA', '2026-06-25 01:00:00+03', 'scheduled'),
  ('تونس', 'Tunisia', 'هولندا', 'Netherlands', 'TN', 'NL', '2026-06-25 23:00:00+03', 'scheduled'),
  ('الرأس الأخضر', 'Cape Verde', 'السعودية', 'Saudi Arabia', 'CV', 'SA', '2026-06-26 19:00:00+03', 'scheduled'),  -- 🔥 دبل
  ('مصر', 'Egypt', 'إيران', 'Iran', 'EG', 'IR', '2026-06-26 22:00:00+03', 'scheduled'),
  ('السنغال', 'Senegal', 'العراق', 'Iraq', 'SN', 'IQ', '2026-06-27 01:00:00+03', 'scheduled'),
  ('الجزائر', 'Algeria', 'النمسا', 'Austria', 'DZ', 'AT', '2026-06-27 04:00:00+03', 'scheduled'),
  ('الأرجنتين', 'Argentina', 'الأردن', 'Jordan', 'AR', 'JO', '2026-06-27 04:00:00+03', 'scheduled');

-- ---------------------------------------------------------------------------
-- 2) الأدوار الإقصائية — الفرق تُحدَّد لاحقاً (TBD) من لوحة التحكم
--    عند إدخال السعودية (SA) في أي مباراة، يُفعَّل الدبل تلقائياً.
-- ---------------------------------------------------------------------------

-- دور الـ32
INSERT INTO public.matches (
  home_team, home_team_en, away_team, away_team_en,
  home_team_code, away_team_code, kickoff_at, status
)
VALUES
  ('دور الـ32 — مباراة 1',  'Round of 32 — M1',  'TBD', 'TBD', 'XX', 'YY', '2026-06-28 19:00:00+03', 'scheduled'),
  ('دور الـ32 — مباراة 2',  'Round of 32 — M2',  'TBD', 'TBD', 'XX', 'YY', '2026-06-28 23:00:00+03', 'scheduled'),
  ('دور الـ32 — مباراة 3',  'Round of 32 — M3',  'TBD', 'TBD', 'XX', 'YY', '2026-06-29 19:00:00+03', 'scheduled'),
  ('دور الـ32 — مباراة 4',  'Round of 32 — M4',  'TBD', 'TBD', 'XX', 'YY', '2026-06-29 23:00:00+03', 'scheduled'),
  ('دور الـ32 — مباراة 5',  'Round of 32 — M5',  'TBD', 'TBD', 'XX', 'YY', '2026-06-30 19:00:00+03', 'scheduled'),
  ('دور الـ32 — مباراة 6',  'Round of 32 — M6',  'TBD', 'TBD', 'XX', 'YY', '2026-06-30 23:00:00+03', 'scheduled'),
  ('دور الـ32 — مباراة 7',  'Round of 32 — M7',  'TBD', 'TBD', 'XX', 'YY', '2026-07-01 19:00:00+03', 'scheduled'),
  ('دور الـ32 — مباراة 8',  'Round of 32 — M8',  'TBD', 'TBD', 'XX', 'YY', '2026-07-01 23:00:00+03', 'scheduled'),
  ('دور الـ32 — مباراة 9',  'Round of 32 — M9',  'TBD', 'TBD', 'XX', 'YY', '2026-07-02 19:00:00+03', 'scheduled'),
  ('دور الـ32 — مباراة 10', 'Round of 32 — M10', 'TBD', 'TBD', 'XX', 'YY', '2026-07-02 23:00:00+03', 'scheduled'),
  ('دور الـ32 — مباراة 11', 'Round of 32 — M11', 'TBD', 'TBD', 'XX', 'YY', '2026-07-03 19:00:00+03', 'scheduled'),
  ('دور الـ32 — مباراة 12', 'Round of 32 — M12', 'TBD', 'TBD', 'XX', 'YY', '2026-07-03 23:00:00+03', 'scheduled'),
  ('دور الـ32 — مباراة 13', 'Round of 32 — M13', 'TBD', 'TBD', 'XX', 'YY', '2026-07-04 19:00:00+03', 'scheduled'),
  ('دور الـ32 — مباراة 14', 'Round of 32 — M14', 'TBD', 'TBD', 'XX', 'YY', '2026-07-04 23:00:00+03', 'scheduled'),
  ('دور الـ32 — مباراة 15', 'Round of 32 — M15', 'TBD', 'TBD', 'XX', 'YY', '2026-07-05 19:00:00+03', 'scheduled'),
  ('دور الـ32 — مباراة 16', 'Round of 32 — M16', 'TBD', 'TBD', 'XX', 'YY', '2026-07-05 23:00:00+03', 'scheduled');

-- دور الـ16
INSERT INTO public.matches (
  home_team, home_team_en, away_team, away_team_en,
  home_team_code, away_team_code, kickoff_at, status
)
VALUES
  ('دور الـ16 — مباراة 1', 'Round of 16 — M1', 'TBD', 'TBD', 'XX', 'YY', '2026-07-06 19:00:00+03', 'scheduled'),
  ('دور الـ16 — مباراة 2', 'Round of 16 — M2', 'TBD', 'TBD', 'XX', 'YY', '2026-07-06 23:00:00+03', 'scheduled'),
  ('دور الـ16 — مباراة 3', 'Round of 16 — M3', 'TBD', 'TBD', 'XX', 'YY', '2026-07-07 19:00:00+03', 'scheduled'),
  ('دور الـ16 — مباراة 4', 'Round of 16 — M4', 'TBD', 'TBD', 'XX', 'YY', '2026-07-07 23:00:00+03', 'scheduled'),
  ('دور الـ16 — مباراة 5', 'Round of 16 — M5', 'TBD', 'TBD', 'XX', 'YY', '2026-07-08 19:00:00+03', 'scheduled'),
  ('دور الـ16 — مباراة 6', 'Round of 16 — M6', 'TBD', 'TBD', 'XX', 'YY', '2026-07-08 23:00:00+03', 'scheduled'),
  ('دور الـ16 — مباراة 7', 'Round of 16 — M7', 'TBD', 'TBD', 'XX', 'YY', '2026-07-09 19:00:00+03', 'scheduled'),
  ('دور الـ16 — مباراة 8', 'Round of 16 — M8', 'TBD', 'TBD', 'XX', 'YY', '2026-07-09 23:00:00+03', 'scheduled');

-- ربع النهائي
INSERT INTO public.matches (
  home_team, home_team_en, away_team, away_team_en,
  home_team_code, away_team_code, kickoff_at, status
)
VALUES
  ('ربع النهائي 1', 'Quarter-Final 1', 'TBD', 'TBD', 'XX', 'YY', '2026-07-11 19:00:00+03', 'scheduled'),
  ('ربع النهائي 2', 'Quarter-Final 2', 'TBD', 'TBD', 'XX', 'YY', '2026-07-11 23:00:00+03', 'scheduled'),
  ('ربع النهائي 3', 'Quarter-Final 3', 'TBD', 'TBD', 'XX', 'YY', '2026-07-12 19:00:00+03', 'scheduled'),
  ('ربع النهائي 4', 'Quarter-Final 4', 'TBD', 'TBD', 'XX', 'YY', '2026-07-12 23:00:00+03', 'scheduled');

-- نصف النهائي
INSERT INTO public.matches (
  home_team, home_team_en, away_team, away_team_en,
  home_team_code, away_team_code, kickoff_at, status
)
VALUES
  ('نصف النهائي 1', 'Semi-Final 1', 'TBD', 'TBD', 'XX', 'YY', '2026-07-14 22:00:00+03', 'scheduled'),
  ('نصف النهائي 2', 'Semi-Final 2', 'TBD', 'TBD', 'XX', 'YY', '2026-07-15 22:00:00+03', 'scheduled');

-- تحديد المركز الثالث + النهائي
INSERT INTO public.matches (
  home_team, home_team_en, away_team, away_team_en,
  home_team_code, away_team_code, kickoff_at, status
)
VALUES
  ('تحديد المركز الثالث', 'Third Place', 'TBD', 'TBD', 'XX', 'YY', '2026-07-18 23:00:00+03', 'scheduled'),
  ('النهائي', 'Final', 'TBD', 'TBD', 'XX', 'YY', '2026-07-19 22:00:00+03', 'scheduled');

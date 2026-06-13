-- ===========================================================================
-- كأس العالم 2026 — جميع مباريات دور المجموعات (72) + الأدوار الإقصائية
-- التوقيت: بتوقيت السعودية (+03)
-- ---------------------------------------------------------------------------
-- 🔥 دبل النقاط (×2) على مباريات المنتخب السعودي (SA) فقط.
--    (يُحسب تلقائياً عبر دالة is_arab_team_code — راجع migration 011)
-- ===========================================================================

TRUNCATE public.prediction_history, public.predictions, public.matches CASCADE;

-- ---------------------------------------------------------------------------
-- 1) دور المجموعات — 72 مباراة
-- ---------------------------------------------------------------------------
INSERT INTO public.matches (
  home_team, home_team_en, away_team, away_team_en,
  home_team_code, away_team_code, kickoff_at, status
)
VALUES
  ('المكسيك', 'Mexico', 'جنوب إفريقيا', 'South Africa', 'MX', 'ZA', '2026-06-11 22:00:00+03', 'scheduled'),
  ('كوريا الجنوبية', 'South Korea', 'التشيك', 'Czech Republic', 'KR', 'CZ', '2026-06-12 05:00:00+03', 'scheduled'),
  ('كندا', 'Canada', 'البوسنة والهرسك', 'Bosnia', 'CA', 'BA', '2026-06-12 22:00:00+03', 'scheduled'),
  ('الولايات المتحدة', 'USA', 'باراغواي', 'Paraguay', 'US', 'PY', '2026-06-13 04:00:00+03', 'scheduled'),
  ('قطر', 'Qatar', 'سويسرا', 'Switzerland', 'QA', 'CH', '2026-06-13 22:00:00+03', 'scheduled'),
  ('البرازيل', 'Brazil', 'المغرب', 'Morocco', 'BR', 'MA', '2026-06-14 01:00:00+03', 'scheduled'),
  ('اسكتلندا', 'Scotland', 'هايتي', 'Haiti', 'SF', 'HT', '2026-06-14 04:00:00+03', 'scheduled'),
  ('أستراليا', 'Australia', 'تركيا', 'Turkey', 'AU', 'TR', '2026-06-14 07:00:00+03', 'scheduled'),
  ('ألمانيا', 'Germany', 'كوراساو', 'Curaçao', 'DE', 'CW', '2026-06-14 20:00:00+03', 'scheduled'),
  ('هولندا', 'Netherlands', 'اليابان', 'Japan', 'NL', 'JP', '2026-06-14 23:00:00+03', 'scheduled'),
  ('ساحل العاج', 'Ivory Coast', 'الإكوادور', 'Ecuador', 'CI', 'EC', '2026-06-15 02:00:00+03', 'scheduled'),
  ('السويد', 'Sweden', 'تونس', 'Tunisia', 'SE', 'TN', '2026-06-15 05:00:00+03', 'scheduled'),
  ('إسبانيا', 'Spain', 'الرأس الأخضر', 'Cape Verde', 'ES', 'CV', '2026-06-15 19:00:00+03', 'scheduled'),
  ('بلجيكا', 'Belgium', 'مصر', 'Egypt', 'BE', 'EG', '2026-06-15 22:00:00+03', 'scheduled'),
  ('أوروغواي', 'Uruguay', 'السعودية', 'Saudi Arabia', 'UY', 'SA', '2026-06-16 01:00:00+03', 'scheduled'),  -- 🔥 دبل
  ('إيران', 'Iran', 'نيوزيلندا', 'New Zealand', 'IR', 'NZ', '2026-06-16 04:00:00+03', 'scheduled'),
  ('فرنسا', 'France', 'السنغال', 'Senegal', 'FR', 'SN', '2026-06-16 22:00:00+03', 'scheduled'),
  ('العراق', 'Iraq', 'النرويج', 'Norway', 'IQ', 'NO', '2026-06-17 01:00:00+03', 'scheduled'),
  ('الأرجنتين', 'Argentina', 'الجزائر', 'Algeria', 'AR', 'DZ', '2026-06-17 04:00:00+03', 'scheduled'),
  ('النمسا', 'Austria', 'الأردن', 'Jordan', 'AT', 'JO', '2026-06-17 07:00:00+03', 'scheduled'),
  ('البرتغال', 'Portugal', 'جمهورية الكونغو ديموقراطية', 'DR Congo', 'PT', 'CD', '2026-06-17 20:00:00+03', 'scheduled'),
  ('إنجلترا', 'England', 'كرواتيا', 'Croatia', 'EN', 'HR', '2026-06-17 23:00:00+03', 'scheduled'),
  ('غانا', 'Ghana', 'بنما', 'Panama', 'GH', 'PA', '2026-06-18 02:00:00+03', 'scheduled'),
  ('أوزبكستان', 'Uzbekistan', 'كولومبيا', 'Colombia', 'UZ', 'CO', '2026-06-18 05:00:00+03', 'scheduled'),
  ('التشيك', 'Czech Republic', 'جنوب إفريقيا', 'South Africa', 'CZ', 'ZA', '2026-06-18 19:00:00+03', 'scheduled'),
  ('سويسرا', 'Switzerland', 'البوسنة والهرسك', 'Bosnia', 'CH', 'BA', '2026-06-18 22:00:00+03', 'scheduled'),
  ('كندا', 'Canada', 'قطر', 'Qatar', 'CA', 'QA', '2026-06-19 01:00:00+03', 'scheduled'),
  ('المكسيك', 'Mexico', 'كوريا الجنوبية', 'South Korea', 'MX', 'KR', '2026-06-19 04:00:00+03', 'scheduled'),
  ('الولايات المتحدة', 'USA', 'أستراليا', 'Australia', 'US', 'AU', '2026-06-19 22:00:00+03', 'scheduled'),
  ('اسكتلندا', 'Scotland', 'المغرب', 'Morocco', 'SF', 'MA', '2026-06-20 01:00:00+03', 'scheduled'),
  ('البرازيل', 'Brazil', 'هايتي', 'Haiti', 'BR', 'HT', '2026-06-20 03:30:00+03', 'scheduled'),
  ('تركيا', 'Turkey', 'باراغواي', 'Paraguay', 'TR', 'PY', '2026-06-20 06:00:00+03', 'scheduled'),
  ('هولندا', 'Netherlands', 'السويد', 'Sweden', 'NL', 'SE', '2026-06-20 20:00:00+03', 'scheduled'),
  ('ألمانيا', 'Germany', 'ساحل العاج', 'Ivory Coast', 'DE', 'CI', '2026-06-20 23:00:00+03', 'scheduled'),
  ('الإكوادور', 'Ecuador', 'كوراساو', 'Curaçao', 'EC', 'CW', '2026-06-21 03:00:00+03', 'scheduled'),
  ('تونس', 'Tunisia', 'اليابان', 'Japan', 'TN', 'JP', '2026-06-21 07:00:00+03', 'scheduled'),
  ('إسبانيا', 'Spain', 'السعودية', 'Saudi Arabia', 'ES', 'SA', '2026-06-21 19:00:00+03', 'scheduled'),  -- 🔥 دبل
  ('بلجيكا', 'Belgium', 'إيران', 'Iran', 'BE', 'IR', '2026-06-21 22:00:00+03', 'scheduled'),
  ('أوروغواي', 'Uruguay', 'الرأس الأخضر', 'Cape Verde', 'UY', 'CV', '2026-06-22 01:00:00+03', 'scheduled'),
  ('نيوزيلندا', 'New Zealand', 'مصر', 'Egypt', 'NZ', 'EG', '2026-06-22 04:00:00+03', 'scheduled'),
  ('النرويج', 'Norway', 'السنغال', 'Senegal', 'NO', 'SN', '2026-06-22 22:00:00+03', 'scheduled'),
  ('فرنسا', 'France', 'العراق', 'Iraq', 'FR', 'IQ', '2026-06-23 01:00:00+03', 'scheduled'),
  ('الأرجنتين', 'Argentina', 'النمسا', 'Austria', 'AR', 'AT', '2026-06-23 04:00:00+03', 'scheduled'),
  ('الأردن', 'Jordan', 'الجزائر', 'Algeria', 'JO', 'DZ', '2026-06-23 07:00:00+03', 'scheduled'),
  ('إنجلترا', 'England', 'غانا', 'Ghana', 'EN', 'GH', '2026-06-23 20:00:00+03', 'scheduled'),
  ('بنما', 'Panama', 'كرواتيا', 'Croatia', 'PA', 'HR', '2026-06-23 23:00:00+03', 'scheduled'),
  ('البرتغال', 'Portugal', 'أوزبكستان', 'Uzbekistan', 'PT', 'UZ', '2026-06-24 02:00:00+03', 'scheduled'),
  ('كولومبيا', 'Colombia', 'جمهورية الكونغو ديموقراطية', 'DR Congo', 'CO', 'CD', '2026-06-24 05:00:00+03', 'scheduled'),
  ('اسكتلندا', 'Scotland', 'البرازيل', 'Brazil', 'SF', 'BR', '2026-06-24 22:00:00+03', 'scheduled'),
  ('المغرب', 'Morocco', 'هايتي', 'Haiti', 'MA', 'HT', '2026-06-24 22:00:00+03', 'scheduled'),
  ('سويسرا', 'Switzerland', 'كندا', 'Canada', 'CH', 'CA', '2026-06-25 01:00:00+03', 'scheduled'),
  ('البوسنة والهرسك', 'Bosnia', 'قطر', 'Qatar', 'BA', 'QA', '2026-06-25 01:00:00+03', 'scheduled'),
  ('التشيك', 'Czech Republic', 'المكسيك', 'Mexico', 'CZ', 'MX', '2026-06-25 04:00:00+03', 'scheduled'),
  ('جنوب إفريقيا', 'South Africa', 'كوريا الجنوبية', 'South Korea', 'ZA', 'KR', '2026-06-25 04:00:00+03', 'scheduled'),
  ('كوراساو', 'Curaçao', 'ساحل العاج', 'Ivory Coast', 'CW', 'CI', '2026-06-25 20:00:00+03', 'scheduled'),
  ('الإكوادور', 'Ecuador', 'ألمانيا', 'Germany', 'EC', 'DE', '2026-06-25 20:00:00+03', 'scheduled'),
  ('اليابان', 'Japan', 'السويد', 'Sweden', 'JP', 'SE', '2026-06-25 23:00:00+03', 'scheduled'),
  ('تونس', 'Tunisia', 'هولندا', 'Netherlands', 'TN', 'NL', '2026-06-25 23:00:00+03', 'scheduled'),
  ('تركيا', 'Turkey', 'الولايات المتحدة', 'USA', 'TR', 'US', '2026-06-26 03:00:00+03', 'scheduled'),
  ('باراغواي', 'Paraguay', 'أستراليا', 'Australia', 'PY', 'AU', '2026-06-26 03:00:00+03', 'scheduled'),
  ('الرأس الأخضر', 'Cape Verde', 'السعودية', 'Saudi Arabia', 'CV', 'SA', '2026-06-26 19:00:00+03', 'scheduled'),  -- 🔥 دبل
  ('أوروغواي', 'Uruguay', 'إسبانيا', 'Spain', 'UY', 'ES', '2026-06-26 19:00:00+03', 'scheduled'),
  ('مصر', 'Egypt', 'إيران', 'Iran', 'EG', 'IR', '2026-06-26 22:00:00+03', 'scheduled'),
  ('نيوزيلندا', 'New Zealand', 'بلجيكا', 'Belgium', 'NZ', 'BE', '2026-06-26 22:00:00+03', 'scheduled'),
  ('السنغال', 'Senegal', 'العراق', 'Iraq', 'SN', 'IQ', '2026-06-27 01:00:00+03', 'scheduled'),
  ('النرويج', 'Norway', 'فرنسا', 'France', 'NO', 'FR', '2026-06-27 01:00:00+03', 'scheduled'),
  ('الجزائر', 'Algeria', 'النمسا', 'Austria', 'DZ', 'AT', '2026-06-27 04:00:00+03', 'scheduled'),
  ('كولومبيا', 'Colombia', 'البرتغال', 'Portugal', 'CO', 'PT', '2026-06-27 04:00:00+03', 'scheduled'),
  ('جمهورية الكونغو ديموقراطية', 'DR Congo', 'أوزبكستان', 'Uzbekistan', 'CD', 'UZ', '2026-06-27 04:00:00+03', 'scheduled'),
  ('الأرجنتين', 'Argentina', 'الأردن', 'Jordan', 'AR', 'JO', '2026-06-27 04:00:00+03', 'scheduled'),
  ('كرواتيا', 'Croatia', 'غانا', 'Ghana', 'HR', 'GH', '2026-06-27 19:00:00+03', 'scheduled'),
  ('بنما', 'Panama', 'إنجلترا', 'England', 'PA', 'EN', '2026-06-27 19:00:00+03', 'scheduled');

-- ---------------------------------------------------------------------------
-- 2) الأدوار الإقصائية — الفرق تُحدَّد لاحقاً (TBD) من لوحة التحكم
--    عند إدخال السعودية (SA) في أي مباراة، يُفعَّل الدبل تلقائياً.
-- ---------------------------------------------------------------------------

-- دور الـ32 (16 مباراة)
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

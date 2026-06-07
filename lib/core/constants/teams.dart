/// Team catalog: Arabic, English, and flag images (flagcdn.com).
class TeamInfo {
  const TeamInfo({
    required this.code,
    required this.nameAr,
    required this.nameEn,
    this.flagSlug,
  });

  final String code;
  final String nameAr;
  final String nameEn;
  final String? flagSlug;

  String get flagUrl {
    if (flagSlug == null) return '';
    return 'https://flagcdn.com/w80/$flagSlug.png';
  }
}

const _catalog = <String, TeamInfo>{
  'MX': TeamInfo(code: 'MX', nameAr: 'المكسيك', nameEn: 'Mexico', flagSlug: 'mx'),
  'ZA': TeamInfo(code: 'ZA', nameAr: 'جنوب إفريقيا', nameEn: 'South Africa', flagSlug: 'za'),
  'KR': TeamInfo(code: 'KR', nameAr: 'كوريا الجنوبية', nameEn: 'South Korea', flagSlug: 'kr'),
  'CZ': TeamInfo(code: 'CZ', nameAr: 'التشيك', nameEn: 'Czech Republic', flagSlug: 'cz'),
  'CA': TeamInfo(code: 'CA', nameAr: 'كندا', nameEn: 'Canada', flagSlug: 'ca'),
  'BA': TeamInfo(code: 'BA', nameAr: 'البوسنة والهرسك', nameEn: 'Bosnia', flagSlug: 'ba'),
  'US': TeamInfo(code: 'US', nameAr: 'الولايات المتحدة', nameEn: 'USA', flagSlug: 'us'),
  'PY': TeamInfo(code: 'PY', nameAr: 'باراغواي', nameEn: 'Paraguay', flagSlug: 'py'),
  'QA': TeamInfo(code: 'QA', nameAr: 'قطر', nameEn: 'Qatar', flagSlug: 'qa'),
  'CH': TeamInfo(code: 'CH', nameAr: 'سويسرا', nameEn: 'Switzerland', flagSlug: 'ch'),
  'BR': TeamInfo(code: 'BR', nameAr: 'البرازيل', nameEn: 'Brazil', flagSlug: 'br'),
  'MA': TeamInfo(code: 'MA', nameAr: 'المغرب', nameEn: 'Morocco', flagSlug: 'ma'),
  'SF': TeamInfo(code: 'SF', nameAr: 'اسكتلندا', nameEn: 'Scotland', flagSlug: 'gb-sct'),
  'HT': TeamInfo(code: 'HT', nameAr: 'هايتي', nameEn: 'Haiti', flagSlug: 'ht'),
  'AU': TeamInfo(code: 'AU', nameAr: 'أستراليا', nameEn: 'Australia', flagSlug: 'au'),
  'TR': TeamInfo(code: 'TR', nameAr: 'تركيا', nameEn: 'Turkey', flagSlug: 'tr'),
  'DE': TeamInfo(code: 'DE', nameAr: 'ألمانيا', nameEn: 'Germany', flagSlug: 'de'),
  'CW': TeamInfo(code: 'CW', nameAr: 'كوراساو', nameEn: 'Curaçao', flagSlug: 'cw'),
  'NL': TeamInfo(code: 'NL', nameAr: 'هولندا', nameEn: 'Netherlands', flagSlug: 'nl'),
  'JP': TeamInfo(code: 'JP', nameAr: 'اليابان', nameEn: 'Japan', flagSlug: 'jp'),
  'CI': TeamInfo(code: 'CI', nameAr: 'ساحل العاج', nameEn: 'Ivory Coast', flagSlug: 'ci'),
  'EC': TeamInfo(code: 'EC', nameAr: 'الإكوادور', nameEn: 'Ecuador', flagSlug: 'ec'),
  'SE': TeamInfo(code: 'SE', nameAr: 'السويد', nameEn: 'Sweden', flagSlug: 'se'),
  'TN': TeamInfo(code: 'TN', nameAr: 'تونس', nameEn: 'Tunisia', flagSlug: 'tn'),
  'ES': TeamInfo(code: 'ES', nameAr: 'إسبانيا', nameEn: 'Spain', flagSlug: 'es'),
  'CV': TeamInfo(code: 'CV', nameAr: 'الرأس الأخضر', nameEn: 'Cape Verde', flagSlug: 'cv'),
  'BE': TeamInfo(code: 'BE', nameAr: 'بلجيكا', nameEn: 'Belgium', flagSlug: 'be'),
  'EG': TeamInfo(code: 'EG', nameAr: 'مصر', nameEn: 'Egypt', flagSlug: 'eg'),
  'UY': TeamInfo(code: 'UY', nameAr: 'أوروغواي', nameEn: 'Uruguay', flagSlug: 'uy'),
  'SA': TeamInfo(code: 'SA', nameAr: 'السعودية', nameEn: 'Saudi Arabia', flagSlug: 'sa'),
  'IR': TeamInfo(code: 'IR', nameAr: 'إيران', nameEn: 'Iran', flagSlug: 'ir'),
  'NZ': TeamInfo(code: 'NZ', nameAr: 'نيوزيلندا', nameEn: 'New Zealand', flagSlug: 'nz'),
  'FR': TeamInfo(code: 'FR', nameAr: 'فرنسا', nameEn: 'France', flagSlug: 'fr'),
  'SN': TeamInfo(code: 'SN', nameAr: 'السنغال', nameEn: 'Senegal', flagSlug: 'sn'),
  'IQ': TeamInfo(code: 'IQ', nameAr: 'العراق', nameEn: 'Iraq', flagSlug: 'iq'),
  'NO': TeamInfo(code: 'NO', nameAr: 'النرويج', nameEn: 'Norway', flagSlug: 'no'),
  'AR': TeamInfo(code: 'AR', nameAr: 'الأرجنتين', nameEn: 'Argentina', flagSlug: 'ar'),
  'DZ': TeamInfo(code: 'DZ', nameAr: 'الجزائر', nameEn: 'Algeria', flagSlug: 'dz'),
  'AT': TeamInfo(code: 'AT', nameAr: 'النمسا', nameEn: 'Austria', flagSlug: 'at'),
  'JO': TeamInfo(code: 'JO', nameAr: 'الأردن', nameEn: 'Jordan', flagSlug: 'jo'),
  'PT': TeamInfo(code: 'PT', nameAr: 'البرتغال', nameEn: 'Portugal', flagSlug: 'pt'),
  'CD': TeamInfo(
    code: 'CD',
    nameAr: 'جمهورية الكونغو ديموقراطية',
    nameEn: 'DR Congo',
    flagSlug: 'cd',
  ),
  'EN': TeamInfo(code: 'EN', nameAr: 'إنجلترا', nameEn: 'England', flagSlug: 'gb-eng'),
  'HR': TeamInfo(code: 'HR', nameAr: 'كرواتيا', nameEn: 'Croatia', flagSlug: 'hr'),
  'GH': TeamInfo(code: 'GH', nameAr: 'غانا', nameEn: 'Ghana', flagSlug: 'gh'),
  'PA': TeamInfo(code: 'PA', nameAr: 'بنما', nameEn: 'Panama', flagSlug: 'pa'),
  'UZ': TeamInfo(code: 'UZ', nameAr: 'أوزبكستان', nameEn: 'Uzbekistan', flagSlug: 'uz'),
  'CO': TeamInfo(code: 'CO', nameAr: 'كولومبيا', nameEn: 'Colombia', flagSlug: 'co'),
};

TeamInfo resolveTeam({
  required String code,
  String? nameAr,
  String? nameEn,
}) {
  final info = _catalog[code.toUpperCase()];
  if (info != null) {
    return TeamInfo(
      code: code.toUpperCase(),
      nameAr: nameAr ?? info.nameAr,
      nameEn: nameEn ?? info.nameEn,
      flagSlug: info.flagSlug,
    );
  }
  return TeamInfo(
    code: code.toUpperCase(),
    nameAr: nameAr ?? code,
    nameEn: nameEn ?? code,
    flagSlug: null,
  );
}

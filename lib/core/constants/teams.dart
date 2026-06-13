/// Team catalog: Arabic + English names and flag images (flagcdn.com).
///
/// Flags are derived automatically from the ISO 3166-1 alpha-2 country code,
/// so any country resolves to a flag even if it is not listed below. Only the
/// non-ISO internal codes (UK home nations) need an explicit [flagSlug].
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

  /// Explicit flagcdn slug override (for codes that are not ISO alpha-2).
  final String? flagSlug;

  /// Whether [code] is a plain 2-letter ASCII code usable as a flagcdn slug.
  static bool _isAlpha2(String c) {
    if (c.length != 2) return false;
    return RegExp(r'^[A-Za-z]{2}$').hasMatch(c);
  }

  String get flagUrl {
    final slug = flagSlug ?? (_isAlpha2(code) ? code.toLowerCase() : null);
    if (slug == null) return '';
    return 'https://flagcdn.com/w160/$slug.png';
  }
}

/// Full country catalog keyed by uppercase code. ISO alpha-2 unless noted.
const _catalog = <String, TeamInfo>{
  // ── Arab / MENA ──────────────────────────────────────────────
  'SA': TeamInfo(code: 'SA', nameAr: 'السعودية', nameEn: 'Saudi Arabia'),
  'AE': TeamInfo(code: 'AE', nameAr: 'الإمارات', nameEn: 'UAE'),
  'QA': TeamInfo(code: 'QA', nameAr: 'قطر', nameEn: 'Qatar'),
  'KW': TeamInfo(code: 'KW', nameAr: 'الكويت', nameEn: 'Kuwait'),
  'BH': TeamInfo(code: 'BH', nameAr: 'البحرين', nameEn: 'Bahrain'),
  'OM': TeamInfo(code: 'OM', nameAr: 'عُمان', nameEn: 'Oman'),
  'YE': TeamInfo(code: 'YE', nameAr: 'اليمن', nameEn: 'Yemen'),
  'IQ': TeamInfo(code: 'IQ', nameAr: 'العراق', nameEn: 'Iraq'),
  'JO': TeamInfo(code: 'JO', nameAr: 'الأردن', nameEn: 'Jordan'),
  'LB': TeamInfo(code: 'LB', nameAr: 'لبنان', nameEn: 'Lebanon'),
  'SY': TeamInfo(code: 'SY', nameAr: 'سوريا', nameEn: 'Syria'),
  'PS': TeamInfo(code: 'PS', nameAr: 'فلسطين', nameEn: 'Palestine'),
  'EG': TeamInfo(code: 'EG', nameAr: 'مصر', nameEn: 'Egypt'),
  'LY': TeamInfo(code: 'LY', nameAr: 'ليبيا', nameEn: 'Libya'),
  'TN': TeamInfo(code: 'TN', nameAr: 'تونس', nameEn: 'Tunisia'),
  'DZ': TeamInfo(code: 'DZ', nameAr: 'الجزائر', nameEn: 'Algeria'),
  'MA': TeamInfo(code: 'MA', nameAr: 'المغرب', nameEn: 'Morocco'),
  'MR': TeamInfo(code: 'MR', nameAr: 'موريتانيا', nameEn: 'Mauritania'),
  'SD': TeamInfo(code: 'SD', nameAr: 'السودان', nameEn: 'Sudan'),
  'SS': TeamInfo(code: 'SS', nameAr: 'جنوب السودان', nameEn: 'South Sudan'),
  'SO': TeamInfo(code: 'SO', nameAr: 'الصومال', nameEn: 'Somalia'),
  'DJ': TeamInfo(code: 'DJ', nameAr: 'جيبوتي', nameEn: 'Djibouti'),
  'KM': TeamInfo(code: 'KM', nameAr: 'جزر القمر', nameEn: 'Comoros'),

  // ── Europe (UEFA) ────────────────────────────────────────────
  'AL': TeamInfo(code: 'AL', nameAr: 'ألبانيا', nameEn: 'Albania'),
  'AD': TeamInfo(code: 'AD', nameAr: 'أندورا', nameEn: 'Andorra'),
  'AT': TeamInfo(code: 'AT', nameAr: 'النمسا', nameEn: 'Austria'),
  'BY': TeamInfo(code: 'BY', nameAr: 'بيلاروسيا', nameEn: 'Belarus'),
  'BE': TeamInfo(code: 'BE', nameAr: 'بلجيكا', nameEn: 'Belgium'),
  'BA': TeamInfo(code: 'BA', nameAr: 'البوسنة والهرسك', nameEn: 'Bosnia'),
  'BG': TeamInfo(code: 'BG', nameAr: 'بلغاريا', nameEn: 'Bulgaria'),
  'HR': TeamInfo(code: 'HR', nameAr: 'كرواتيا', nameEn: 'Croatia'),
  'CY': TeamInfo(code: 'CY', nameAr: 'قبرص', nameEn: 'Cyprus'),
  'CZ': TeamInfo(code: 'CZ', nameAr: 'التشيك', nameEn: 'Czechia'),
  'DK': TeamInfo(code: 'DK', nameAr: 'الدنمارك', nameEn: 'Denmark'),
  'EN': TeamInfo(code: 'EN', nameAr: 'إنجلترا', nameEn: 'England', flagSlug: 'gb-eng'),
  'EE': TeamInfo(code: 'EE', nameAr: 'إستونيا', nameEn: 'Estonia'),
  'FO': TeamInfo(code: 'FO', nameAr: 'جزر فارو', nameEn: 'Faroe Islands'),
  'FI': TeamInfo(code: 'FI', nameAr: 'فنلندا', nameEn: 'Finland'),
  'FR': TeamInfo(code: 'FR', nameAr: 'فرنسا', nameEn: 'France'),
  'DE': TeamInfo(code: 'DE', nameAr: 'ألمانيا', nameEn: 'Germany'),
  'GI': TeamInfo(code: 'GI', nameAr: 'جبل طارق', nameEn: 'Gibraltar'),
  'GR': TeamInfo(code: 'GR', nameAr: 'اليونان', nameEn: 'Greece'),
  'HU': TeamInfo(code: 'HU', nameAr: 'المجر', nameEn: 'Hungary'),
  'IS': TeamInfo(code: 'IS', nameAr: 'آيسلندا', nameEn: 'Iceland'),
  'IE': TeamInfo(code: 'IE', nameAr: 'أيرلندا', nameEn: 'Ireland'),
  'IT': TeamInfo(code: 'IT', nameAr: 'إيطاليا', nameEn: 'Italy'),
  'XK': TeamInfo(code: 'XK', nameAr: 'كوسوفو', nameEn: 'Kosovo'),
  'LV': TeamInfo(code: 'LV', nameAr: 'لاتفيا', nameEn: 'Latvia'),
  'LI': TeamInfo(code: 'LI', nameAr: 'ليختنشتاين', nameEn: 'Liechtenstein'),
  'LT': TeamInfo(code: 'LT', nameAr: 'ليتوانيا', nameEn: 'Lithuania'),
  'LU': TeamInfo(code: 'LU', nameAr: 'لوكسمبورغ', nameEn: 'Luxembourg'),
  'MT': TeamInfo(code: 'MT', nameAr: 'مالطا', nameEn: 'Malta'),
  'MD': TeamInfo(code: 'MD', nameAr: 'مولدوفا', nameEn: 'Moldova'),
  'MC': TeamInfo(code: 'MC', nameAr: 'موناكو', nameEn: 'Monaco'),
  'ME': TeamInfo(code: 'ME', nameAr: 'الجبل الأسود', nameEn: 'Montenegro'),
  'NL': TeamInfo(code: 'NL', nameAr: 'هولندا', nameEn: 'Netherlands'),
  'MK': TeamInfo(code: 'MK', nameAr: 'مقدونيا الشمالية', nameEn: 'North Macedonia'),
  'NIR': TeamInfo(code: 'NIR', nameAr: 'أيرلندا الشمالية', nameEn: 'N. Ireland', flagSlug: 'gb-nir'),
  'NO': TeamInfo(code: 'NO', nameAr: 'النرويج', nameEn: 'Norway'),
  'PL': TeamInfo(code: 'PL', nameAr: 'بولندا', nameEn: 'Poland'),
  'PT': TeamInfo(code: 'PT', nameAr: 'البرتغال', nameEn: 'Portugal'),
  'RO': TeamInfo(code: 'RO', nameAr: 'رومانيا', nameEn: 'Romania'),
  'RU': TeamInfo(code: 'RU', nameAr: 'روسيا', nameEn: 'Russia'),
  'SM': TeamInfo(code: 'SM', nameAr: 'سان مارينو', nameEn: 'San Marino'),
  'SF': TeamInfo(code: 'SF', nameAr: 'اسكتلندا', nameEn: 'Scotland', flagSlug: 'gb-sct'),
  'RS': TeamInfo(code: 'RS', nameAr: 'صربيا', nameEn: 'Serbia'),
  'SK': TeamInfo(code: 'SK', nameAr: 'سلوفاكيا', nameEn: 'Slovakia'),
  'SI': TeamInfo(code: 'SI', nameAr: 'سلوفينيا', nameEn: 'Slovenia'),
  'ES': TeamInfo(code: 'ES', nameAr: 'إسبانيا', nameEn: 'Spain'),
  'SE': TeamInfo(code: 'SE', nameAr: 'السويد', nameEn: 'Sweden'),
  'CH': TeamInfo(code: 'CH', nameAr: 'سويسرا', nameEn: 'Switzerland'),
  'TR': TeamInfo(code: 'TR', nameAr: 'تركيا', nameEn: 'Türkiye'),
  'UA': TeamInfo(code: 'UA', nameAr: 'أوكرانيا', nameEn: 'Ukraine'),
  'WAL': TeamInfo(code: 'WAL', nameAr: 'ويلز', nameEn: 'Wales', flagSlug: 'gb-wls'),

  // ── Africa (CAF) ─────────────────────────────────────────────
  'AO': TeamInfo(code: 'AO', nameAr: 'أنغولا', nameEn: 'Angola'),
  'BJ': TeamInfo(code: 'BJ', nameAr: 'بنين', nameEn: 'Benin'),
  'BW': TeamInfo(code: 'BW', nameAr: 'بوتسوانا', nameEn: 'Botswana'),
  'BF': TeamInfo(code: 'BF', nameAr: 'بوركينا فاسو', nameEn: 'Burkina Faso'),
  'BI': TeamInfo(code: 'BI', nameAr: 'بوروندي', nameEn: 'Burundi'),
  'CM': TeamInfo(code: 'CM', nameAr: 'الكاميرون', nameEn: 'Cameroon'),
  'CV': TeamInfo(code: 'CV', nameAr: 'الرأس الأخضر', nameEn: 'Cape Verde'),
  'CF': TeamInfo(code: 'CF', nameAr: 'إفريقيا الوسطى', nameEn: 'Central African Rep.'),
  'TD': TeamInfo(code: 'TD', nameAr: 'تشاد', nameEn: 'Chad'),
  'CG': TeamInfo(code: 'CG', nameAr: 'الكونغو', nameEn: 'Congo'),
  'CD': TeamInfo(code: 'CD', nameAr: 'الكونغو الديمقراطية', nameEn: 'DR Congo'),
  'CI': TeamInfo(code: 'CI', nameAr: 'ساحل العاج', nameEn: 'Ivory Coast'),
  'GQ': TeamInfo(code: 'GQ', nameAr: 'غينيا الاستوائية', nameEn: 'Equatorial Guinea'),
  'ER': TeamInfo(code: 'ER', nameAr: 'إريتريا', nameEn: 'Eritrea'),
  'SZ': TeamInfo(code: 'SZ', nameAr: 'إسواتيني', nameEn: 'Eswatini'),
  'ET': TeamInfo(code: 'ET', nameAr: 'إثيوبيا', nameEn: 'Ethiopia'),
  'GA': TeamInfo(code: 'GA', nameAr: 'الغابون', nameEn: 'Gabon'),
  'GM': TeamInfo(code: 'GM', nameAr: 'غامبيا', nameEn: 'Gambia'),
  'GH': TeamInfo(code: 'GH', nameAr: 'غانا', nameEn: 'Ghana'),
  'GN': TeamInfo(code: 'GN', nameAr: 'غينيا', nameEn: 'Guinea'),
  'GW': TeamInfo(code: 'GW', nameAr: 'غينيا بيساو', nameEn: 'Guinea-Bissau'),
  'KE': TeamInfo(code: 'KE', nameAr: 'كينيا', nameEn: 'Kenya'),
  'LS': TeamInfo(code: 'LS', nameAr: 'ليسوتو', nameEn: 'Lesotho'),
  'LR': TeamInfo(code: 'LR', nameAr: 'ليبيريا', nameEn: 'Liberia'),
  'MG': TeamInfo(code: 'MG', nameAr: 'مدغشقر', nameEn: 'Madagascar'),
  'MW': TeamInfo(code: 'MW', nameAr: 'مالاوي', nameEn: 'Malawi'),
  'ML': TeamInfo(code: 'ML', nameAr: 'مالي', nameEn: 'Mali'),
  'MU': TeamInfo(code: 'MU', nameAr: 'موريشيوس', nameEn: 'Mauritius'),
  'MZ': TeamInfo(code: 'MZ', nameAr: 'موزمبيق', nameEn: 'Mozambique'),
  'NA': TeamInfo(code: 'NA', nameAr: 'ناميبيا', nameEn: 'Namibia'),
  'NE': TeamInfo(code: 'NE', nameAr: 'النيجر', nameEn: 'Niger'),
  'NG': TeamInfo(code: 'NG', nameAr: 'نيجيريا', nameEn: 'Nigeria'),
  'RW': TeamInfo(code: 'RW', nameAr: 'رواندا', nameEn: 'Rwanda'),
  'ST': TeamInfo(code: 'ST', nameAr: 'ساو تومي وبرينسيب', nameEn: 'São Tomé'),
  'SN': TeamInfo(code: 'SN', nameAr: 'السنغال', nameEn: 'Senegal'),
  'SC': TeamInfo(code: 'SC', nameAr: 'سيشل', nameEn: 'Seychelles'),
  'SL': TeamInfo(code: 'SL', nameAr: 'سيراليون', nameEn: 'Sierra Leone'),
  'ZA': TeamInfo(code: 'ZA', nameAr: 'جنوب إفريقيا', nameEn: 'South Africa'),
  'TZ': TeamInfo(code: 'TZ', nameAr: 'تنزانيا', nameEn: 'Tanzania'),
  'TG': TeamInfo(code: 'TG', nameAr: 'توغو', nameEn: 'Togo'),
  'UG': TeamInfo(code: 'UG', nameAr: 'أوغندا', nameEn: 'Uganda'),
  'ZM': TeamInfo(code: 'ZM', nameAr: 'زامبيا', nameEn: 'Zambia'),
  'ZW': TeamInfo(code: 'ZW', nameAr: 'زيمبابوي', nameEn: 'Zimbabwe'),

  // ── Asia (AFC) ───────────────────────────────────────────────
  'AF': TeamInfo(code: 'AF', nameAr: 'أفغانستان', nameEn: 'Afghanistan'),
  'AM': TeamInfo(code: 'AM', nameAr: 'أرمينيا', nameEn: 'Armenia'),
  'AZ': TeamInfo(code: 'AZ', nameAr: 'أذربيجان', nameEn: 'Azerbaijan'),
  'BD': TeamInfo(code: 'BD', nameAr: 'بنغلاديش', nameEn: 'Bangladesh'),
  'BT': TeamInfo(code: 'BT', nameAr: 'بوتان', nameEn: 'Bhutan'),
  'BN': TeamInfo(code: 'BN', nameAr: 'بروناي', nameEn: 'Brunei'),
  'KH': TeamInfo(code: 'KH', nameAr: 'كمبوديا', nameEn: 'Cambodia'),
  'CN': TeamInfo(code: 'CN', nameAr: 'الصين', nameEn: 'China'),
  'GE': TeamInfo(code: 'GE', nameAr: 'جورجيا', nameEn: 'Georgia'),
  'HK': TeamInfo(code: 'HK', nameAr: 'هونغ كونغ', nameEn: 'Hong Kong'),
  'IN': TeamInfo(code: 'IN', nameAr: 'الهند', nameEn: 'India'),
  'ID': TeamInfo(code: 'ID', nameAr: 'إندونيسيا', nameEn: 'Indonesia'),
  'IR': TeamInfo(code: 'IR', nameAr: 'إيران', nameEn: 'Iran'),
  'JP': TeamInfo(code: 'JP', nameAr: 'اليابان', nameEn: 'Japan'),
  'KZ': TeamInfo(code: 'KZ', nameAr: 'كازاخستان', nameEn: 'Kazakhstan'),
  'KG': TeamInfo(code: 'KG', nameAr: 'قيرغيزستان', nameEn: 'Kyrgyzstan'),
  'KR': TeamInfo(code: 'KR', nameAr: 'كوريا الجنوبية', nameEn: 'South Korea'),
  'KP': TeamInfo(code: 'KP', nameAr: 'كوريا الشمالية', nameEn: 'North Korea'),
  'LA': TeamInfo(code: 'LA', nameAr: 'لاوس', nameEn: 'Laos'),
  'MO': TeamInfo(code: 'MO', nameAr: 'ماكاو', nameEn: 'Macau'),
  'MY': TeamInfo(code: 'MY', nameAr: 'ماليزيا', nameEn: 'Malaysia'),
  'MV': TeamInfo(code: 'MV', nameAr: 'المالديف', nameEn: 'Maldives'),
  'MN': TeamInfo(code: 'MN', nameAr: 'منغوليا', nameEn: 'Mongolia'),
  'MM': TeamInfo(code: 'MM', nameAr: 'ميانمار', nameEn: 'Myanmar'),
  'NP': TeamInfo(code: 'NP', nameAr: 'نيبال', nameEn: 'Nepal'),
  'PK': TeamInfo(code: 'PK', nameAr: 'باكستان', nameEn: 'Pakistan'),
  'PH': TeamInfo(code: 'PH', nameAr: 'الفلبين', nameEn: 'Philippines'),
  'SG': TeamInfo(code: 'SG', nameAr: 'سنغافورة', nameEn: 'Singapore'),
  'LK': TeamInfo(code: 'LK', nameAr: 'سريلانكا', nameEn: 'Sri Lanka'),
  'TW': TeamInfo(code: 'TW', nameAr: 'تايوان', nameEn: 'Taiwan'),
  'TJ': TeamInfo(code: 'TJ', nameAr: 'طاجيكستان', nameEn: 'Tajikistan'),
  'TH': TeamInfo(code: 'TH', nameAr: 'تايلاند', nameEn: 'Thailand'),
  'TL': TeamInfo(code: 'TL', nameAr: 'تيمور الشرقية', nameEn: 'Timor-Leste'),
  'TM': TeamInfo(code: 'TM', nameAr: 'تركمانستان', nameEn: 'Turkmenistan'),
  'UZ': TeamInfo(code: 'UZ', nameAr: 'أوزبكستان', nameEn: 'Uzbekistan'),
  'VN': TeamInfo(code: 'VN', nameAr: 'فيتنام', nameEn: 'Vietnam'),

  // ── North/Central America & Caribbean (CONCACAF) ─────────────
  'AI': TeamInfo(code: 'AI', nameAr: 'أنغويلا', nameEn: 'Anguilla'),
  'AG': TeamInfo(code: 'AG', nameAr: 'أنتيغوا وبربودا', nameEn: 'Antigua & Barbuda'),
  'AW': TeamInfo(code: 'AW', nameAr: 'أروبا', nameEn: 'Aruba'),
  'BS': TeamInfo(code: 'BS', nameAr: 'الباهاما', nameEn: 'Bahamas'),
  'BB': TeamInfo(code: 'BB', nameAr: 'بربادوس', nameEn: 'Barbados'),
  'BZ': TeamInfo(code: 'BZ', nameAr: 'بليز', nameEn: 'Belize'),
  'BM': TeamInfo(code: 'BM', nameAr: 'برمودا', nameEn: 'Bermuda'),
  'CA': TeamInfo(code: 'CA', nameAr: 'كندا', nameEn: 'Canada'),
  'CW': TeamInfo(code: 'CW', nameAr: 'كوراساو', nameEn: 'Curaçao'),
  'CR': TeamInfo(code: 'CR', nameAr: 'كوستاريكا', nameEn: 'Costa Rica'),
  'CU': TeamInfo(code: 'CU', nameAr: 'كوبا', nameEn: 'Cuba'),
  'DM': TeamInfo(code: 'DM', nameAr: 'دومينيكا', nameEn: 'Dominica'),
  'DO': TeamInfo(code: 'DO', nameAr: 'الدومينيكان', nameEn: 'Dominican Rep.'),
  'SV': TeamInfo(code: 'SV', nameAr: 'السلفادور', nameEn: 'El Salvador'),
  'GD': TeamInfo(code: 'GD', nameAr: 'غرينادا', nameEn: 'Grenada'),
  'GT': TeamInfo(code: 'GT', nameAr: 'غواتيمالا', nameEn: 'Guatemala'),
  'GY': TeamInfo(code: 'GY', nameAr: 'غيانا', nameEn: 'Guyana'),
  'HT': TeamInfo(code: 'HT', nameAr: 'هايتي', nameEn: 'Haiti'),
  'HN': TeamInfo(code: 'HN', nameAr: 'هندوراس', nameEn: 'Honduras'),
  'JM': TeamInfo(code: 'JM', nameAr: 'جامايكا', nameEn: 'Jamaica'),
  'MX': TeamInfo(code: 'MX', nameAr: 'المكسيك', nameEn: 'Mexico'),
  'NI': TeamInfo(code: 'NI', nameAr: 'نيكاراغوا', nameEn: 'Nicaragua'),
  'PA': TeamInfo(code: 'PA', nameAr: 'بنما', nameEn: 'Panama'),
  'PR': TeamInfo(code: 'PR', nameAr: 'بورتوريكو', nameEn: 'Puerto Rico'),
  'KN': TeamInfo(code: 'KN', nameAr: 'سانت كيتس ونيفيس', nameEn: 'St. Kitts & Nevis'),
  'LC': TeamInfo(code: 'LC', nameAr: 'سانت لوسيا', nameEn: 'St. Lucia'),
  'VC': TeamInfo(code: 'VC', nameAr: 'سانت فنسنت', nameEn: 'St. Vincent'),
  'SR': TeamInfo(code: 'SR', nameAr: 'سورينام', nameEn: 'Suriname'),
  'TT': TeamInfo(code: 'TT', nameAr: 'ترينيداد وتوباغو', nameEn: 'Trinidad & Tobago'),
  'US': TeamInfo(code: 'US', nameAr: 'الولايات المتحدة', nameEn: 'USA'),

  // ── South America (CONMEBOL) ─────────────────────────────────
  'AR': TeamInfo(code: 'AR', nameAr: 'الأرجنتين', nameEn: 'Argentina'),
  'BO': TeamInfo(code: 'BO', nameAr: 'بوليفيا', nameEn: 'Bolivia'),
  'BR': TeamInfo(code: 'BR', nameAr: 'البرازيل', nameEn: 'Brazil'),
  'CL': TeamInfo(code: 'CL', nameAr: 'تشيلي', nameEn: 'Chile'),
  'CO': TeamInfo(code: 'CO', nameAr: 'كولومبيا', nameEn: 'Colombia'),
  'EC': TeamInfo(code: 'EC', nameAr: 'الإكوادور', nameEn: 'Ecuador'),
  'PY': TeamInfo(code: 'PY', nameAr: 'باراغواي', nameEn: 'Paraguay'),
  'PE': TeamInfo(code: 'PE', nameAr: 'بيرو', nameEn: 'Peru'),
  'UY': TeamInfo(code: 'UY', nameAr: 'أوروغواي', nameEn: 'Uruguay'),
  'VE': TeamInfo(code: 'VE', nameAr: 'فنزويلا', nameEn: 'Venezuela'),

  // ── Oceania (OFC) ────────────────────────────────────────────
  'AS': TeamInfo(code: 'AS', nameAr: 'ساموا الأمريكية', nameEn: 'American Samoa'),
  'AU': TeamInfo(code: 'AU', nameAr: 'أستراليا', nameEn: 'Australia'),
  'CK': TeamInfo(code: 'CK', nameAr: 'جزر كوك', nameEn: 'Cook Islands'),
  'FJ': TeamInfo(code: 'FJ', nameAr: 'فيجي', nameEn: 'Fiji'),
  'NC': TeamInfo(code: 'NC', nameAr: 'كاليدونيا الجديدة', nameEn: 'New Caledonia'),
  'NZ': TeamInfo(code: 'NZ', nameAr: 'نيوزيلندا', nameEn: 'New Zealand'),
  'PG': TeamInfo(code: 'PG', nameAr: 'بابوا غينيا الجديدة', nameEn: 'Papua New Guinea'),
  'WS': TeamInfo(code: 'WS', nameAr: 'ساموا', nameEn: 'Samoa'),
  'SB': TeamInfo(code: 'SB', nameAr: 'جزر سليمان', nameEn: 'Solomon Islands'),
  'TO': TeamInfo(code: 'TO', nameAr: 'تونغا', nameEn: 'Tonga'),
  'TV': TeamInfo(code: 'TV', nameAr: 'توفالو', nameEn: 'Tuvalu'),
  'VU': TeamInfo(code: 'VU', nameAr: 'فانواتو', nameEn: 'Vanuatu'),
};

/// Total number of countries available in the catalog.
int get catalogCount => _catalog.length;

/// All countries, sorted by Arabic name (used by the admin match picker).
List<TeamInfo> allTeams() {
  final list = _catalog.values.toList();
  list.sort((a, b) => a.nameAr.compareTo(b.nameAr));
  return list;
}

TeamInfo resolveTeam({
  required String code,
  String? nameAr,
  String? nameEn,
}) {
  final key = code.toUpperCase();
  final info = _catalog[key];
  if (info != null) {
    return TeamInfo(
      code: key,
      nameAr: nameAr ?? info.nameAr,
      nameEn: nameEn ?? info.nameEn,
      flagSlug: info.flagSlug,
    );
  }
  // Unknown code: still derive a flag if it looks like an ISO alpha-2 code.
  return TeamInfo(
    code: key,
    nameAr: nameAr ?? code,
    nameEn: nameEn ?? code,
  );
}

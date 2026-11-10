/// Each language in its own name, so the list reads the same in any app
/// language. Unknown codes show as the code itself.
const _endonyms = <String, String>{
  'af': 'Afrikaans', 'am': 'አማርኛ', 'ar': 'العربية', 'as': 'অসমীয়া', 'az': 'Azərbaycan', //
  'ba': 'Башҡорт', 'be': 'Беларуская', 'bg': 'Български', 'bn': 'বাংলা', 'bo': 'བོད་སྐད', //
  'br': 'Brezhoneg', 'bs': 'Bosanski', 'ca': 'Català', 'cs': 'Čeština', 'cy': 'Cymraeg', //
  'da': 'Dansk', 'de': 'Deutsch', 'el': 'Ελληνικά', 'en': 'English', 'es': 'Español', //
  'et': 'Eesti', 'eu': 'Euskara', 'fa': 'فارسی', 'fi': 'Suomi', 'fo': 'Føroyskt', //
  'fr': 'Français', 'gl': 'Galego', 'gu': 'ગુજરાતી', 'ha': 'Hausa', 'haw': 'ʻŌlelo Hawaiʻi', //
  'he': 'עברית', 'hi': 'हिन्दी', 'hr': 'Hrvatski', 'ht': 'Kreyòl ayisyen', 'hu': 'Magyar', //
  'hy': 'Հայերեն', 'id': 'Bahasa Indonesia', 'is': 'Íslenska', 'it': 'Italiano', //
  'ja': '日本語', 'jw': 'Basa Jawa', 'ka': 'ქართული', 'kk': 'Қазақ', 'km': 'ខ្មែរ', //
  'kn': 'ಕನ್ನಡ', 'ko': '한국어', 'la': 'Latina', 'lb': 'Lëtzebuergesch', 'ln': 'Lingála', //
  'lo': 'ລາວ', 'lt': 'Lietuvių', 'lv': 'Latviešu', 'mg': 'Malagasy', 'mi': 'Māori', //
  'mk': 'Македонски', 'ml': 'മലയാളം', 'mn': 'Монгол', 'mr': 'मराठी', 'ms': 'Bahasa Melayu', //
  'mt': 'Malti', 'my': 'မြန်မာ', 'ne': 'नेपाली', 'nl': 'Nederlands', 'nn': 'Nynorsk', //
  'no': 'Norsk', 'oc': 'Occitan', 'pa': 'ਪੰਜਾਬੀ', 'pl': 'Polski', 'ps': 'پښتو', //
  'pt': 'Português', 'ro': 'Română', 'ru': 'Русский', 'sa': 'संस्कृतम्', 'sd': 'سنڌي', //
  'si': 'සිංහල', 'sk': 'Slovenčina', 'sl': 'Slovenščina', 'sn': 'chiShona', 'so': 'Soomaali', //
  'sq': 'Shqip', 'sr': 'Српски', 'su': 'Basa Sunda', 'sv': 'Svenska', 'sw': 'Kiswahili', //
  'ta': 'தமிழ்', 'te': 'తెలుగు', 'tg': 'Тоҷикӣ', 'th': 'ไทย', 'tk': 'Türkmen', //
  'tl': 'Tagalog', 'tr': 'Türkçe', 'tt': 'Татар', 'uk': 'Українська', 'ur': 'اردو', //
  'uz': 'Oʻzbek', 'vi': 'Tiếng Việt', 'yi': 'ייִדיש', 'yo': 'Yorùbá', 'yue': '粵語', //
  'zh': '中文',
};

String languageName(String code) => _endonyms[code] ?? code;

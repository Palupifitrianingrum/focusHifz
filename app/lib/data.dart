import 'dart:math';

// Periksa kembali teks ayat dengan mushaf sebelum dipakai serius.

class Surah {
  final String n;
  final List<String> a;
  const Surah(this.n, this.a);
}

class Verse {
  final int s;
  final int n;
  final String t;
  const Verse(this.s, this.n, this.t);
}

const List<Surah> surahs = [
  Surah('Al-Fatihah', [
    'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
    'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
    'الرَّحْمَٰنِ الرَّحِيمِ',
    'مَالِكِ يَوْمِ الدِّينِ',
    'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
    'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ',
    'صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ',
  ]),
  Surah('Al-Ikhlas', [
    'قُلْ هُوَ ٱللَّهُ أَحَدٌ',
    'ٱللَّهُ ٱلصَّمَدُ',
    'لَمْ يَلِدْ وَلَمْ يُولَدْ',
    'وَلَمْ يَكُن لَّهُۥ كُفُوًا أَحَدٌۢ',
  ]),
  Surah('Al-Falaq', [
    'قُلْ أَعُوذُ بِرَبِّ ٱلْفَلَقِ',
    'مِن شَرِّ مَا خَلَقَ',
    'وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ',
    'وَمِن شَرِّ ٱلنَّفَّٰثَٰتِ فِى ٱلْعُقَدِ',
    'وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ',
  ]),
  Surah('An-Nas', [
    'قُلْ أَعُوذُ بِرَبِّ ٱلنَّاسِ',
    'مَلِكِ ٱلنَّاسِ',
    'إِلَٰهِ ٱلنَّاسِ',
    'مِن شَرِّ ٱلْوَسْوَاسِ ٱلْخَنَّاسِ',
    'ٱلَّذِى يُوَسْوِسُ فِى صُدُورِ ٱلنَّاسِ',
    'مِنَ ٱلْجِنَّةِ وَٱلنَّاسِ',
  ]),
  Surah('Al-Kautsar', [
    'إِنَّآ أَعْطَيْنَٰكَ ٱلْكَوْثَرَ',
    'فَصَلِّ لِرَبِّكَ وَٱنْحَرْ',
    'إِنَّ شَانِئَكَ هُوَ ٱلْأَبْتَرُ',
  ]),
];

final List<Verse> verses = [
  for (var i = 0; i < surahs.length; i++)
    for (var j = 0; j < surahs[i].a.length; j++) Verse(i, j + 1, surahs[i].a[j]),
];

class Hukum {
  final String q, t, r;
  const Hukum(this.q, this.t, this.r);
}

const List<Hukum> hukumList = [
  Hukum('Lam pada "ال" di kata ini dibaca…', 'الْحَمْدُ', 'Alif Lam Qamariyah'),
  Hukum('Lam pada "ال" di kata ini dibaca…', 'الرَّحْمَٰنِ', 'Alif Lam Syamsiyah'),
  Hukum('Nun sukun bertemu huruf ع. Hukumnya…', 'أَنْعَمْتَ', 'Izhar Halqi'),
  Hukum('Huruf د yang sukun di kata ini dibaca…', 'لَمْ يَلِدْ', 'Qalqalah'),
  Hukum('Mad pada alif sebelum lam bertasydid di kata ini disebut…', 'الضَّالِّينَ', 'Mad Lazim'),
];

const List<String> hukumPilihan = [
  'Alif Lam Qamariyah',
  'Alif Lam Syamsiyah',
  'Izhar Halqi',
  'Qalqalah',
  'Mad Lazim',
  'Ikhfa',
];

const List<List<String>> tajwid = [
  ['Alif Lam Qamariyah', 'Lam pada "ال" dibaca jelas bila diikuti huruf qamariyah, mis. ح, ع, ك, م. Contoh: الْحَمْدُ.'],
  ['Alif Lam Syamsiyah', 'Lam melebur ke huruf sesudahnya bila diikuti huruf syamsiyah, mis. ر, ص, ض, ت. Contoh: الرَّحْمَٰنِ.'],
  ['Izhar Halqi', 'Nun sukun/tanwin bertemu huruf halq (ء ه ع ح غ خ) dibaca jelas tanpa dengung. Contoh: أَنْعَمْتَ.'],
  ['Qalqalah', 'Huruf ق ط ب ج د yang sukun dibunyikan memantul. Contoh: يَلِدْ.'],
  ['Mad Lazim', 'Huruf mad diikuti sukun asli atau tasydid dalam satu kata, dipanjangkan 6 harakat. Contoh: الضَّالِّينَ.'],
  ['Ikhfa', 'Nun sukun/tanwin bertemu 15 huruf ikhfa dibaca samar disertai dengung.'],
];

final Random rng = Random();
T rnd<T>(List<T> l) => l[rng.nextInt(l.length)];
List<T> shuf<T>(Iterable<T> it) => it.toList()..shuffle(rng);
List<String> words(String t) => t.split(' ');

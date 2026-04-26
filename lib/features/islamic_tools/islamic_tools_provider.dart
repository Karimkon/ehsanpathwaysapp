import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:ehsan_pathways/config/app_config.dart';

// ---------------------------------------------------------------------------
// Shared Dio (no auth needed — static data)
// ---------------------------------------------------------------------------
final _isToolsDioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(milliseconds: AppConfig.connectTimeout),
    receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeout),
    headers: {'Accept': 'application/json'},
  ));
});

// Separate Dio for alquran.cloud (different baseUrl)
final _quranCloudDioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    baseUrl: 'https://api.alquran.cloud/v1',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Accept': 'application/json'},
  ));
});

// ===========================================================================
// QURAN MODELS
// ===========================================================================

class Surah {
  final int no;
  final String name;
  final String arabic;
  final int verses;
  final String type;
  final String meaning;

  const Surah({
    required this.no,
    required this.name,
    required this.arabic,
    required this.verses,
    required this.type,
    required this.meaning,
  });

  factory Surah.fromJson(Map<String, dynamic> j) => Surah(
        no: (j['no'] as num).toInt(),
        name: j['name'] as String? ?? '',
        arabic: j['arabic'] as String? ?? '',
        verses: (j['verses'] as num?)?.toInt() ?? 0,
        type: j['type'] as String? ?? '',
        meaning: j['meaning'] as String? ?? '',
      );
}

// ---------------------------------------------------------------------------
// Quran providers
// ---------------------------------------------------------------------------

final quranSurahsProvider = FutureProvider<List<Surah>>((ref) async {
  final dio = ref.read(_isToolsDioProvider);
  final res = await dio.get('/islamic-tools/quran/surahs');
  final data = res.data as Map<String, dynamic>;
  return (data['data'] as List)
      .map((e) => Surah.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ===========================================================================
// QURAN VERSE MODEL
// ===========================================================================

class QuranVerse {
  final int number;       // verse number within surah
  final String arabic;
  final String translation;

  const QuranVerse({
    required this.number,
    required this.arabic,
    required this.translation,
  });
}

/// Fetches Arabic + English translation from alquran.cloud
final quranVersesProvider =
    FutureProvider.family<List<QuranVerse>, int>((ref, surahNo) async {
  final dio = ref.read(_quranCloudDioProvider);
  final res = await dio.get('/surah/$surahNo/editions/quran-simple,en.sahih');
  final editions = (res.data['data'] as List).cast<Map<String, dynamic>>();
  // editions[0] = Arabic, editions[1] = English
  final arabicAyahs = (editions[0]['ayahs'] as List).cast<Map<String, dynamic>>();
  final englishAyahs = (editions[1]['ayahs'] as List).cast<Map<String, dynamic>>();

  return List.generate(arabicAyahs.length, (i) {
    return QuranVerse(
      number: (arabicAyahs[i]['numberInSurah'] as num).toInt(),
      arabic: arabicAyahs[i]['text'] as String,
      translation: englishAyahs[i]['text'] as String,
    );
  });
});

// ===========================================================================
// HADITH MODELS
// ===========================================================================

class HadithCollection {
  final String id;
  final String name;
  final String arabic;
  final int count;
  final String desc;
  final String color;

  const HadithCollection({
    required this.id,
    required this.name,
    required this.arabic,
    required this.count,
    required this.desc,
    required this.color,
  });

  factory HadithCollection.fromJson(Map<String, dynamic> j) =>
      HadithCollection(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        arabic: j['arabic'] as String? ?? '',
        count: (j['count'] as num?)?.toInt() ?? 0,
        desc: j['desc'] as String? ?? '',
        color: j['color'] as String? ?? 'green',
      );
}

class HadithItem {
  final int no;
  final String arabic;
  final String english;
  final String narrator;
  final String ref;
  final String topic;

  const HadithItem({
    required this.no,
    required this.arabic,
    required this.english,
    required this.narrator,
    required this.ref,
    required this.topic,
  });

  factory HadithItem.fromJson(Map<String, dynamic> j) => HadithItem(
        no: (j['no'] as num).toInt(),
        arabic: j['arabic'] as String? ?? '',
        english: j['english'] as String? ?? '',
        narrator: j['narrator'] as String? ?? '',
        ref: j['ref'] as String? ?? '',
        topic: j['topic'] as String? ?? '',
      );
}

// ---------------------------------------------------------------------------
// Hadith providers
// ---------------------------------------------------------------------------

final hadithCollectionsProvider =
    FutureProvider<List<HadithCollection>>((ref) async {
  final dio = ref.read(_isToolsDioProvider);
  final res = await dio.get('/islamic-tools/hadith/collections');
  return (res.data['data'] as List)
      .map((e) => HadithCollection.fromJson(e as Map<String, dynamic>))
      .toList();
});

final hadithCollectionProvider =
    FutureProvider.family<List<HadithItem>, String>((ref, id) async {
  final dio = ref.read(_isToolsDioProvider);
  final res = await dio.get('/islamic-tools/hadith/$id');
  final data = res.data['data'] as Map<String, dynamic>;
  return (data['hadiths'] as List)
      .map((e) => HadithItem.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ===========================================================================
// DUA MODELS
// ===========================================================================

class DuaCategory {
  final String id;
  final String name;
  final String arabic;
  final String icon;
  final String color;
  final int count;
  final String desc;

  const DuaCategory({
    required this.id,
    required this.name,
    required this.arabic,
    required this.icon,
    required this.color,
    required this.count,
    required this.desc,
  });

  factory DuaCategory.fromJson(Map<String, dynamic> j) => DuaCategory(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        arabic: j['arabic'] as String? ?? '',
        icon: j['icon'] as String? ?? '🤲',
        color: j['color'] as String? ?? 'green',
        count: (j['count'] as num?)?.toInt() ?? 0,
        desc: j['desc'] as String? ?? '',
      );
}

class DuaItem {
  final String title;
  final String arabic;
  final String latin;
  final String english;
  final String ref;
  final String count; // display string e.g. "3x after Fajr"

  const DuaItem({
    required this.title,
    required this.arabic,
    required this.latin,
    required this.english,
    required this.ref,
    required this.count,
  });

  factory DuaItem.fromJson(Map<String, dynamic> j) => DuaItem(
        title: j['title'] as String? ?? '',
        arabic: j['arabic'] as String? ?? '',
        latin: j['latin'] as String? ?? '',
        english: j['english'] as String? ?? '',
        ref: j['ref'] as String? ?? '',
        count: j['count']?.toString() ?? '',
      );
}

/// Wraps the API response for a single dua category (category meta + duas list)
class DuaCategoryData {
  final DuaCategory category;
  final List<DuaItem> duas;
  const DuaCategoryData({required this.category, required this.duas});
}

// ---------------------------------------------------------------------------
// Dua providers
// ---------------------------------------------------------------------------

final duaCategoriesProvider =
    FutureProvider<List<DuaCategory>>((ref) async {
  final dio = ref.read(_isToolsDioProvider);
  final res = await dio.get('/islamic-tools/dua/categories');
  return (res.data['data'] as List)
      .map((e) => DuaCategory.fromJson(e as Map<String, dynamic>))
      .toList();
});

final duaCategoryProvider =
    FutureProvider.family<DuaCategoryData, String>((ref, catId) async {
  final dio = ref.read(_isToolsDioProvider);
  final res = await dio.get('/islamic-tools/dua/$catId');
  final data = res.data['data'] as Map<String, dynamic>;
  final category =
      DuaCategory.fromJson(data['category'] as Map<String, dynamic>);
  final duas = (data['duas'] as List)
      .map((e) => DuaItem.fromJson(e as Map<String, dynamic>))
      .toList();
  return DuaCategoryData(category: category, duas: duas);
});

// ===========================================================================
// HIFZ TRACKER (SharedPreferences-based)
// ===========================================================================

enum HifzStatus { notStarted, inProgress, memorised }

class HifzSurah {
  final int no;
  final String name;
  final String arabic;
  final int juz;
  final int verses;
  final HifzStatus status;

  const HifzSurah({
    required this.no,
    required this.name,
    required this.arabic,
    required this.juz,
    required this.verses,
    this.status = HifzStatus.notStarted,
  });

  HifzSurah copyWith({HifzStatus? status}) => HifzSurah(
        no: no,
        name: name,
        arabic: arabic,
        juz: juz,
        verses: verses,
        status: status ?? this.status,
      );
}

class HifzState {
  final List<HifzSurah> surahs;
  final bool isLoading;

  const HifzState({this.surahs = const [], this.isLoading = true});

  int get memorisedCount =>
      surahs.where((s) => s.status == HifzStatus.memorised).length;
  int get inProgressCount =>
      surahs.where((s) => s.status == HifzStatus.inProgress).length;
  int get notStartedCount =>
      surahs.where((s) => s.status == HifzStatus.notStarted).length;
  double get percentage => surahs.isEmpty ? 0 : memorisedCount / surahs.length * 100;
}

class HifzNotifier extends Notifier<HifzState> {
  static const _prefKey = 'ehsan_hifz_progress';

  @override
  HifzState build() {
    _load();
    return const HifzState();
  }

  static List<HifzSurah> _staticSurahs() {
    // Juz 30 mini-list from 78-114; full list below
    const raw = [
      (1,'Al-Fatihah','الفاتحة',1,7),(2,'Al-Baqarah','البقرة',1,286),(3,'Ali Imran','آل عمران',3,200),(4,'An-Nisa','النساء',4,176),(5,'Al-Maidah','المائدة',6,120),
      (6,'Al-Anam','الأنعام',7,165),(7,'Al-Araf','الأعراف',8,206),(8,'Al-Anfal','الأنفال',9,75),(9,'At-Tawbah','التوبة',10,129),(10,'Yunus','يونس',11,109),
      (11,'Hud','هود',11,123),(12,'Yusuf','يوسف',12,111),(13,'Ar-Rad','الرعد',13,43),(14,'Ibrahim','إبراهيم',13,52),(15,'Al-Hijr','الحجر',14,99),
      (16,'An-Nahl','النحل',14,128),(17,'Al-Isra','الإسراء',15,111),(18,'Al-Kahf','الكهف',15,110),(19,'Maryam','مريم',16,98),(20,'Ta-Ha','طه',16,135),
      (21,'Al-Anbiya','الأنبياء',17,112),(22,'Al-Hajj','الحج',17,78),(23,'Al-Muminun','المؤمنون',18,118),(24,'An-Nur','النور',18,64),(25,'Al-Furqan','الفرقان',18,77),
      (26,'Ash-Shuara','الشعراء',19,227),(27,'An-Naml','النمل',19,93),(28,'Al-Qasas','القصص',20,88),(29,'Al-Ankabut','العنكبوت',20,69),(30,'Ar-Rum','الروم',21,60),
      (31,'Luqman','لقمان',21,34),(32,'As-Sajdah','السجدة',21,30),(33,'Al-Ahzab','الأحزاب',21,73),(34,'Saba','سبأ',22,54),(35,'Fatir','فاطر',22,45),
      (36,'Ya-Sin','يس',22,83),(37,'As-Saffat','الصافات',23,182),(38,'Sad','ص',23,88),(39,'Az-Zumar','الزمر',23,75),(40,'Ghafir','غافر',24,85),
      (41,'Fussilat','فصلت',24,54),(42,'Ash-Shura','الشورى',25,53),(43,'Az-Zukhruf','الزخرف',25,89),(44,'Ad-Dukhan','الدخان',25,59),(45,'Al-Jathiyah','الجاثية',25,37),
      (46,'Al-Ahqaf','الأحقاف',26,35),(47,'Muhammad','محمد',26,38),(48,'Al-Fath','الفتح',26,29),(49,'Al-Hujurat','الحجرات',26,18),(50,'Qaf','ق',26,45),
      (51,'Adh-Dhariyat','الذاريات',26,60),(52,'At-Tur','الطور',27,49),(53,'An-Najm','النجم',27,62),(54,'Al-Qamar','القمر',27,55),(55,'Ar-Rahman','الرحمن',27,78),
      (56,'Al-Waqiah','الواقعة',27,96),(57,'Al-Hadid','الحديد',27,29),(58,'Al-Mujadilah','المجادلة',28,22),(59,'Al-Hashr','الحشر',28,24),(60,'Al-Mumtahanah','الممتحنة',28,13),
      (61,'As-Saf','الصف',28,14),(62,'Al-Jumuah','الجمعة',28,11),(63,'Al-Munafiqun','المنافقون',28,11),(64,'At-Taghabun','التغابن',28,18),(65,'At-Talaq','الطلاق',28,12),
      (66,'At-Tahrim','التحريم',28,12),(67,'Al-Mulk','الملك',29,30),(68,'Al-Qalam','القلم',29,52),(69,'Al-Haqqah','الحاقة',29,52),(70,'Al-Maarij','المعارج',29,44),
      (71,'Nuh','نوح',29,28),(72,'Al-Jinn','الجن',29,28),(73,'Al-Muzzammil','المزمل',29,20),(74,'Al-Muddaththir','المدثر',29,56),(75,'Al-Qiyamah','القيامة',29,40),
      (76,'Al-Insan','الإنسان',29,31),(77,'Al-Mursalat','المرسلات',29,50),(78,'An-Naba','النبأ',30,40),(79,'An-Naziat','النازعات',30,46),(80,'Abasa','عبس',30,42),
      (81,'At-Takwir','التكوير',30,29),(82,'Al-Infitar','الانفطار',30,19),(83,'Al-Mutaffifin','المطففين',30,36),(84,'Al-Inshiqaq','الانشقاق',30,25),(85,'Al-Buruj','البروج',30,22),
      (86,'At-Tariq','الطارق',30,17),(87,'Al-Ala','الأعلى',30,19),(88,'Al-Ghashiyah','الغاشية',30,26),(89,'Al-Fajr','الفجر',30,30),(90,'Al-Balad','البلد',30,20),
      (91,'Ash-Shams','الشمس',30,15),(92,'Al-Layl','الليل',30,21),(93,'Ad-Duha','الضحى',30,11),(94,'Ash-Sharh','الشرح',30,8),(95,'At-Tin','التين',30,8),
      (96,'Al-Alaq','العلق',30,19),(97,'Al-Qadr','القدر',30,5),(98,'Al-Bayyinah','البينة',30,8),(99,'Az-Zalzalah','الزلزلة',30,8),(100,'Al-Adiyat','العاديات',30,11),
      (101,'Al-Qariah','القارعة',30,11),(102,'At-Takathur','التكاثر',30,8),(103,'Al-Asr','العصر',30,3),(104,'Al-Humazah','الهمزة',30,9),(105,'Al-Fil','الفيل',30,5),
      (106,'Quraysh','قريش',30,4),(107,'Al-Maun','الماعون',30,7),(108,'Al-Kawthar','الكوثر',30,3),(109,'Al-Kafirun','الكافرون',30,6),(110,'An-Nasr','النصر',30,3),
      (111,'Al-Masad','المسد',30,5),(112,'Al-Ikhlas','الإخلاص',30,4),(113,'Al-Falaq','الفلق',30,5),(114,'An-Nas','الناس',30,6),
    ];
    return raw
        .map((r) => HifzSurah(no: r.$1, name: r.$2, arabic: r.$3, juz: r.$4, verses: r.$5))
        .toList();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    Map<String, dynamic> progressMap = {};
    if (saved != null) {
      try {
        progressMap = json.decode(saved) as Map<String, dynamic>;
      } catch (_) {}
    }

    final surahs = _staticSurahs().map((s) {
      final statusStr = progressMap[s.no.toString()] as String?;
      final status = switch (statusStr) {
        'memorised' => HifzStatus.memorised,
        'inprogress' => HifzStatus.inProgress,
        _ => HifzStatus.notStarted,
      };
      return s.copyWith(status: status);
    }).toList();

    state = HifzState(surahs: surahs, isLoading: false);
  }

  Future<void> setStatus(int surahNo, HifzStatus status) async {
    final updated = state.surahs.map((s) {
      if (s.no == surahNo) return s.copyWith(status: status);
      return s;
    }).toList();
    state = HifzState(surahs: updated, isLoading: false);

    // Persist
    final prefs = await SharedPreferences.getInstance();
    final map = {
      for (final s in updated) s.no.toString(): switch (s.status) {
          HifzStatus.memorised => 'memorised',
          HifzStatus.inProgress => 'inprogress',
          HifzStatus.notStarted => 'notstarted',
        }
    };
    await prefs.setString(_prefKey, json.encode(map));
  }

  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    await _load();
  }
}

final hifzProvider = NotifierProvider<HifzNotifier, HifzState>(HifzNotifier.new);

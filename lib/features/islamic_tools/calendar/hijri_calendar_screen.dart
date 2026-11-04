import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/shared/widgets/reading_width.dart';

/// Hijri months in Arabic, 1-12.
const kHijriMonthsArabic = [
  'مُحَرَّم',
  'صَفَر',
  'رَبِيع الأَوَّل',
  'رَبِيع الآخِر',
  'جُمَادَى الأُولَى',
  'جُمَادَى الآخِرَة',
  'رَجَب',
  'شَعْبَان',
  'رَمَضَان',
  'شَوَّال',
  'ذُو القَعْدَة',
  'ذُو الحِجَّة',
];

const kHijriMonthsEnglish = [
  'Muharram',
  'Safar',
  "Rabi' al-Awwal",
  "Rabi' al-Akhir",
  'Jumada al-Ula',
  'Jumada al-Akhirah',
  'Rajab',
  "Sha'ban",
  'Ramadan',
  'Shawwal',
  "Dhul-Qa'dah",
  'Dhul-Hijjah',
];

/// Days with an established basis in the Sunnah. Kept deliberately to dates
/// on which there is broad agreement.
String? hijriObservance(int month, int day) {
  if (day >= 13 && day <= 15 && !(month == 12 && day == 13)) {
    // Ayyam al-Bid; in Dhul-Hijjah the 13th is a day of Tashreeq instead.
    if (!(month == 9)) return 'The White Days: Sunnah to fast';
  }
  return switch ((month, day)) {
    (1, 1) => 'Islamic New Year',
    (1, 9) => "Tasu'a: Sunnah to fast with 'Ashura",
    (1, 10) => "'Ashura: Sunnah to fast",
    (9, 1) => 'First day of Ramadan',
    (9, >= 21) when day <= 30 => 'The last ten nights of Ramadan',
    (10, 1) => 'Eid al-Fitr',
    (12, >= 1) when day <= 7 => 'The first ten days of Dhul-Hijjah',
    (12, 8) => 'Day of Tarwiyah',
    (12, 9) => "Day of 'Arafah: Sunnah to fast",
    (12, 10) => 'Eid al-Adha',
    (12, >= 11) when day <= 13 => 'Days of Tashreeq',
    _ => null,
  };
}

/// Hijri calendar on the Umm al-Qura tables, with an adjustment of up to two
/// days either way for regions that follow local moon sighting.
class HijriCalendarScreen extends StatefulWidget {
  const HijriCalendarScreen({super.key});

  @override
  State<HijriCalendarScreen> createState() => _HijriCalendarScreenState();
}

class _HijriCalendarScreenState extends State<HijriCalendarScreen> {
  static const _adjustKey = 'hijri_adjust_days';

  int _adjust = 0;
  late int _year;
  late int _month;

  HijriCalendar _hijriFor(DateTime d) =>
      HijriCalendar.fromDate(d.add(Duration(days: _adjust)));

  @override
  void initState() {
    super.initState();
    final today = _hijriFor(DateTime.now());
    _year = today.hYear;
    _month = today.hMonth;
    _loadAdjust();
  }

  Future<void> _loadAdjust() async {
    try {
      final v = (await SharedPreferences.getInstance()).getInt(_adjustKey) ?? 0;
      if (!mounted || v == _adjust) return;
      setState(() {
        _adjust = v.clamp(-2, 2);
        final today = _hijriFor(DateTime.now());
        _year = today.hYear;
        _month = today.hMonth;
      });
    } catch (_) {}
  }

  Future<void> _setAdjust(int v) async {
    setState(() {
      _adjust = v;
      final today = _hijriFor(DateTime.now());
      _year = today.hYear;
      _month = today.hMonth;
    });
    try {
      await (await SharedPreferences.getInstance()).setInt(_adjustKey, v);
    } catch (_) {}
  }

  void _shiftMonth(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      var m = _month + delta, y = _year;
      if (m < 1) {
        m = 12;
        y--;
      } else if (m > 12) {
        m = 1;
        y++;
      }
      _month = m;
      _year = y;
    });
  }

  /// Gregorian date of a Hijri day, honouring the adjustment.
  DateTime _gregorianOf(int y, int m, int d) => HijriCalendar()
      .hijriToGregorian(y, m, d)
      .subtract(Duration(days: _adjust));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final today = _hijriFor(now);
    final todayNote = hijriObservance(today.hMonth, today.hDay);

    final daysInMonth = HijriCalendar().getDaysInMonth(_year, _month);
    final first = _gregorianOf(_year, _month, 1);
    final leading = first.weekday % 7; // Sunday-first grid

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 236 + MediaQuery.paddingOf(context).top,
            backgroundColor: AppColors.emerald900,
            foregroundColor: Colors.white,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            title: const Text('Hijri Calendar'),
            flexibleSpace: FlexibleSpaceBar(
              background: DecoratedBox(
                decoration: const BoxDecoration(gradient: AppGradients.emerald),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                    child: FitHeader(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${today.hDay} ${kHijriMonthsArabic[today.hMonth - 1]} ${today.hYear}',
                            textDirection: TextDirection.rtl,
                            style: AppTheme.arabic(
                              size: 30,
                              weight: FontWeight.w700,
                              color: AppColors.goldLight,
                              height: 1.5,
                            ),
                          ),
                          Text(
                            '${today.hDay} ${kHijriMonthsEnglish[today.hMonth - 1]} ${today.hYear} AH',
                            style: AppTheme.ui(
                              size: 16,
                              weight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEEE, d MMMM y').format(now),
                            style: AppTheme.ui(
                              size: 13,
                              weight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          if (todayNote != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.6),
                                ),
                              ),
                              child: Text(
                                todayNote,
                                style: AppTheme.ui(
                                  size: 12,
                                  color: AppColors.goldPale,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: readingInsets(
              context,
              horizontal: 16,
              top: 16,
              bottom: 32,
              maxWidth: 640,
            ),
            sliver: SliverList.list(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Previous month',
                      onPressed: () => _shiftMonth(-1),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${kHijriMonthsEnglish[_month - 1]} $_year',
                            style: AppTheme.ui(
                              size: 17,
                              weight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${DateFormat('MMM y').format(first)} – '
                            '${DateFormat('MMM y').format(first.add(Duration(days: daysInMonth - 1)))}',
                            style: AppTheme.ui(
                              size: 12,
                              weight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.onDarkMuted
                                  : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Next month',
                      onPressed: () => _shiftMonth(1),
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final d in [
                      'Sun',
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat',
                    ])
                      Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: AppTheme.ui(
                              size: 11.5,
                              weight: FontWeight.w700,
                              color: d == 'Fri'
                                  ? (isDark
                                        ? AppColors.gold
                                        : AppColors.goldDeep)
                                  : (isDark
                                        ? AppColors.onDarkMuted
                                        : AppColors.muted),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemCount: leading + daysInMonth,
                  itemBuilder: (context, i) {
                    if (i < leading) return const SizedBox.shrink();
                    final day = i - leading + 1;
                    final greg = first.add(Duration(days: day - 1));
                    final isToday =
                        _year == today.hYear &&
                        _month == today.hMonth &&
                        day == today.hDay;
                    final note = hijriObservance(_month, day);
                    return _DayCell(
                      hijriDay: day,
                      gregorianDay: greg.day,
                      isToday: isToday,
                      marked: note != null,
                      onTap: note == null
                          ? null
                          : () => ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '$day ${kHijriMonthsEnglish[_month - 1]}: $note',
                                ),
                              ),
                            ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DATE ADJUSTMENT',
                          style: AppTheme.eyebrow(
                            isDark ? AppColors.onDarkMuted : AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Dates follow the Umm al-Qura calendar. If your community '
                          'begins the month by local moon sighting, adjust by a day or two.',
                          style: AppTheme.ui(
                            size: 13,
                            weight: FontWeight.w500,
                            height: 1.45,
                            color: isDark
                                ? AppColors.onDarkMuted
                                : AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<int>(
                            segments: [
                              for (final v in [-2, -1, 0, 1, 2])
                                ButtonSegment(
                                  value: v,
                                  label: Text(v > 0 ? '+$v' : '$v'),
                                ),
                            ],
                            selected: {_adjust},
                            showSelectedIcon: false,
                            onSelectionChanged: (s) => _setAdjust(s.first),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.hijriDay,
    required this.gregorianDay,
    required this.isToday,
    required this.marked,
    this.onTap,
  });

  final int hijriDay;
  final int gregorianDay;
  final bool isToday;
  final bool marked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isToday
        ? AppColors.emerald900
        : (isDark ? AppColors.slateCard : AppColors.card);
    final fg = isToday
        ? Colors.white
        : (isDark ? AppColors.onDark : AppColors.ink);
    return Semantics(
      label:
          'Hijri day $hijriDay, Gregorian $gregorianDay${marked ? ', observance' : ''}',
      button: onTap != null,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isToday || marked
                    ? AppColors.gold
                    : (isDark ? AppColors.slateLine : AppColors.sand),
                width: isToday || marked ? 1.4 : 1,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$hijriDay',
                      style: AppTheme.ui(
                        size: 16,
                        weight: FontWeight.w800,
                        color: fg,
                      ),
                    ),
                    Text(
                      '$gregorianDay',
                      style: AppTheme.ui(
                        size: 10.5,
                        weight: FontWeight.w600,
                        color: isToday
                            ? AppColors.goldLight
                            : (isDark
                                  ? AppColors.onDarkSubtle
                                  : AppColors.subtle),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

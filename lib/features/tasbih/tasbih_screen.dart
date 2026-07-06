import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _green = Color(0xFF16A34A);
const _greenDark = Color(0xFF15803D);
const _gold = Color(0xFFF59E0B);

/// A single dhikr phrase the user can count.
class _Dhikr {
  final String arabic;
  final String transliteration;
  final String meaning;
  final int target;

  const _Dhikr(this.arabic, this.transliteration, this.meaning, this.target);
}

const _dhikrList = <_Dhikr>[
  _Dhikr('سُبْحَانَ اللَّه', 'SubhanAllah', 'Glory be to Allah', 33),
  _Dhikr('الْحَمْدُ لِلَّه', 'Alhamdulillah', 'All praise is to Allah', 33),
  _Dhikr('اللَّهُ أَكْبَر', 'Allahu Akbar', 'Allah is the Greatest', 34),
  _Dhikr('لَا إِلَٰهَ إِلَّا اللَّه', 'La ilaha illAllah',
      'There is no god but Allah', 100),
  _Dhikr('أَسْتَغْفِرُ اللَّه', 'Astaghfirullah',
      'I seek forgiveness from Allah', 100),
];

/// Digital Tasbih (dhikr counter) with haptic feedback, selectable dhikr,
/// per-dhikr targets, round tracking, and a persisted lifetime total.
class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  int _dhikrIndex = 0;
  int _count = 0;
  int _rounds = 0;
  int _lifetime = 0;

  static const _kLifetimeKey = 'tasbih_lifetime_total';

  _Dhikr get _current => _dhikrList[_dhikrIndex];

  @override
  void initState() {
    super.initState();
    _loadLifetime();
  }

  Future<void> _loadLifetime() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _lifetime = prefs.getInt(_kLifetimeKey) ?? 0);
    }
  }

  Future<void> _persistLifetime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLifetimeKey, _lifetime);
  }

  void _increment() {
    HapticFeedback.lightImpact();
    setState(() {
      _count++;
      _lifetime++;
      if (_count >= _current.target) {
        _rounds++;
        _count = 0;
        HapticFeedback.mediumImpact();
      }
    });
    _persistLifetime();
  }

  void _reset() {
    HapticFeedback.selectionClick();
    setState(() {
      _count = 0;
      _rounds = 0;
    });
  }

  void _selectDhikr(int index) {
    setState(() {
      _dhikrIndex = index;
      _count = 0;
      _rounds = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = _count / _current.target;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('Tasbih',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Reset',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _reset,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Dhikr selector chips
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _dhikrList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final selected = i == _dhikrIndex;
                  return GestureDetector(
                    onTap: () => _selectDhikr(i),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: selected
                            ? _green
                            : (isDark ? const Color(0xFF1A1A1A) : Colors.white),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: selected
                              ? _green
                              : Colors.grey.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        _dhikrList[i].transliteration,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : (isDark ? Colors.white70 : const Color(0xFF374151)),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Current dhikr text
            Text(
              _current.arabic,
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: isDark ? _gold : _greenDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _current.meaning,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.white54 : const Color(0xFF6B7280),
              ),
            ),
            const Spacer(),
            // Big tappable counter
            GestureDetector(
              onTap: _increment,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_green, _greenDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _green.withValues(alpha: 0.4),
                      blurRadius: 30,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 216,
                      height: 216,
                      child: CircularProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        strokeWidth: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor:
                            const AlwaysStoppedAnimation(_gold),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_count',
                          style: GoogleFonts.inter(
                            fontSize: 68,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        Text(
                          'of ${_current.target}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tap anywhere on the circle to count',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
              ),
            ),
            const Spacer(),
            // Stats row
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  _StatTile(label: 'Rounds', value: '$_rounds', isDark: isDark),
                  const SizedBox(width: 12),
                  _StatTile(
                    label: 'Lifetime',
                    value: '$_lifetime',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _green,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white54 : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

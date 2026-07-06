import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:ehsan_pathways/core/services/prayer_times_service.dart';
import 'package:ehsan_pathways/features/prayer/prayer_provider.dart';
import 'package:ehsan_pathways/shared/widgets/empty_state.dart';

const _green = Color(0xFF16A34A);
const _greenDark = Color(0xFF15803D);
const _gold = Color(0xFFF59E0B);

/// Full prayer-times screen: today's schedule for the user's location, a live
/// "next prayer" countdown, calculation-method selection, and quick access to
/// notification settings.
class PrayerTimesScreen extends ConsumerStatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  ConsumerState<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends ConsumerState<PrayerTimesScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Rebuild every second so the countdown stays live.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _pickMethod(PrayerScheduleData data) async {
    final selected = await showModalBottomSheet<PrayerCalculationMethod>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MethodPicker(current: data.method),
    );
    if (selected == null || selected == data.method) return;

    final settings = await PrayerTimesService.loadSettings();
    await PrayerTimesService.saveSettings(
      enabled: settings['enabled'] as bool? ?? false,
      method: selected,
      prayerToggles: {
        Prayer.fajr: settings['notify_fajr'] as bool? ?? true,
        Prayer.dhuhr: settings['notify_dhuhr'] as bool? ?? true,
        Prayer.asr: settings['notify_asr'] as bool? ?? true,
        Prayer.maghrib: settings['notify_maghrib'] as bool? ?? true,
        Prayer.isha: settings['notify_isha'] as bool? ?? true,
      },
      lat: data.latitude,
      lng: data.longitude,
      city: data.locationLabel,
    );
    ref.invalidate(prayerScheduleProvider);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final async = ref.watch(prayerScheduleProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAF9),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: _green),
        ),
        error: (err, _) => _ErrorView(
          isLocation: err is PrayerLocationException,
          onRetry: () async {
            // Explicit user action → OK to request GPS permission now.
            await resolvePrayerLocation();
            ref.invalidate(prayerScheduleProvider);
          },
        ),
        data: (data) => _Content(
          data: data,
          isDark: isDark,
          onPickMethod: () => _pickMethod(data),
          onRefreshLocation: () async {
            await resolvePrayerLocation();
            ref.invalidate(prayerScheduleProvider);
          },
        ),
      ),
    );
  }
}

// ===========================================================================
// Loaded content
// ===========================================================================

class _Content extends StatelessWidget {
  const _Content({
    required this.data,
    required this.isDark,
    required this.onPickMethod,
    required this.onRefreshLocation,
  });

  final PrayerScheduleData data;
  final bool isDark;
  final VoidCallback onPickMethod;
  final Future<void> Function() onRefreshLocation;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 260,
          backgroundColor: _greenDark,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              tooltip: 'Refresh location',
              icon: const Icon(Icons.my_location_rounded),
              onPressed: onRefreshLocation,
            ),
            IconButton(
              tooltip: 'Calculation method',
              icon: const Icon(Icons.tune_rounded),
              onPressed: onPickMethod,
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            title: const Text(
              'Prayer Times',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            background: _NextPrayerHeader(data: data),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 16, color: _green),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    data.locationLabel,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                    ),
                  ),
                ),
                Text(
                  DateFormat('EEE, d MMM').format(DateTime.now()),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          sliver: SliverList.separated(
            itemCount: data.entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final entry = data.entries[i];
              final isNext = entry.prayer == data.nextPrayer &&
                  entry.prayer != Prayer.sunrise;
              final isCurrent = entry.prayer == data.currentPrayer &&
                  entry.prayer != Prayer.sunrise;
              return _PrayerRow(
                entry: entry,
                isNext: isNext,
                isCurrent: isCurrent,
                isDark: isDark,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// Header with live countdown
// ===========================================================================

class _NextPrayerHeader extends StatelessWidget {
  const _NextPrayerHeader({required this.data});

  final PrayerScheduleData data;

  String _formatRemaining(Duration d) {
    if (d.isNegative) return 'now';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final next = data.nextEntry;
    final remaining = data.nextPrayerTime.difference(DateTime.now());

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_greenDark, Color(0xFF052E16)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 44, 20, 44),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'NEXT PRAYER',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: _gold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                next.arabicName,
                style: GoogleFonts.amiri(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                next.name,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 15, color: _gold),
                    const SizedBox(width: 6),
                    Text(
                      '${PrayerTimesService.formatTime(next.time)}  •  in ${_formatRemaining(remaining)}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Single prayer row
// ===========================================================================

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.entry,
    required this.isNext,
    required this.isCurrent,
    required this.isDark,
  });

  final PrayerEntry entry;
  final bool isNext;
  final bool isCurrent;
  final bool isDark;

  IconData get _icon {
    switch (entry.prayer) {
      case Prayer.fajr:
        return Icons.dark_mode_rounded;
      case Prayer.sunrise:
        return Icons.wb_twilight_rounded;
      case Prayer.dhuhr:
        return Icons.wb_sunny_rounded;
      case Prayer.asr:
        return Icons.wb_cloudy_rounded;
      case Prayer.maghrib:
        return Icons.nightlight_round;
      case Prayer.isha:
        return Icons.bedtime_rounded;
      default:
        return Icons.access_time_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final highlight = isNext;
    final baseColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: highlight
            ? const LinearGradient(colors: [_green, _greenDark])
            : null,
        color: highlight ? null : baseColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight
              ? Colors.transparent
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFE5E7EB)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: highlight
                  ? Colors.white.withValues(alpha: 0.18)
                  : _green.withValues(alpha: isDark ? 0.15 : 0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon,
                size: 20, color: highlight ? Colors.white : _green),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    entry.name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: highlight
                          ? Colors.white
                          : (isDark ? Colors.white : const Color(0xFF111827)),
                    ),
                  ),
                  if (isCurrent && !isNext) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _gold.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'NOW',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: _gold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                entry.arabicName,
                style: GoogleFonts.amiri(
                  fontSize: 14,
                  color: highlight
                      ? Colors.white.withValues(alpha: 0.8)
                      : (isDark ? Colors.white54 : const Color(0xFF9CA3AF)),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            PrayerTimesService.formatTime(entry.time),
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: highlight
                  ? Colors.white
                  : (isDark ? Colors.white : const Color(0xFF111827)),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Calculation-method picker
// ===========================================================================

class _MethodPicker extends StatelessWidget {
  const _MethodPicker({required this.current});

  final PrayerCalculationMethod current;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Calculation Method',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: PrayerCalculationMethod.values.map((m) {
                  final selected = m == current;
                  return ListTile(
                    onTap: () => Navigator.pop(context, m),
                    leading: Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: selected ? _green : Colors.grey,
                    ),
                    title: Text(
                      m.displayName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                    subtitle: Text(
                      m.region,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Error / location-denied view
// ===========================================================================

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.isLocation, required this.onRetry});

  final bool isLocation;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: BackButton(color: Theme.of(context).colorScheme.onSurface),
          ),
          Expanded(
            child: Center(
              child: EmptyState(
                icon: isLocation
                    ? Icons.location_off_rounded
                    : Icons.error_outline_rounded,
                title: isLocation
                    ? 'Location needed'
                    : 'Unable to load prayer times',
                subtitle: isLocation
                    ? 'Enable location access so we can calculate accurate prayer times for your area.'
                    : 'Something went wrong while calculating prayer times. Please try again.',
                actionLabel: isLocation ? 'Enable & Retry' : 'Retry',
                onAction: onRetry,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

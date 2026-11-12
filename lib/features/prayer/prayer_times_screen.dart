import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:ehsan_pathways/core/services/prayer_times_service.dart';
import 'package:ehsan_pathways/features/prayer/prayer_cities.dart';
import 'package:ehsan_pathways/features/prayer/prayer_provider.dart';
import 'package:ehsan_pathways/shared/widgets/reading_width.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/core/json_read.dart';

const _green = AppColors.emerald700;
const _greenDark = AppColors.emerald800;
const _gold = AppColors.gold;

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
      enabled: jBool(settings['enabled']) ?? false,
      method: selected,
      prayerToggles: {
        Prayer.fajr: jBool(settings['notify_fajr']) ?? true,
        Prayer.dhuhr: jBool(settings['notify_dhuhr']) ?? true,
        Prayer.asr: jBool(settings['notify_asr']) ?? true,
        Prayer.maghrib: jBool(settings['notify_maghrib']) ?? true,
        Prayer.isha: jBool(settings['notify_isha']) ?? true,
      },
      lat: data.latitude,
      lng: data.longitude,
      city: data.locationLabel,
    );
    ref.invalidate(prayerScheduleProvider);
  }

  Future<void> _useMyLocation() async {
    final result = await resolvePrayerLocation();
    if (!mounted) return;
    ref.invalidate(prayerScheduleProvider);
    final message = switch (result) {
      LocationResult.ok => null,
      LocationResult.servicesOff =>
        'Location Services are turned off. Choose your city instead, or turn them on in Settings.',
      LocationResult.denied =>
        'Location access was not allowed. You can choose your city instead.',
      LocationResult.deniedForever =>
        'Location access is off for Ehsan Pathways. Choose your city, or allow access in Settings.',
      LocationResult.failed =>
        'Your location could not be found. Choose your city instead.',
    };
    if (message == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action:
            result == LocationResult.deniedForever ||
                result == LocationResult.servicesOff
            ? SnackBarAction(
                label: 'Settings',
                onPressed: () => result == LocationResult.servicesOff
                    ? Geolocator.openLocationSettings()
                    : Geolocator.openAppSettings(),
              )
            : SnackBarAction(label: 'Choose city', onPressed: _pickCity),
      ),
    );
  }

  Future<void> _pickCity() async {
    final city = await showPrayerCityPicker(context);
    if (city == null) return;
    await PrayerTimesService.saveLocation(
      lat: city.lat,
      lng: city.lng,
      city: city.label,
    );
    // Adopt the region's customary method and Asr school.
    final settings = await PrayerTimesService.loadSettings();
    await PrayerTimesService.saveSettings(
      enabled: jBool(settings['enabled']) ?? false,
      method: city.method,
      prayerToggles: {
        Prayer.fajr: jBool(settings['notify_fajr']) ?? true,
        Prayer.dhuhr: jBool(settings['notify_dhuhr']) ?? true,
        Prayer.asr: jBool(settings['notify_asr']) ?? true,
        Prayer.maghrib: jBool(settings['notify_maghrib']) ?? true,
        Prayer.isha: jBool(settings['notify_isha']) ?? true,
      },
    );
    await PrayerTimesService.saveMadhab(city.hanafi ? 'hanafi' : 'shafi');
    ref.invalidate(prayerScheduleProvider);
  }

  Future<void> _setHanafi(bool hanafi) async {
    await PrayerTimesService.saveMadhab(hanafi ? 'hanafi' : 'shafi');
    ref.invalidate(prayerScheduleProvider);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final async = ref.watch(prayerScheduleProvider);

    return Scaffold(
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorView(
          isLocation: err is PrayerLocationException,
          onUseLocation: _useMyLocation,
          onPickCity: _pickCity,
        ),
        data: (data) => _Content(
          data: data,
          isDark: isDark,
          onPickMethod: () => _pickMethod(data),
          onRefreshLocation: _useMyLocation,
          onPickCity: _pickCity,
          onSetHanafi: _setHanafi,
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
    required this.onPickCity,
    required this.onSetHanafi,
  });

  final PrayerScheduleData data;
  final bool isDark;
  final VoidCallback onPickMethod;
  final Future<void> Function() onRefreshLocation;
  final VoidCallback onPickCity;
  final ValueChanged<bool> onSetHanafi;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 260,
          backgroundColor: AppColors.emerald900,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              tooltip: 'Use my location',
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
          padding: readingInsets(context, horizontal: 16, top: 16, bottom: 8),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 18,
                      color: isDark ? AppColors.gold : AppColors.emerald700,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        data.locationLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.ui(
                          size: 14,
                          weight: FontWeight.w700,
                          color: isDark ? AppColors.onDark : AppColors.ink,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: onPickCity,
                      child: const Text('Change'),
                    ),
                  ],
                ),
                Text(
                  '${DateFormat('EEEE, d MMMM').format(DateTime.now())} · '
                  '${data.method.displayName}',
                  style: AppTheme.ui(
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: isDark ? AppColors.onDarkMuted : AppColors.muted,
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text("Asr: Shafi'i / Standard"),
                    ),
                    ButtonSegment(value: true, label: Text('Asr: Hanafi')),
                  ],
                  selected: {data.hanafi},
                  showSelectedIcon: false,
                  onSelectionChanged: (v) => onSetHanafi(v.first),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: readingInsets(context, horizontal: 16, top: 8, bottom: 32),
          sliver: SliverList.separated(
            itemCount: data.entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final entry = data.entries[i];
              final isNext =
                  entry.prayer == data.nextPrayer &&
                  entry.prayer != Prayer.sunrise;
              final isCurrent =
                  entry.prayer == data.currentPrayer &&
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
      decoration: const BoxDecoration(gradient: AppGradients.emerald),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 44, 20, 44),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'NEXT PRAYER',
                style: GoogleFonts.plusJakartaSans(
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
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 15,
                      color: _gold,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${PrayerTimesService.formatTime(next.time)}  •  in ${_formatRemaining(remaining)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
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
    final baseColor = isDark ? AppColors.slateCard : Colors.white;

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
                    : AppColors.sand),
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
            child: Icon(
              _icon,
              size: 20,
              color: highlight ? Colors.white : _green,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    entry.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: highlight
                          ? Colors.white
                          : (isDark ? Colors.white : AppColors.ink),
                    ),
                  ),
                  if (isCurrent && !isNext) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _gold.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'NOW',
                        style: GoogleFonts.plusJakartaSans(
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
                      : (isDark ? Colors.white54 : AppColors.subtle),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            PrayerTimesService.formatTime(entry.time),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: highlight
                  ? Colors.white
                  : (isDark ? Colors.white : AppColors.ink),
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
        color: isDark ? AppColors.slateCard : Colors.white,
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
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.ink,
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
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.ink,
                      ),
                    ),
                    subtitle: Text(
                      m.region,
                      style: GoogleFonts.plusJakartaSans(
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
  const _ErrorView({
    required this.isLocation,
    required this.onUseLocation,
    required this.onPickCity,
  });

  final bool isLocation;
  final VoidCallback onUseLocation;
  final VoidCallback onPickCity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: BackButton(color: Theme.of(context).colorScheme.onSurface),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        alignment: Alignment.center,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppGradients.emerald,
                        ),
                        child: const Icon(
                          Icons.mosque_rounded,
                          size: 40,
                          color: AppColors.goldLight,
                        ),
                      ).centered(),
                      Text(
                        isLocation
                            ? 'Where are you praying?'
                            : 'Unable to calculate prayer times',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isLocation
                            ? 'Prayer times are calculated on your device. Share your location for the most accurate times, or choose your city. Both work offline.'
                            : 'Please choose your city or try your location again.',
                        textAlign: TextAlign.center,
                        style: AppTheme.ui(
                          size: 14,
                          weight: FontWeight.w500,
                          height: 1.5,
                          color: isDark
                              ? AppColors.onDarkMuted
                              : AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: onUseLocation,
                        icon: const Icon(Icons.my_location_rounded),
                        label: const Text('Use my location'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: onPickCity,
                        icon: const Icon(Icons.location_city_rounded),
                        label: const Text('Choose a city'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension on Widget {
  Widget centered() => Center(child: this);
}

// ===========================================================================
// City picker
// ===========================================================================

/// Bottom sheet listing the bundled cities; returns the one chosen.
Future<PrayerCity?> showPrayerCityPicker(BuildContext context) =>
    showModalBottomSheet<PrayerCity>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CityPicker(),
    );

class _CityPicker extends StatefulWidget {
  const _CityPicker();

  @override
  State<_CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<_CityPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final cities = q.isEmpty
        ? kPrayerCities
        : kPrayerCities
              .where(
                (c) =>
                    c.name.toLowerCase().contains(q) ||
                    c.country.toLowerCase().contains(q),
              )
              .toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose your city',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: false,
                    onChanged: (v) => setState(() => _query = v),
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      hintText: 'Search city or country',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: cities.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No match. Choose the nearest city listed, or use your location.',
                          textAlign: TextAlign.center,
                          style: AppTheme.ui(
                            size: 14,
                            color: isDark
                                ? AppColors.onDarkMuted
                                : AppColors.muted,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: cities.length,
                      itemBuilder: (context, i) {
                        final c = cities[i];
                        return ListTile(
                          leading: const Icon(Icons.place_outlined),
                          title: Text(c.name),
                          subtitle: Text(
                            '${c.country} · ${c.method.displayName}',
                          ),
                          onTap: () => Navigator.pop(context, c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

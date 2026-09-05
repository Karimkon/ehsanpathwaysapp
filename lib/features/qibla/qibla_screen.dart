import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ehsan_pathways/core/services/prayer_times_service.dart';
import 'package:ehsan_pathways/shared/widgets/empty_state.dart';

const _green = Color(0xFF16A34A);
const _greenDark = Color(0xFF15803D);
const _gold = Color(0xFFF59E0B);

/// Coordinates of the Kaaba in Makkah.
const double _kaabaLat = 21.4225;
const double _kaabaLng = 39.8262;

/// Qibla compass: shows the direction of the Kaaba relative to the device's
/// current heading. Falls back to a static bearing readout when the device
/// has no magnetometer.
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  double? _qiblaBearing; // degrees from true north
  String? _locationLabel;
  bool _loading = true;
  bool _locationDenied = false;

  @override
  void initState() {
    super.initState();
    _resolveLocation();
  }

  Future<void> _resolveLocation() async {
    setState(() {
      _loading = true;
      _locationDenied = false;
    });

    // Prefer a saved location; otherwise request GPS.
    final settings = await PrayerTimesService.loadSettings();
    double? lat = settings['lat'] as double?;
    double? lng = settings['lng'] as double?;
    String label = settings['city'] as String? ?? '';

    if (lat == null || lng == null) {
      final pos = await PrayerTimesService.getCurrentPosition();
      if (pos == null) {
        if (mounted) {
          setState(() {
            _loading = false;
            _locationDenied = true;
          });
        }
        return;
      }
      lat = pos.latitude;
      lng = pos.longitude;
      label = PrayerTimesService.coordinatesLabel(lat, lng);
    }

    final bearing = _computeQiblaBearing(lat, lng);
    if (mounted) {
      setState(() {
        _qiblaBearing = bearing;
        _locationLabel =
            label.isNotEmpty ? label : PrayerTimesService.coordinatesLabel(lat!, lng!);
        _loading = false;
      });
    }
  }

  /// Great-circle initial bearing from the user's position to the Kaaba.
  double _computeQiblaBearing(double lat, double lng) {
    final phi1 = _rad(lat);
    final phi2 = _rad(_kaabaLat);
    final deltaLng = _rad(_kaabaLng - lng);

    final y = math.sin(deltaLng);
    final x = math.cos(phi1) * math.tan(phi2) - math.sin(phi1) * math.cos(deltaLng);
    final bearing = _deg(math.atan2(y, x));
    return (bearing + 360) % 360;
  }

  double _rad(double deg) => deg * math.pi / 180.0;
  double _deg(double rad) => rad * 180.0 / math.pi;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('Qibla Direction',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _green));
    }

    if (_locationDenied) {
      return Center(
        child: EmptyState(
          icon: Icons.location_off_rounded,
          title: 'Location needed',
          subtitle:
              'We need your location to calculate the direction of the Kaaba. Please enable location access.',
          actionLabel: 'Enable & Retry',
          onAction: _resolveLocation,
        ),
      );
    }

    final bearing = _qiblaBearing!;

    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        // Device without magnetometer (or permission not yet granted): show a
        // static readout of the Qibla bearing so the screen is still useful.
        final heading = snapshot.data?.heading;
        final hasCompass = snapshot.hasData && heading != null;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Text(
                _locationLabel ?? '',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${bearing.toStringAsFixed(0)}° from North',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _green,
                ),
              ),
              const SizedBox(height: 28),
              _CompassDial(
                qiblaBearing: bearing,
                heading: heading ?? 0,
                isDark: isDark,
                active: hasCompass,
              ),
              const SizedBox(height: 28),
              if (hasCompass)
                _AlignmentHint(
                  qiblaBearing: bearing,
                  heading: heading,
                  isDark: isDark,
                )
              else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 18, color: _gold),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Compass sensor unavailable. Face ${bearing.toStringAsFixed(0)}° from North (use a physical compass) to face the Qibla.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color:
                                isDark ? Colors.white70 : const Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

// ===========================================================================
// Compass dial
// ===========================================================================

class _CompassDial extends StatelessWidget {
  const _CompassDial({
    required this.qiblaBearing,
    required this.heading,
    required this.isDark,
    required this.active,
  });

  final double qiblaBearing;
  final double heading;
  final bool isDark;
  final bool active;

  @override
  Widget build(BuildContext context) {
    // Dial rotates opposite to heading so N points to real north.
    final dialAngle = active ? -_rad(heading) : 0.0;
    // Qibla needle points to (qiblaBearing - heading) from screen-up.
    final needleAngle = _rad(qiblaBearing - (active ? heading : 0));

    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              border: Border.all(
                color: _green.withValues(alpha: 0.25),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _green.withValues(alpha: isDark ? 0.15 : 0.12),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          // Cardinal directions (rotate with heading)
          Transform.rotate(
            angle: dialAngle,
            child: SizedBox(
              width: 300,
              height: 300,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _cardinal('N', Alignment.topCenter,
                      color: Colors.redAccent, isDark: isDark),
                  _cardinal('E', Alignment.centerRight, isDark: isDark),
                  _cardinal('S', Alignment.bottomCenter, isDark: isDark),
                  _cardinal('W', Alignment.centerLeft, isDark: isDark),
                ],
              ),
            ),
          ),
          // Qibla needle (Kaaba pointer)
          Transform.rotate(
            angle: needleAngle,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: _greenDark,
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🕋', style: TextStyle(fontSize: 22)),
                ),
                Container(
                  width: 4,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_green, _greenDark],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          // Centre hub
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: _gold,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardinal(String label, Alignment alignment,
      {Color? color, required bool isDark}) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color ??
                (isDark ? Colors.white60 : const Color(0xFF6B7280)),
          ),
        ),
      ),
    );
  }

  double _rad(double deg) => deg * math.pi / 180.0;
}

// ===========================================================================
// Alignment hint (turns green when the phone faces the Qibla)
// ===========================================================================

class _AlignmentHint extends StatelessWidget {
  const _AlignmentHint({
    required this.qiblaBearing,
    required this.heading,
    required this.isDark,
  });

  final double qiblaBearing;
  final double heading;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Angular difference between where the phone points and the Qibla.
    var diff = (qiblaBearing - heading) % 360;
    if (diff > 180) diff -= 360;
    final aligned = diff.abs() <= 5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: aligned
            ? _green.withValues(alpha: 0.15)
            : (isDark ? const Color(0xFF1A1A1A) : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: aligned ? _green : Colors.grey.withValues(alpha: 0.3),
          width: aligned ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            aligned ? Icons.check_circle_rounded : Icons.rotate_right_rounded,
            color: aligned ? _green : _gold,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            aligned
                ? 'Facing the Qibla — Allahu Akbar'
                : diff > 0
                    ? 'Turn right ${diff.abs().toStringAsFixed(0)}°'
                    : 'Turn left ${diff.abs().toStringAsFixed(0)}°',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: aligned
                  ? _green
                  : (isDark ? Colors.white : const Color(0xFF111827)),
            ),
          ),
        ],
      ),
    );
  }
}

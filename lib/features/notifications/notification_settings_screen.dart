import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ehsan_pathways/core/providers/notification_provider.dart';
import 'package:ehsan_pathways/core/services/notification_service.dart';
import 'package:ehsan_pathways/core/services/prayer_times_service.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  static const routeName = '/notifications';

  static const _green = Color(0xFF16A34A);
  static const _green900 = Color(0xFF14532D);
  static const _gold = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        title: Text(
          'Notifications',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Prayer Times Section ─────────────────────────────────────────
          _SectionHeader(title: 'Prayer Times', icon: Icons.mosque_rounded, isDark: isDark),
          const SizedBox(height: 8),

          _SettingsCard(
            isDark: isDark,
            children: [
              _SwitchTile(
                title: 'Prayer Time Reminders',
                subtitle: 'Get notified at each prayer time',
                value: settings.prayerTimesEnabled,
                icon: Icons.access_time_rounded,
                iconColor: _green,
                isDark: isDark,
                onChanged: (v) => notifier.togglePrayerTimes(v),
              ),

              if (settings.prayerTimesEnabled) ...[
                const Divider(height: 1),

                // Location row
                _LocationTile(
                  settings: settings,
                  isDark: isDark,
                  onDetect: () => notifier.detectLocation(),
                ),

                if (settings.status == NotificationLoadStatus.error &&
                    settings.error != null) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red.shade400, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              settings.error!,
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const Divider(height: 1),

                // Calculation method
                ListTile(
                  leading: Icon(Icons.calculate_outlined,
                      color: _green, size: 22),
                  title: Text(
                    'Calculation Method',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : _green900),
                  ),
                  subtitle: Text(
                    settings.calculationMethod.label,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade500),
                  ),
                  trailing: Icon(Icons.chevron_right,
                      color: Colors.grey.shade400),
                  onTap: () => _showMethodPicker(context, ref, settings),
                ),

                const Divider(height: 1),

                // Individual prayer toggles
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    'Enable notifications for each prayer',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),

                // Today's prayer times with toggles
                if (settings.todayPrayers.isNotEmpty)
                  ...settings.todayPrayers
                      .where((e) => e.prayer != Prayer.sunrise)
                      .map(
                        (entry) => _PrayerTile(
                          entry: entry,
                          isDark: isDark,
                          onToggle: (v) =>
                              notifier.togglePrayer(entry.prayer, v),
                        ),
                      ),

                if (settings.hasLocation && settings.todayPrayers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),

                if (!settings.hasLocation && settings.prayerTimesEnabled)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _LocationPrompt(
                      onDetect: () => notifier.detectLocation(),
                    ),
                  ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // Jumah reminder
          _SettingsCard(
            isDark: isDark,
            children: [
              _SwitchTile(
                title: 'Jumu\'ah Reminder',
                subtitle: 'Friday prayer reminder at 11:30 AM',
                value: settings.jumahReminderEnabled,
                icon: Icons.star_rounded,
                iconColor: _gold,
                isDark: isDark,
                onChanged: (v) => notifier.toggleJumahReminder(v),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Learning Section ─────────────────────────────────────────────
          _SectionHeader(
              title: 'Learning Reminders', icon: Icons.menu_book_rounded, isDark: isDark),
          const SizedBox(height: 8),

          _SettingsCard(
            isDark: isDark,
            children: [
              _SwitchTile(
                title: 'Daily Learning Reminder',
                subtitle: 'Reminder to continue your Islamic knowledge journey',
                value: settings.learningReminderEnabled,
                icon: Icons.notifications_active_rounded,
                iconColor: const Color(0xFF7C3AED),
                isDark: isDark,
                onChanged: (v) => notifier.toggleLearningReminder(v),
              ),

              if (settings.learningReminderEnabled) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.schedule_rounded,
                      color: Color(0xFF7C3AED), size: 22),
                  title: Text(
                    'Reminder Time',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : _green900),
                  ),
                  subtitle: Text(
                    settings.learningReminderTime.format(context),
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey.shade500),
                  ),
                  trailing: Icon(Icons.chevron_right,
                      color: Colors.grey.shade400),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: settings.learningReminderTime,
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(primary: _green),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      ref
                          .read(notificationProvider.notifier)
                          .setLearningReminderTime(picked);
                    }
                  },
                ),
              ],
            ],
          ),

          const SizedBox(height: 20),

          // ── Content Section ──────────────────────────────────────────────
          _SectionHeader(
              title: 'Content Notifications', icon: Icons.campaign_rounded, isDark: isDark),
          const SizedBox(height: 8),

          _SettingsCard(
            isDark: isDark,
            children: [
              _SwitchTile(
                title: 'New Content Alerts',
                subtitle: 'Be notified when new videos, articles & podcasts are published',
                value: settings.newContentEnabled,
                icon: Icons.new_releases_rounded,
                iconColor: const Color(0xFF0EA5E9),
                isDark: isDark,
                onChanged: (v) => notifier.toggleNewContent(v),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Today's Prayer Times Card ─────────────────────────────────────
          if (settings.hasLocation && settings.todayPrayers.isNotEmpty) ...[
            _SectionHeader(
                title: "Today's Prayer Times", icon: Icons.wb_twilight_rounded, isDark: isDark),
            const SizedBox(height: 8),
            _TodayPrayerCard(
                prayers: settings.todayPrayers, isDark: isDark),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showMethodPicker(
    BuildContext context,
    WidgetRef ref,
    NotificationSettings settings,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, controller) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Calculation Method',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _green900,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                children: PrayerCalculationMethod.values.map((method) {
                  final isSelected = method == settings.calculationMethod;
                  return ListTile(
                    title: Text(
                      method.label,
                      style: GoogleFonts.poppins(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected ? _green : null,
                      ),
                    ),
                    subtitle: Text(
                      method.region,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: _green)
                        : null,
                    onTap: () {
                      ref
                          .read(notificationProvider.notifier)
                          .setCalculationMethod(method);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
      {required this.title, required this.icon, required this.isDark});

  final String title;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: NotificationSettingsScreen._green),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: NotificationSettingsScreen._green,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children, required this.isDark});

  final List<Widget> children;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: children),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.isDark,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final IconData icon;
  final Color iconColor;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: NotificationSettingsScreen._green,
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : const Color(0xFF14532D),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  const _LocationTile(
      {required this.settings, required this.isDark, required this.onDetect});

  final NotificationSettings settings;
  final bool isDark;
  final VoidCallback onDetect;

  @override
  Widget build(BuildContext context) {
    final isLoading = settings.status == NotificationLoadStatus.loading;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.location_on_rounded,
            color: Colors.blue.shade600, size: 20),
      ),
      title: Text(
        settings.hasLocation ? 'Location Detected' : 'Detect My Location',
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : const Color(0xFF14532D),
        ),
      ),
      subtitle: Text(
        settings.hasLocation
            ? settings.locationLabel
            : 'Required for accurate prayer times',
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: settings.hasLocation
              ? Colors.blue.shade600
              : Colors.grey.shade500,
        ),
      ),
      trailing: isLoading
          ? const SizedBox(
              width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : TextButton(
              onPressed: onDetect,
              child: Text(
                settings.hasLocation ? 'Update' : 'Detect',
                style: GoogleFonts.poppins(
                  color: NotificationSettingsScreen._green,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
    );
  }
}

class _LocationPrompt extends StatelessWidget {
  const _LocationPrompt({required this.onDetect});
  final VoidCallback onDetect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.location_searching_rounded,
            size: 40, color: Colors.grey.shade400),
        const SizedBox(height: 8),
        Text(
          'Location needed for prayer times',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: onDetect,
          icon: const Icon(Icons.gps_fixed_rounded, size: 18),
          label: Text(
            'Detect My Location',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: NotificationSettingsScreen._green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

class _PrayerTile extends StatelessWidget {
  const _PrayerTile(
      {required this.entry, required this.isDark, required this.onToggle});

  final PrayerEntry entry;
  final bool isDark;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Text(
        entry.arabicName,
        style: const TextStyle(
          fontSize: 18,
          fontFamily: 'Amiri',
          color: Color(0xFF16A34A),
        ),
      ),
      title: Text(
        entry.name,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : const Color(0xFF14532D),
        ),
      ),
      subtitle: Text(
        PrayerTimesService.formatTime(entry.time),
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey.shade500,
        ),
      ),
      trailing: Switch.adaptive(
        value: entry.notifyEnabled,
        onChanged: onToggle,
        activeColor: NotificationSettingsScreen._green,
      ),
    );
  }
}

class _TodayPrayerCard extends StatelessWidget {
  const _TodayPrayerCard(
      {required this.prayers, required this.isDark});

  final List<PrayerEntry> prayers;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF16A34A), Color(0xFF15803D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.wb_twilight_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                "Today's Prayer Times",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...prayers.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        e.arabicName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        e.name,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    PrayerTimesService.formatTime(e.time),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Extension for display labels
extension on PrayerCalculationMethod {
  String get label {
    switch (this) {
      case PrayerCalculationMethod.muslimWorldLeague: return 'Muslim World League';
      case PrayerCalculationMethod.northAmerica: return 'ISNA — North America';
      case PrayerCalculationMethod.egyptian: return 'Egyptian General Authority';
      case PrayerCalculationMethod.ummAlQura: return 'Umm Al-Qura (Makkah)';
      case PrayerCalculationMethod.karachi: return 'University of Karachi';
      case PrayerCalculationMethod.kuwait: return 'Kuwait';
      case PrayerCalculationMethod.qatar: return 'Qatar';
      case PrayerCalculationMethod.singapore: return 'Singapore';
      case PrayerCalculationMethod.turkey: return 'Turkey (Diyanet)';
      case PrayerCalculationMethod.tehran: return 'Tehran';
    }
  }

  String get region {
    switch (this) {
      case PrayerCalculationMethod.muslimWorldLeague: return 'Global / Europe / Americas';
      case PrayerCalculationMethod.northAmerica: return 'USA & Canada';
      case PrayerCalculationMethod.egyptian: return 'Egypt, Sudan, Africa';
      case PrayerCalculationMethod.ummAlQura: return 'Saudi Arabia & Gulf';
      case PrayerCalculationMethod.karachi: return 'Pakistan, Bangladesh, India';
      case PrayerCalculationMethod.kuwait: return 'Kuwait';
      case PrayerCalculationMethod.qatar: return 'Qatar';
      case PrayerCalculationMethod.singapore: return 'Singapore & SE Asia';
      case PrayerCalculationMethod.turkey: return 'Turkey';
      case PrayerCalculationMethod.tehran: return 'Iran';
    }
  }
}

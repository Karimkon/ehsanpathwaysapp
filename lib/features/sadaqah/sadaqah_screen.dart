import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/core/services/content_service.dart';
import 'package:ehsan_pathways/shared/widgets/badge_chip.dart';
import 'package:ehsan_pathways/shared/widgets/empty_state.dart';
import 'package:ehsan_pathways/shared/widgets/loading_shimmer.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final _contentServiceProvider =
    Provider<ContentService>((ref) => ContentService());

final sadaqahPurposesProvider = FutureProvider<List<dynamic>>((ref) async {
  final service = ref.watch(_contentServiceProvider);
  return service.fetchSadaqahPurposes();
});

final sadaqahReportsProvider = FutureProvider<List<dynamic>>((ref) async {
  final service = ref.watch(_contentServiceProvider);
  return service.fetchSadaqahReports();
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class SadaqahScreen extends ConsumerStatefulWidget {
  const SadaqahScreen({super.key});

  @override
  ConsumerState<SadaqahScreen> createState() => _SadaqahScreenState();
}

class _SadaqahScreenState extends ConsumerState<SadaqahScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8FAF8),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          // ── Header ────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: const Color(0xFF78350F),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF78350F),
                      Color(0xFFB45309),
                      Color(0xFFF59E0B),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.volunteer_activism_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Sadaqah',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '"The believer\'s shade on the Day of Resurrection will be their charity"',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
              labelStyle: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Give'),
                Tab(text: 'Transparency'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _GiveTab(isDark: isDark),
            _TransparencyTab(isDark: isDark),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Give tab
// ---------------------------------------------------------------------------

class _GiveTab extends ConsumerWidget {
  const _GiveTab({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purposesAsync = ref.watch(sadaqahPurposesProvider);

    return purposesAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ShimmerWrap(
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
      error: (e, _) => EmptyState(
        icon: Icons.volunteer_activism_rounded,
        title: 'Could not load purposes',
        subtitle: 'Please check your connection and try again.',
        actionLabel: 'Retry',
        onAction: () => ref.invalidate(sadaqahPurposesProvider),
        iconColor: const Color(0xFFF59E0B),
      ),
      data: (purposes) {
        if (purposes.isEmpty) {
          return EmptyState(
            icon: Icons.volunteer_activism_rounded,
            title: 'No purposes available',
            subtitle: 'Donation purposes are being set up.',
            iconColor: const Color(0xFFF59E0B),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      const Color(0xFFF59E0B).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(0xFFF59E0B), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Give Sadaqah — purify your wealth and earn ongoing rewards.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: isDark
                            ? const Color(0xFFFCD34D)
                            : const Color(0xFF78350F),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Choose a Cause',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            ...purposes.map((p) {
              final purpose = p as Map<String, dynamic>;
              return _PurposeCard(
                purpose: purpose,
                isDark: isDark,
                onDonate: () => _showDonationSheet(
                    context, purpose, ref),
              );
            }),
          ],
        );
      },
    );
  }

  void _showDonationSheet(
    BuildContext context,
    Map<String, dynamic> purpose,
    WidgetRef ref,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DonationBottomSheet(
        purpose: purpose,
        isDark: isDark,
        ref: ref,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Purpose card
// ---------------------------------------------------------------------------

class _PurposeCard extends StatelessWidget {
  const _PurposeCard({
    required this.purpose,
    required this.isDark,
    required this.onDonate,
  });

  final Map<String, dynamic> purpose;
  final bool isDark;
  final VoidCallback onDonate;

  @override
  Widget build(BuildContext context) {
    final name = purpose['name'] as String? ?? '';
    final description = purpose['description'] as String? ?? '';
    final targetAmount =
        (purpose['target_amount'] as num?)?.toDouble() ?? 0;
    final currentAmount =
        (purpose['current_amount'] as num?)?.toDouble() ?? 0;
    final progress =
        targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
    final currency = purpose['currency'] as String? ?? 'USD';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.volunteer_activism_rounded,
                    color: Color(0xFFF59E0B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color:
                      isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
            ],
            if (targetAmount > 0) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$currency ${currentAmount.toStringAsFixed(0)} raised',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  Text(
                    'Goal: $currency ${targetAmount.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: isDark
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFFF3F4F6),
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onDonate,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.favorite_rounded, size: 16),
                label: Text(
                  'Donate',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Donation bottom sheet
// ---------------------------------------------------------------------------

class _DonationBottomSheet extends StatefulWidget {
  const _DonationBottomSheet({
    required this.purpose,
    required this.isDark,
    required this.ref,
  });

  final Map<String, dynamic> purpose;
  final bool isDark;
  final WidgetRef ref;

  @override
  State<_DonationBottomSheet> createState() => _DonationBottomSheetState();
}

class _DonationBottomSheetState extends State<_DonationBottomSheet> {
  static const _presetAmounts = [5.0, 10.0, 25.0, 50.0, 100.0];
  double? _selectedAmount;
  final _customController = TextEditingController();
  String _currency = 'USD';
  String _paymentMethod = 'Flutterwave';
  bool _isAnonymous = false;
  final _nameController = TextEditingController();
  bool _isSubmitting = false;

  static const _currencies = ['USD', 'KES', 'GBP', 'EUR', 'NGN'];
  static const _paymentMethods = ['Flutterwave', 'M-Pesa', 'Crypto'];

  @override
  void dispose() {
    _customController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  double get _effectiveAmount {
    if (_selectedAmount != null) return _selectedAmount!;
    return double.tryParse(_customController.text) ?? 0;
  }

  Future<void> _submit() async {
    final amount = _effectiveAmount;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final service = widget.ref.read(_contentServiceProvider);
      final purposeId = widget.purpose['id'] as int? ?? 0;
      await service.submitDonation(
        purposeId: purposeId,
        amount: amount,
        currency: _currency,
        paymentMethod: _paymentMethod,
        isAnonymous: _isAnonymous,
        donorName: _isAnonymous ? null : _nameController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Donation failed: ${e.toString()}'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.volunteer_activism_rounded,
                size: 36,
                color: Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'JazakAllah Khair!',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: widget.isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your donation is being processed. May Allah bless your generosity.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: widget.isDark
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Ameen',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final purposeName = widget.purpose['name'] as String? ?? '';
    final sheetColor =
        widget.isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: sheetColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: widget.isDark
                    ? const Color(0xFF3A3A3A)
                    : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Text(
                    'Donate to $purposeName',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: widget.isDark
                          ? Colors.white
                          : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Amount presets
                  Text(
                    'Select Amount',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: widget.isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _presetAmounts.map((amt) {
                      final selected = _selectedAmount == amt;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedAmount = amt;
                            _customController.clear();
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFF59E0B)
                                : (widget.isDark
                                    ? const Color(0xFF2A2A2A)
                                    : const Color(0xFFF9FAFB)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFFF59E0B)
                                  : (widget.isDark
                                      ? const Color(0xFF3A3A3A)
                                      : const Color(0xFFE5E7EB)),
                            ),
                          ),
                          child: Text(
                            '\$${amt.toInt()}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? Colors.white
                                  : (widget.isDark
                                      ? Colors.white
                                      : const Color(0xFF111827)),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Custom amount
                  TextField(
                    controller: _customController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    onChanged: (_) =>
                        setState(() => _selectedAmount = null),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: widget.isDark
                          ? Colors.white
                          : const Color(0xFF111827),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Custom amount',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: widget.isDark
                            ? const Color(0xFF6B7280)
                            : const Color(0xFF9CA3AF),
                      ),
                      prefixText: '\$ ',
                      filled: true,
                      fillColor: widget.isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: widget.isDark
                              ? const Color(0xFF3A3A3A)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: widget.isDark
                              ? const Color(0xFF3A3A3A)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFF59E0B),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Currency
                  Text(
                    'Currency',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: widget.isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _currency,
                    items: _currencies
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c,
                                  style: GoogleFonts.poppins(fontSize: 14)),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _currency = v ?? 'USD'),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: widget.isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: widget.isDark
                              ? const Color(0xFF3A3A3A)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: widget.isDark
                              ? const Color(0xFF3A3A3A)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment method
                  Text(
                    'Payment Method',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: widget.isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _paymentMethods.map((method) {
                      final selected = _paymentMethod == method;
                      IconData icon;
                      switch (method) {
                        case 'M-Pesa':
                          icon = Icons.phone_android_rounded;
                          break;
                        case 'Crypto':
                          icon = Icons.currency_bitcoin_rounded;
                          break;
                        default:
                          icon = Icons.credit_card_rounded;
                      }
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _paymentMethod = method),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.15)
                                : (widget.isDark
                                    ? const Color(0xFF2A2A2A)
                                    : const Color(0xFFF9FAFB)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFFF59E0B)
                                  : (widget.isDark
                                      ? const Color(0xFF3A3A3A)
                                      : const Color(0xFFE5E7EB)),
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icon,
                                size: 16,
                                color: selected
                                    ? const Color(0xFFF59E0B)
                                    : (widget.isDark
                                        ? const Color(0xFF9CA3AF)
                                        : const Color(0xFF6B7280)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                method,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected
                                      ? const Color(0xFFF59E0B)
                                      : (widget.isDark
                                          ? const Color(0xFF9CA3AF)
                                          : const Color(0xFF6B7280)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Donor name
                  if (!_isAnonymous) ...[
                    TextField(
                      controller: _nameController,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: widget.isDark
                            ? Colors.white
                            : const Color(0xFF111827),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Your name (optional)',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          color: widget.isDark
                              ? const Color(0xFF6B7280)
                              : const Color(0xFF9CA3AF),
                        ),
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        filled: true,
                        fillColor: widget.isDark
                            ? const Color(0xFF2A2A2A)
                            : const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: widget.isDark
                                ? const Color(0xFF3A3A3A)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: widget.isDark
                                ? const Color(0xFF3A3A3A)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFF59E0B),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Anonymous toggle
                  Row(
                    children: [
                      Switch(
                        value: _isAnonymous,
                        onChanged: (v) =>
                            setState(() => _isAnonymous = v),
                        activeColor: const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Give anonymously',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: widget.isDark
                              ? Colors.white
                              : const Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFF59E0B)
                            .withValues(alpha: 0.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.favorite_rounded),
                      label: Text(
                        _isSubmitting
                            ? 'Processing...'
                            : 'Donate $_currency ${_effectiveAmount > 0 ? _effectiveAmount.toStringAsFixed(2) : ""}',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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

// ---------------------------------------------------------------------------
// Transparency tab
// ---------------------------------------------------------------------------

class _TransparencyTab extends ConsumerWidget {
  const _TransparencyTab({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(sadaqahReportsProvider);

    return reportsAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ShimmerWrap(
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
      error: (e, _) => EmptyState(
        icon: Icons.pie_chart_rounded,
        title: 'Could not load reports',
        subtitle: 'Please check your connection and try again.',
        actionLabel: 'Retry',
        onAction: () => ref.invalidate(sadaqahReportsProvider),
        iconColor: const Color(0xFFF59E0B),
      ),
      data: (reports) {
        if (reports.isEmpty) {
          return EmptyState(
            icon: Icons.pie_chart_outline_rounded,
            title: 'No reports yet',
            subtitle: 'Spending reports will appear here.',
            iconColor: const Color(0xFFF59E0B),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded,
                      color: AppTheme.primaryGreen, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'We are committed to full transparency in how your donations are used.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: isDark
                            ? const Color(0xFF86EFAC)
                            : AppTheme.primaryGreenDark,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Spending Reports',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            ...reports.map((r) {
              final report = r as Map<String, dynamic>;
              return _ReportCard(report: report, isDark: isDark);
            }),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Report card
// ---------------------------------------------------------------------------

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.isDark});

  final Map<String, dynamic> report;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final period = report['period'] as String? ?? '';
    final totalReceived =
        (report['total_received'] as num?)?.toDouble() ?? 0;
    final totalSpent =
        (report['total_spent'] as num?)?.toDouble() ?? 0;
    final currency = report['currency'] as String? ?? 'USD';
    final spentPercent =
        totalReceived > 0 ? (totalSpent / totalReceived).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  period,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                BadgeChip(
                  label: '${(spentPercent * 100).toInt()}% spent',
                  variant: spentPercent < 0.9
                      ? BadgeVariant.green
                      : BadgeVariant.amber,
                  size: BadgeSize.small,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AmountTile(
                    label: 'Received',
                    amount: '$currency ${totalReceived.toStringAsFixed(2)}',
                    color: AppTheme.primaryGreen,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AmountTile(
                    label: 'Spent',
                    amount: '$currency ${totalSpent.toStringAsFixed(2)}',
                    color: const Color(0xFFF59E0B),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Utilization',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                          Text(
                            '${(spentPercent * 100).toStringAsFixed(1)}%',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2A2A2A)
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: spentPercent,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppTheme.primaryGreen,
                                    Color(0xFFF59E0B),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountTile extends StatelessWidget {
  const _AmountTile({
    required this.label,
    required this.amount,
    required this.color,
    required this.isDark,
  });

  final String label;
  final String amount;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

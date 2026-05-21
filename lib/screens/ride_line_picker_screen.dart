import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/vg_card.dart';
import '../providers/card_provider.dart';

/// Picker screen for selecting one card to fill a ride line slot.
/// [grade] must be 0, 1, 2, or 3.
class RideLinePickerScreen extends ConsumerStatefulWidget {
  final int grade;

  const RideLinePickerScreen({super.key, required this.grade});

  @override
  ConsumerState<RideLinePickerScreen> createState() =>
      _RideLinePickerScreenState();
}

class _RideLinePickerScreenState
    extends ConsumerState<RideLinePickerScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _query = '';

  static const _gradeColors = [
    Color(0xFF34D399), // G0 — green
    Color(0xFF60A5FA), // G1 — blue
    Color(0xFFA78BFA), // G2 — purple
    Color(0xFFEF4444), // G3 — red
  ];

  Color get _gradeColor => _gradeColors[widget.grade.clamp(0, 3)];

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String val) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      setState(() => _query = val.toLowerCase().trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardsAsync =
        ref.watch(rideLinePickerCardsProvider(widget.grade));
    final rideLine = ref.watch(rideLineProvider);
    final allowedNation = rideLine.nation;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Grade ${widget.grade} Card',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (allowedNation != null)
              Text(
                'Nation: $allowedNation',
                style: TextStyle(
                  color: _gradeColor.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Nation badge (if locked) ──────────────────────────────────
          if (allowedNation != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _gradeColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _gradeColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.flag_rounded, color: _gradeColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nation locked to "$allowedNation" based on ride line. '
                      'Cards without nation are also shown.',
                      style: TextStyle(
                        color: _gradeColor.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 10),

          // ── Search bar ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearch,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Search card name...',
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.white38, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Card grid ──────────────────────────────────────────────────
          Expanded(
            child: cardsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: Colors.white54)),
              ),
              data: (cards) {
                final filtered = _query.isEmpty
                    ? cards
                    : cards
                        .where((c) =>
                            c.name.toLowerCase().contains(_query))
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 60, color: _gradeColor.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        const Text('No cards found',
                            style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(
                          allowedNation != null
                              ? 'Try adjusting search or check nation filter'
                              : 'Try a different search term',
                          style: const TextStyle(
                              color: Colors.white24, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final card = filtered[index];
                    final isSelected =
                        rideLine.slotForGrade(widget.grade)?.id == card.id;
                    return _buildCardTile(context, card, isSelected);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardTile(BuildContext context, VgCard card, bool isSelected) {
    return GestureDetector(
      onTap: () {
        ref
            .read(rideLineProvider.notifier)
            .setSlot(widget.grade, card);
        Navigator.of(context).pop();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? _gradeColor
                : Colors.white.withValues(alpha: 0.06),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _gradeColor.withValues(alpha: 0.35),
                    blurRadius: 12,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: CachedNetworkImage(
                imageUrl: card.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => Container(
                  color: const Color(0xFF1E293B),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _gradeColor,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: const Color(0xFF1E293B),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.broken_image,
                          color: Colors.white24, size: 28),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          card.name,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 9),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom gradient + name
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(11),
                    bottomRight: Radius.circular(11),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  card.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Grade badge
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: _gradeColor.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'G${card.grade}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Selected checkmark
            if (isSelected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: _gradeColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check,
                      color: Colors.white, size: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

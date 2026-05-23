import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_recommendation.dart';
import '../models/deck_context.dart';
import '../models/mechanic_tag.dart';
import '../models/saved_deck.dart';
import '../models/vg_card.dart';
import '../providers/card_provider.dart';
import '../providers/recommendation_provider.dart';
import 'card_detail_screen.dart';

// ── Tag colours ───────────────────────────────────────────────────────────────
Color _tagColor(MechanicTag tag) {
  switch (tag) {
    case MechanicTag.drawEngine:          return const Color(0xFF60A5FA);
    case MechanicTag.soulCharger:         return const Color(0xFFA78BFA);
    case MechanicTag.counterCharger:      return const Color(0xFF34D399);
    case MechanicTag.powerBooster:        return const Color(0xFFFBBF24);
    case MechanicTag.retire:              return const Color(0xFFF87171);
    case MechanicTag.searcher:            return const Color(0xFF38BDF8);
    case MechanicTag.personalRideSupport: return const Color(0xFFE879F9);
    case MechanicTag.callFromDrop:        return const Color(0xFF4ADE80);
    case MechanicTag.standUnit:           return const Color(0xFFFCD34D);
    case MechanicTag.pressureLock:        return const Color(0xFFFF6B6B);
    case MechanicTag.healTrigger:         return const Color(0xFFF472B6);
    case MechanicTag.soulBlastCost:       return const Color(0xFFBB86FC);
    case MechanicTag.counterBlastCost:    return const Color(0xFF06B6D4);
    case MechanicTag.energyBlastCost:     return const Color(0xFFFF9800);
    case MechanicTag.orderSynergy:        return const Color(0xFF84CC16);
    case MechanicTag.bindZoneSynergy:     return const Color(0xFFF59E0B);
    case MechanicTag.guardianCaller:      return const Color(0xFF67E8F9);
    case MechanicTag.frontRow:            return const Color(0xFFFCA5A5);
    case MechanicTag.overTrigger:         return const Color(0xFFE879F9);
    case MechanicTag.critTrigger:         return const Color(0xFFEF4444);
    case MechanicTag.drawTrigger:         return const Color(0xFF60A5FA);
    case MechanicTag.frontTrigger:        return const Color(0xFF4ADE80);
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class RecommendationScreen extends ConsumerStatefulWidget {
  final VgCard targetCard;
  final DeckContext? initialDeckContext;

  const RecommendationScreen({
    super.key,
    required this.targetCard,
    this.initialDeckContext,
  });

  @override
  ConsumerState<RecommendationScreen> createState() =>
      _RecommendationScreenState();
}

class _RecommendationScreenState extends ConsumerState<RecommendationScreen> {
  String? _selectedRegulation;
  String? _selectedNation;
  SavedDeck? _selectedDeck;

  late VgCard _target;

  @override
  void initState() {
    super.initState();
    _target = widget.targetCard;
  }

  DeckContext? get _deckContext {
    if (_selectedDeck != null) return deckContextFromSavedDeck(_selectedDeck!);
    return widget.initialDeckContext;
  }

  RecommendationInput get _input => RecommendationInput(
        targetCard: _target,
        deckContext: _deckContext,
        regulationFilter: _selectedRegulation,
        nationFilter: _selectedNation,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF020617)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildTargetPreview(),
              _buildFilters(),
              Expanded(child: _buildResults()),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white70, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Find Replacements',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'For: ${_target.name}',
                  style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF60A5FA).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF60A5FA).withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF60A5FA), size: 14),
                const SizedBox(width: 6),
                Text(
                  'G${_target.grade}',
                  style: const TextStyle(
                    color: Color(0xFF60A5FA), fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Target card mini preview ───────────────────────────────────────────────
  Widget _buildTargetPreview() {
    final tags = _target.resolvedTags;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF60A5FA).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: _target.imageUrl,
              width: 44,
              height: 62,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(width: 44, height: 62, color: Colors.black26),
              errorWidget: (_, __, ___) =>
                  Container(width: 44, height: 62, color: Colors.black26,
                    child: const Icon(Icons.broken_image, size: 20, color: Colors.white38)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _target.name,
                  style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: tags.take(4).map((t) => _tagChip(t, small: true)).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Filters ────────────────────────────────────────────────────────────────
  Widget _buildFilters() {
    final regsAsync = ref.watch(availableRegulationsProvider);
    final nationsAsync = ref.watch(nationsProvider);
    final decksAsync = ref.watch(deckManagerProvider);

    final regs = regsAsync.valueOrNull ?? [];
    final nations = nationsAsync.valueOrNull ?? [];
    final decks = decksAsync.valueOrNull ?? [];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _filterChip(
            label: _selectedRegulation ?? 'All Formats',
            icon: Icons.verified_outlined,
            active: _selectedRegulation != null,
            onTap: () => _showPicker(
              context,
              'Select Format',
              ['All', ...regs],
              (v) => setState(() => _selectedRegulation = v == 'All' ? null : v),
            ),
          ),
          _filterChip(
            label: _selectedNation ?? 'All Nations',
            icon: Icons.flag_outlined,
            active: _selectedNation != null,
            onTap: () => _showPicker(
              context,
              'Select Nation',
              ['All', ...nations],
              (v) => setState(() => _selectedNation = v == 'All' ? null : v),
            ),
          ),
          _filterChip(
            label: _selectedDeck?.name ?? 'No Deck',
            icon: Icons.style_outlined,
            active: _selectedDeck != null,
            onTap: () => _showPicker(
              context,
              'Deck Context',
              ['None', ...decks.map((d) => d.name)],
              (v) => setState(() {
                _selectedDeck = v == 'None'
                    ? null
                    : decks.firstWhere((d) => d.name == v);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF60A5FA).withValues(alpha: 0.15)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? const Color(0xFF60A5FA).withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: active ? const Color(0xFF60A5FA) : Colors.white54),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? const Color(0xFF60A5FA) : Colors.white60,
                fontSize: 12,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more,
                size: 14,
                color: active ? const Color(0xFF60A5FA) : Colors.white38),
          ],
        ),
      ),
    );
  }

  // ── Results list ───────────────────────────────────────────────────────────
  Widget _buildResults() {
    final resultsAsync = ref.watch(recommendationResultProvider(_input));

    return resultsAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF60A5FA)),
            SizedBox(height: 16),
            Text('Computing recommendations…',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
      ),
      error: (e, _) => Center(
        child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent)),
      ),
      data: (recs) {
        if (recs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64,
                    color: Colors.white.withValues(alpha: 0.15)),
                const SizedBox(height: 16),
                const Text('No recommendations found',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Try removing filters or choosing a different card.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 13)),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                '${recs.length} Replacements Found',
                style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                itemCount: recs.length,
                itemBuilder: (context, i) =>
                    _RecommendationCard(rec: recs[i]),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Picker modal ───────────────────────────────────────────────────────────
  void _showPicker(BuildContext context, String title, List<String> options,
      void Function(String) onSelected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  )),
            ),
            ...options.map(
              (opt) => ListTile(
                title: Text(opt,
                    style: const TextStyle(color: Colors.white70, fontSize: 14)),
                onTap: () {
                  onSelected(opt);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _tagChip(MechanicTag tag, {bool small = false}) {
    final color = _tagColor(tag);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 6 : 8, vertical: small ? 2 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        tag.label,
        style: TextStyle(
          color: color,
          fontSize: small ? 9.5 : 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ── Individual recommendation card widget ─────────────────────────────────────

class _RecommendationCard extends StatelessWidget {
  final CardRecommendation rec;
  const _RecommendationCard({required this.rec});

  @override
  Widget build(BuildContext context) {
    final card = rec.card;
    final score = rec.similarityScore;
    final scoreColor = score >= 0.75
        ? const Color(0xFF34D399)
        : score >= 0.5
            ? const Color(0xFF60A5FA)
            : const Color(0xFFFBBF24);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CardDetailScreen(card: card)),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: rec.isInDeck
                  ? const Color(0xFF34D399).withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Card image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: card.imageUrl,
                        width: 48,
                        height: 68,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                            width: 48, height: 68, color: Colors.black26),
                        errorWidget: (_, __, ___) => Container(
                          width: 48,
                          height: 68,
                          color: Colors.black26,
                          child: const Icon(Icons.broken_image,
                              size: 20, color: Colors.white38),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name + in-deck badge
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  card.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (rec.isInDeck) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF34D399)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: const Color(0xFF34D399)
                                            .withValues(alpha: 0.4)),
                                  ),
                                  child: const Text('In Deck',
                                      style: TextStyle(
                                          color: Color(0xFF34D399),
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Score bar
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: score,
                                    minHeight: 5,
                                    backgroundColor: Colors.black26,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(scoreColor),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                rec.scorePercent,
                                style: TextStyle(
                                  color: scoreColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rec.scoreLabel,
                            style: TextStyle(
                                color: scoreColor.withValues(alpha: 0.7),
                                fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Matched tags
                if (rec.matchedTags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: rec.matchedTags
                        .map((t) => _tagChip(t))
                        .toList(),
                  ),
                ],
                // Reasons
                if (rec.reasons.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    rec.reasons.join(' • '),
                    style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tagChip(MechanicTag tag) {
    final color = _tagColor(tag);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        tag.label,
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

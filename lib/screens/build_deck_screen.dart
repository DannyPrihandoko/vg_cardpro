import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../providers/card_provider.dart';
import '../models/vg_card.dart';
import '../models/saved_deck.dart';
import 'deck_share_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Per-deck ephemeral state providers (family by deckId)
// ─────────────────────────────────────────────────────────────────────────────

// ── Ephemeral: ride line slots ──────────────────────────────────────────────
class _RideLineNotifier extends AutoDisposeNotifier<Map<int, VgCard?>> {
  @override
  Map<int, VgCard?> build() => {0: null, 1: null, 2: null, 3: null};

  void setSlot(int grade, VgCard? card) {
    state = {...state, grade: card};
  }
}

final _editRideLineProvider =
    NotifierProvider.autoDispose<_RideLineNotifier, Map<int, VgCard?>>(
  _RideLineNotifier.new,
);

// ── Ephemeral: main deck items ──────────────────────────────────────────────
class _DeckItemsNotifier extends AutoDisposeNotifier<List<DeckItem>> {
  @override
  List<DeckItem> build() => [];

  void setItems(List<DeckItem> items) => state = items;
}

final _editDeckItemsProvider =
    NotifierProvider.autoDispose<_DeckItemsNotifier, List<DeckItem>>(
  _DeckItemsNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// BuildDeckScreen
// ─────────────────────────────────────────────────────────────────────────────

class BuildDeckScreen extends ConsumerStatefulWidget {
  /// The deck being edited. Must be pre-loaded from DeckManagerNotifier.
  final SavedDeck deck;

  const BuildDeckScreen({super.key, required this.deck});

  @override
  ConsumerState<BuildDeckScreen> createState() => _BuildDeckScreenState();
}

class _BuildDeckScreenState extends ConsumerState<BuildDeckScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSaving = false;
  bool _isDirty = false; // has unsaved changes

  static const _gradeColors = [
    Color(0xFF34D399),
    Color(0xFF60A5FA),
    Color(0xFFA78BFA),
    Color(0xFFEF4444),
  ];
  static const _gradeLabels = ['Grade 0', 'Grade 1', 'Grade 2', 'Grade 3'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    // Seed ephemeral state from saved deck
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _seedFromDeck(widget.deck);
    });
  }

  void _seedFromDeck(SavedDeck deck) {
    // Seed ride line — set each slot individually
    final slots = Map<int, VgCard?>.from(deck.rideLineSlots);
    final rlNotifier = ref.read(_editRideLineProvider.notifier);
    for (int g = 0; g <= 3; g++) {
      rlNotifier.setSlot(g, slots[g]);
    }

    // Seed main deck items
    ref.read(_editDeckItemsProvider.notifier).setItems(
      deck.mainCards
          .map((e) => DeckItem(card: e.card, quantity: e.quantity))
          .toList(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Computed helpers ──────────────────────────────────────────────────────

  Map<int, VgCard?> get _rideLineSlots =>
      ref.read(_editRideLineProvider);

  List<DeckItem> get _deckItems =>
      ref.read(_editDeckItemsProvider);

  String? get _resolvedNation {
    final slots = _rideLineSlots;
    for (int g = 3; g >= 0; g--) {
      final c = slots[g];
      if (c != null && c.hasNation) return c.nation.trim();
    }
    return null;
  }

  int get _totalCards =>
      _deckItems.fold(0, (sum, item) => sum + item.quantity);
  int get _triggerCount =>
      _deckItems.fold(0, (s, i) => s + (i.card.isTriggerUnit ? i.quantity : 0));
  int get _healCount =>
      _deckItems.fold(0, (s, i) => s + (i.card.isHealTrigger ? i.quantity : 0));
  int get _overCount =>
      _deckItems.fold(0, (s, i) => s + (i.card.isOverTrigger ? i.quantity : 0));

  // ── Save deck ─────────────────────────────────────────────────────────────

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final slots = _rideLineSlots;
    final items = _deckItems;
    final updatedDeck = widget.deck.copyWith(
      rideLineSlots: slots,
      mainCards: items
          .map((i) => SavedDeckEntry(card: i.card, quantity: i.quantity))
          .toList(),
      updatedAt: DateTime.now(),
    );
    await ref.read(deckManagerProvider.notifier).saveDeck(updatedDeck);
    if (mounted) {
      setState(() {
        _isSaving = false;
        _isDirty = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ "${widget.deck.name}" saved!'),
          backgroundColor: Colors.greenAccent.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  void _showRenameDeckDialog() {
    String tempName = widget.deck.name;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text(
            'Rename Deck',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Deck Name',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. Bastion Apex Majesty',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: const Color(0xFFFFD700).withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
                  ),
                ),
                controller: TextEditingController(text: widget.deck.name),
                onChanged: (value) {
                  tempName = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.redAccent)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 4,
                shadowColor: const Color(0xFFFFD700).withOpacity(0.3),
              ),
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                if (tempName.trim().isNotEmpty) {
                  setState(() {
                    widget.deck.name = tempName.trim();
                  });
                  _markDirty();
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // ── Add/Remove card from ephemeral deck ───────────────────────────────────

  /// Count how many times [card] appears in the current ride line slots.
  int _rideLineCountForCard(VgCard card) {
    int count = 0;
    final slots = _rideLineSlots;
    for (int g = 0; g <= 3; g++) {
      if (slots[g]?.id == card.id) count++;
    }
    return count;
  }

  String? _addCard(VgCard card) {
    final items = List<DeckItem>.from(_deckItems);
    final nation = _resolvedNation;

    if (_totalCards >= 50) return 'Deck is already full (maximum 50 cards)!';
    if (nation != null && card.hasNation && card.nation.trim() != nation) {
      return 'Only $nation cards (or no-nation cards) can be added!';
    }
    if (card.isTriggerUnit) {
      if (_triggerCount >= 16) return 'Trigger limit reached! Max 16 triggers.';
      if (card.isHealTrigger && _healCount >= 4) {
        return 'Heal trigger limit reached! Max 4 heal triggers.';
      }
      if (card.isOverTrigger && _overCount >= 1) {
        return 'Over trigger limit reached! Max 1 over trigger.';
      }
    }

    // ── Playset limit: ride line copies count toward the 4-copy max ──────────
    final rideLineCount = _rideLineCountForCard(card);
    final maxAllowed = 4 - rideLineCount; // e.g. 1 in ride line → max 3 in main

    final idx = items.indexWhere((i) => i.card.id == card.id);
    if (idx != -1) {
      if (items[idx].quantity >= maxAllowed) {
        if (rideLineCount > 0) {
          return "'${card.name}' is already in the ride line ($rideLineCount×). Max ${maxAllowed} more in main deck.";
        }
        return "Max 4 copies of '${card.name}'!";
      }
      items[idx] = DeckItem(card: card, quantity: items[idx].quantity + 1);
    } else {
      if (maxAllowed <= 0) {
        return "'${card.name}' is already used $rideLineCount× in the ride line (max 4 total).";
      }
      items.add(DeckItem(card: card, quantity: 1));
    }
    ref.read(_editDeckItemsProvider.notifier).setItems(items);
    _markDirty();
    return null;
  }

  void _removeCard(VgCard card) {
    final items = List<DeckItem>.from(_deckItems);
    final idx = items.indexWhere((i) => i.card.id == card.id);
    if (idx == -1) return;
    if (items[idx].quantity > 1) {
      items[idx] = DeckItem(card: card, quantity: items[idx].quantity - 1);
    } else {
      items.removeAt(idx);
    }
    ref.read(_editDeckItemsProvider.notifier).setItems(items);
    _markDirty();
  }

  void _setRideLineSlot(int grade, VgCard? card) {
    ref.read(_editRideLineProvider.notifier).setSlot(grade, card);
    _markDirty();
  }

  void _openMainDeckPicker(BuildContext context, String? allowedNation) {
    final currentSlots = _rideLineSlots;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.97,
        builder: (ctx, scrollController) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: _EphemeralMainDeckPicker(
            allowedNation: allowedNation,
            rideLineSlots: currentSlots,
            onAddCard: _addCard,
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch ephemeral providers to rebuild on changes
    final slots = ref.watch(_editRideLineProvider);
    final items = ref.watch(_editDeckItemsProvider);

    final nation = _resolvedNation;
    final total = items.fold(0, (s, i) => s + i.quantity);
    final isFull = total == 50;

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, nation, total, isFull),
              
              // High-fidelity progress indicator bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.flag_rounded, color: Color(0xFFFFD700), size: 14),
                            const SizedBox(width: 6),
                            Text(
                              nation != null ? 'Nation: $nation' : 'Set Ride Line first',
                              style: TextStyle(
                                color: nation != null ? const Color(0xFFFFD700) : Colors.white38,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$total / 50 cards',
                          style: TextStyle(
                            color: isFull
                                ? const Color(0xFF66BB6A) // completion green
                                : (total > 50
                                    ? const Color(0xFFEF5350) // warning red
                                    : const Color(0xFFFFD700)), // gold
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: 6,
                        color: const Color(0xFF1E293B),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: (total / 50).clamp(0.0, 1.0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                color: isFull
                                    ? const Color(0xFF66BB6A)
                                    : (total > 50 ? const Color(0xFFEF5350) : const Color(0xFFFFD700)),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isFull
                                            ? const Color(0xFF66BB6A)
                                            : (total > 50 ? const Color(0xFFEF5350) : const Color(0xFFFFD700)))
                                        .withOpacity(0.5),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _RideLineTab(
                      deckId: widget.deck.id,
                      slots: slots,
                      gradeColors: _gradeColors,
                      gradeLabels: _gradeLabels,
                      onSetSlot: _setRideLineSlot,
                    ),
                    _MainDeckTab(
                      deckId: widget.deck.id,
                      items: items,
                      total: total,
                      triggerCount:
                          items.fold(0, (s, i) => s + (i.card.isTriggerUnit ? i.quantity : 0)),
                      healCount: items.fold(
                          0, (s, i) => s + (i.card.isHealTrigger ? i.quantity : 0)),
                      overCount: items.fold(
                          0, (s, i) => s + (i.card.isOverTrigger ? i.quantity : 0)),
                      allowedNation: nation,
                      onAddCard: _addCard,
                      onRemoveCard: _removeCard,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: () => _openMainDeckPicker(context, nation),
              backgroundColor: const Color(0xFFFFD700),
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text('Add Card',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildHeader(
      BuildContext context, String? nation, int total, bool isFull) {
    final saveButtonActive = _isDirty && !_isSaving;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white70, size: 20),
            onPressed: () async {
              if (_isDirty) {
                final save = await _showUnsavedDialog();
                if (save == true) await _save();
              }
              if (context.mounted) context.pop();
            },
          ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              onTap: _showRenameDeckDialog,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      widget.deck.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.edit_outlined, size: 14, color: Color(0xFFFFD700)),
                ],
              ),
            ),
          ),

          // Share button
          IconButton(
            icon: const Icon(Icons.share_rounded,
                color: Colors.white54, size: 20),
            tooltip: 'Share Deck',
            onPressed: () => showDeckShareSheet(context, widget.deck),
          ),

          // Save button - Slate-and-Gold themed
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: saveButtonActive
                    ? const Color(0xFFFFD700)
                    : Colors.white.withOpacity(0.07),
                foregroundColor:
                    saveButtonActive ? Colors.black : Colors.white38,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: saveButtonActive ? 4 : 0,
                shadowColor: saveButtonActive
                    ? const Color(0xFFFFD700).withOpacity(0.3)
                    : Colors.transparent,
              ),
              onPressed: saveButtonActive ? _save : null,
              icon: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : Icon(Icons.save_outlined, size: 16, color: saveButtonActive ? Colors.black : Colors.white38),
              label: Text(
                _isSaving ? 'Saving…' : 'Save',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13, color: saveButtonActive ? Colors.black : Colors.white38),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: const Color(0xFFFFD700).withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4), width: 1),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: const Color(0xFFFFD700),
          unselectedLabelColor: Colors.grey[400],
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swap_vert_circle_outlined, size: 16),
                  SizedBox(width: 6),
                  Text('RIDE LINE'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.style_outlined, size: 16),
                  SizedBox(width: 6),
                  Text('MAIN DECK'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showUnsavedDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Unsaved Changes',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'You have unsaved changes. Save before leaving?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text('Discard',
                style: TextStyle(color: Colors.redAccent)),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1: Ride Line
// ─────────────────────────────────────────────────────────────────────────────

class _RideLineTab extends StatelessWidget {
  final String deckId;
  final Map<int, VgCard?> slots;
  final List<Color> gradeColors;
  final List<String> gradeLabels;
  final void Function(int grade, VgCard? card) onSetSlot;

  const _RideLineTab({
    required this.deckId,
    required this.slots,
    required this.gradeColors,
    required this.gradeLabels,
    required this.onSetSlot,
  });

  @override
  Widget build(BuildContext context) {
    final nation = _derivedNation;
    final isComplete = slots.values.every((c) => c != null);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        _buildInfoBanner(nation, isComplete),
        const SizedBox(height: 20),
        ...List.generate(4, (g) {
          return _buildGradeSlot(context, g, slots[g]);
        }),
      ],
    );
  }

  String? get _derivedNation {
    for (int g = 3; g >= 0; g--) {
      final c = slots[g];
      if (c != null && c.hasNation) return c.nation.trim();
    }
    return null;
  }

  Widget _buildInfoBanner(String? nation, bool isComplete) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline,
                  color: Color(0xFFFFD700), size: 16),
              const SizedBox(width: 8),
              const Text('Ride Line (4 cards)',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              const Spacer(),
              if (isComplete)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF66BB6A).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF66BB6A).withValues(alpha: 0.3)),
                  ),
                  child: const Text('✓ Complete',
                      style: TextStyle(
                          color: Color(0xFF66BB6A),
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.2)),
                  ),
                  child: const Text('Incomplete',
                      style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Select one card per grade (G0→G3). The nation determines which cards you can add to your main deck.',
            style: TextStyle(
                color: Colors.white60, fontSize: 11.5, height: 1.4),
          ),
          if (nation != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.flag_rounded,
                      color: Color(0xFFFFD700), size: 14),
                  const SizedBox(width: 6),
                  Text('Deck Nation: $nation',
                      style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGradeSlot(BuildContext context, int grade, VgCard? card) {
    final color = gradeColors[grade];
    final label = gradeLabels[grade];
    final isFilled = card != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isFilled
                ? color.withValues(alpha: 0.5)
                : color.withValues(alpha: 0.15),
            width: isFilled ? 1.5 : 1,
          ),
          boxShadow: isFilled
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.1),
                    blurRadius: 12,
                  )
                ]
              : [],
        ),
        child: isFilled
            ? _buildFilledSlot(context, grade, card!, color, label)
            : _buildEmptySlot(context, grade, color, label),
      ),
    );
  }

  Widget _buildEmptySlot(
      BuildContext context, int grade, Color color, String label) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openPicker(context, grade),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 70,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.25), width: 1.2),
              ),
              child: Center(
                child: Icon(Icons.add,
                    color: color, size: 22),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _gradeBadge(label, color),
                  const SizedBox(height: 6),
                  const Text('Tap to select a card',
                      style: TextStyle(color: Colors.white38, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: color.withValues(alpha: 0.5), size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildFilledSlot(BuildContext context, int grade, VgCard card,
      Color color, String label) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _openPicker(context, grade),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: card.imageUrl,
                width: 50,
                height: 70,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                    width: 50,
                    height: 70,
                    color: color.withValues(alpha: 0.1)),
                errorWidget: (_, __, ___) => Container(
                  width: 50,
                  height: 70,
                  color: Colors.black26,
                  child: const Icon(Icons.broken_image,
                      size: 18, color: Colors.white24),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _gradeBadge(label, color),
                const SizedBox(height: 6),
                Text(card.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    if (card.clan.isNotEmpty && card.clan != '-')
                      _miniChip(card.clan, Colors.blueAccent),
                    if (card.nation.isNotEmpty && card.nation != '-')
                      _miniChip(card.nation, Colors.redAccent),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _openPicker(context, grade),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_outlined,
                      color: Colors.white70, size: 16),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => onSetSlot(grade, null),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.close,
                      color: Colors.redAccent, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gradeBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _miniChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.2)),
      ),
      child: Text(text,
          style: const TextStyle(
              color: Color(0xFFFFD700), fontSize: 9, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
    );
  }

  void _openPicker(BuildContext context, int grade) {
    // Temporarily override global rideLineProvider with this deck's slots
    // We use a custom picker that calls onSetSlot
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.97,
        builder: (ctx, scrollController) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: _EphemeralRideLinePicker(
            grade: grade,
            currentSlots: slots,
            onSelected: (card) => onSetSlot(grade, card),
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ephemeral Ride Line Picker (does not use global rideLineProvider)
// ─────────────────────────────────────────────────────────────────────────────

class _EphemeralRideLinePicker extends ConsumerStatefulWidget {
  final int grade;
  final Map<int, VgCard?> currentSlots;
  final void Function(VgCard card) onSelected;
  final ScrollController scrollController;

  const _EphemeralRideLinePicker({
    required this.grade,
    required this.currentSlots,
    required this.onSelected,
    required this.scrollController,
  });

  @override
  ConsumerState<_EphemeralRideLinePicker> createState() =>
      _EphemeralRideLinePickerState();
}

class _EphemeralRideLinePickerState
    extends ConsumerState<_EphemeralRideLinePicker> {
  String _query = '';

  static const _gradeColors = [
    Color(0xFF34D399),
    Color(0xFF60A5FA),
    Color(0xFFA78BFA),
    Color(0xFFEF4444),
  ];

  Color get _gradeColor => _gradeColors[widget.grade.clamp(0, 3)];

  String? get _allowedNation {
    for (int g = 3; g >= 0; g--) {
      final c = widget.currentSlots[g];
      if (c != null && c.hasNation) return c.nation.trim();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(cardListProvider);
    final nation = _allowedNation;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Select Grade ${widget.grade}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        if (nation != null)
                          Text('Nation: $nation',
                              style: TextStyle(
                                  color: _gradeColor.withValues(alpha: 0.8),
                                  fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search card name…',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: cardsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                    child: Text('Error: $e',
                        style: const TextStyle(color: Colors.white54))),
                data: (allCards) {
                  var filtered = allCards.where((c) {
                    final cardGrade = int.tryParse(c.grade.trim()) ?? -1;
                    return cardGrade == widget.grade && !c.isTriggerUnit;
                  }).toList();

                  if (nation != null) {
                    filtered = filtered
                        .where((c) => !c.hasNation || c.nation.trim() == nation)
                        .toList();
                  }
                  if (_query.isNotEmpty) {
                    filtered = filtered
                        .where((c) =>
                            c.name.toLowerCase().contains(_query))
                        .toList();
                  }

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 60,
                              color: _gradeColor.withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          const Text('No cards found',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 16)),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    controller: widget.scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final card = filtered[i];
                      final isSelected =
                          widget.currentSlots[widget.grade]?.id == card.id;
                      return _CardTile(
                        card: card,
                        isSelected: isSelected,
                        gradeColor: _gradeColor,
                        onTap: () {
                          widget.onSelected(card);
                          Navigator.of(context).pop();
                        },
                      );
                    },
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

class _CardTile extends StatelessWidget {
  final VgCard card;
  final bool isSelected;
  final Color gradeColor;
  final VoidCallback onTap;
  final int quantity;
  final int rideLineCount;

  const _CardTile({
    required this.card,
    required this.isSelected,
    required this.gradeColor,
    required this.onTap,
    this.quantity = 0,
    this.rideLineCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final totalCopies = quantity + rideLineCount;
    final isCapped = totalCopies >= 4;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCapped
                ? Colors.redAccent.withValues(alpha: 0.5)
                : isSelected
                    ? const Color(0xFFFFD700)
                    : Colors.white.withValues(alpha: 0.06),
            width: isSelected || isCapped ? 2.0 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                    blurRadius: 10,
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
                placeholder: (_, __) => Container(
                  color: const Color(0xFF1E293B),
                  child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: gradeColor),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: const Color(0xFF1E293B),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.broken_image,
                          color: Colors.white24, size: 24),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(card.name,
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 9),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
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
                child: Text(card.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center),
              ),
            ),
            Positioned(
              top: 6, left: 6,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: gradeColor.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('G${card.grade}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            // Ride line badge (purple, bottom-left next to grade)
            if (rideLineCount > 0)
              Positioned(
                bottom: 28, left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'RL×$rideLineCount',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            // Quantity badge (gold, top-right)
            if (quantity > 0)
              Positioned(
                top: 6, right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isCapped ? Colors.redAccent : const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: (isCapped ? Colors.redAccent : const Color(0xFFFFD700))
                            .withValues(alpha: 0.3),
                        blurRadius: 4,
                      )
                    ],
                  ),
                  child: Text(
                    'x$quantity',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            else if (rideLineCount > 0 && quantity == 0)
              // Show only the "capped" indicator if all copies are in ride line
              const SizedBox.shrink()
            else if (isSelected)
              Positioned(
                top: 6, right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD700),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.black, size: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2: Main Deck (50 cards)
// ─────────────────────────────────────────────────────────────────────────────


class _MainDeckTab extends StatelessWidget {
  final String deckId;
  final List<DeckItem> items;
  final int total;
  final int triggerCount;
  final int healCount;
  final int overCount;
  final String? allowedNation;
  final String? Function(VgCard) onAddCard;
  final void Function(VgCard) onRemoveCard;

  const _MainDeckTab({
    required this.deckId,
    required this.items,
    required this.total,
    required this.triggerCount,
    required this.healCount,
    required this.overCount,
    required this.allowedNation,
    required this.onAddCard,
    required this.onRemoveCard,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: _buildStatsCard(),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: items.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _buildCardItem(context, items[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    final isFull = total == 50;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isFull
              ? const Color(0xFF66BB6A).withValues(alpha: 0.4)
              : const Color(0xFFFFD700).withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isFull ? Icons.check_circle : Icons.info_outline,
                    color: isFull ? const Color(0xFF66BB6A) : const Color(0xFFFFD700),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isFull ? 'Ready to Duel!' : 'Deck Status',
                    style: TextStyle(
                      color: isFull ? const Color(0xFF66BB6A) : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Text('$total / 50',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (total / 50.0).clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: Colors.black26,
              valueColor: AlwaysStoppedAnimation<Color>(
                isFull ? const Color(0xFF66BB6A) : const Color(0xFFFFD700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statBadge(Icons.bolt, '$triggerCount/16', 'Triggers',
                  Colors.yellowAccent, triggerCount >= 16),
              const SizedBox(width: 8),
              _statBadge(Icons.favorite, '$healCount/4', 'Heal',
                  Colors.pinkAccent, healCount >= 4),
              const SizedBox(width: 8),
              _statBadge(Icons.flash_on, '$overCount/1', 'Over',
                  Colors.purpleAccent, overCount >= 1),
            ],
          ),
          if (allowedNation != null) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flag_rounded,
                      color: Color(0xFFFFD700), size: 13),
                  const SizedBox(width: 6),
                  Text('Nation: $allowedNation (+ no-nation cards)',
                      style: const TextStyle(
                          color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statBadge(IconData icon, String value, String label, Color color,
      bool warn) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: warn
              ? color.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: warn
                  ? color.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.06)),
          boxShadow: warn
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 8,
                    spreadRadius: 0.5,
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: warn ? color : Colors.white38, size: 16),
            const SizedBox(height: 3),
            Text(value,
                style: TextStyle(
                    color: warn ? color : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            Text(label,
                style: TextStyle(
                    color: warn ? color.withValues(alpha: 0.7) : Colors.white24,
                    fontSize: 9)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.style_outlined,
                size: 72, color: Colors.white.withValues(alpha: 0.1)),
            const SizedBox(height: 20),
            const Text('No cards in deck',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Browse the Cards tab, then tap "Add to Deck" on any card.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white38, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardItem(BuildContext context, DeckItem item) {
    final card = item.card;
    final qty = item.quantity;

    Color trigColor = Colors.yellowAccent;
    String? trigLabel;
    if (card.isOverTrigger) {
      trigColor = Colors.purpleAccent;
      trigLabel = 'Over';
    } else if (card.isHealTrigger) {
      trigColor = Colors.pinkAccent;
      trigLabel = 'Heal';
    } else if (card.isTriggerUnit) {
      trigLabel = 'Trigger';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        margin: EdgeInsets.zero,
        color: const Color(0xFF1E293B),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push('/detail', extra: card),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: card.imageUrl,
                    width: 46,
                    height: 64,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(width: 46, height: 64, color: Colors.black26),
                    errorWidget: (_, __, ___) => Container(
                        width: 46,
                        height: 64,
                        color: Colors.black26,
                        child: const Icon(Icons.broken_image, size: 18)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(card.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 5,
                        children: [
                          if (card.grade.isNotEmpty && card.grade != '-')
                            _badge('G${card.grade}', Colors.orange),
                          if (card.clan.isNotEmpty && card.clan != '-')
                            _badge(card.clan, Colors.blueAccent),
                          if (trigLabel != null)
                            _badge(trigLabel, trigColor),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => onRemoveCard(card),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.remove, color: Colors.white70, size: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 24,
                      child: Center(
                        child: Text(
                          '$qty',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: qty >= 4
                          ? null
                          : () {
                              final err = onAddCard(card);
                              if (err != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(err),
                                    backgroundColor: Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: qty >= 4 
                              ? Colors.white.withValues(alpha: 0.02)
                              : const Color(0xFFFFD700).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: qty >= 4
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : const Color(0xFFFFD700).withValues(alpha: 0.2)),
                        ),
                        child: Icon(Icons.add,
                            color: qty >= 4 ? Colors.white30 : const Color(0xFFFFD700),
                            size: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}

class _EphemeralMainDeckPicker extends ConsumerStatefulWidget {
  final String? allowedNation;
  final Map<int, VgCard?> rideLineSlots;
  final String? Function(VgCard) onAddCard;
  final ScrollController scrollController;

  const _EphemeralMainDeckPicker({
    required this.allowedNation,
    required this.rideLineSlots,
    required this.onAddCard,
    required this.scrollController,
  });

  @override
  ConsumerState<_EphemeralMainDeckPicker> createState() =>
      _EphemeralMainDeckPickerState();
}

class _EphemeralMainDeckPickerState
    extends ConsumerState<_EphemeralMainDeckPicker> {
  String _query = '';
  String _selectedGrade = 'All';
  String _selectedType = 'All';

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFD700).withValues(alpha: 0.15)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFD700)
                : Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                    blurRadius: 8,
                    spreadRadius: 0.5,
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFFFD700) : Colors.white60,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(cardListProvider);
    final currentItems = ref.watch(_editDeckItemsProvider);
    final nation = widget.allowedNation;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Add to Main Deck',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        if (nation != null)
                          Text('Nation: $nation',
                              style: TextStyle(
                                  color: Colors.blueAccent.withOpacity(0.8),
                                  fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search card name…',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Grade Filter Row
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterChip(
                    label: 'All Grades',
                    isSelected: _selectedGrade == 'All',
                    onTap: () => setState(() => _selectedGrade = 'All'),
                  ),
                  const SizedBox(width: 8),
                  ...['G0', 'G1', 'G2', 'G3'].map((g) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterChip(
                        label: g,
                        isSelected: _selectedGrade == g,
                        onTap: () => setState(() => _selectedGrade = g),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Type Filter Row
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterChip(
                    label: 'All Types',
                    isSelected: _selectedType == 'All',
                    onTap: () => setState(() => _selectedType = 'All'),
                  ),
                  const SizedBox(width: 8),
                  ...['Normal Unit', 'Trigger Unit'].map((t) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterChip(
                        label: t,
                        isSelected: _selectedType == t,
                        onTap: () => setState(() => _selectedType = t),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: cardsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                    child: Text('Error: $e',
                        style: const TextStyle(color: Colors.white54))),
                data: (allCards) {
                  var filtered = allCards;

                  if (nation != null) {
                    filtered = filtered
                        .where((c) => !c.hasNation || c.nation.trim() == nation)
                        .toList();
                  }

                  // Grade Filter
                  if (_selectedGrade != 'All') {
                    final gradeVal = _selectedGrade.replaceAll('G', '');
                    filtered = filtered.where((c) => c.grade.trim() == gradeVal).toList();
                  }

                  // Type Filter
                  if (_selectedType != 'All') {
                    if (_selectedType == 'Normal Unit') {
                      filtered = filtered.where((c) => !c.isTriggerUnit).toList();
                    } else if (_selectedType == 'Trigger Unit') {
                      filtered = filtered.where((c) => c.isTriggerUnit).toList();
                    }
                  }

                  if (_query.isNotEmpty) {
                    filtered = filtered
                        .where((c) => c.name.toLowerCase().contains(_query))
                        .toList();
                  }

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 60,
                              color: Colors.blueAccent.withOpacity(0.3)),
                          const SizedBox(height: 12),
                          const Text('No cards found',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 16)),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    controller: widget.scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final card = filtered[i];
                      final qtyInDeck = currentItems
                          .firstWhere((item) => item.card.id == card.id,
                              orElse: () => DeckItem(card: card, quantity: 0))
                          .quantity;
                      // Count ride line copies for this card
                      int rideCount = 0;
                      widget.rideLineSlots.forEach((_, c) {
                        if (c?.id == card.id) rideCount++;
                      });
                      final isSelected = qtyInDeck > 0 || rideCount > 0;

                      return _CardTile(
                        card: card,
                        isSelected: isSelected,
                        quantity: qtyInDeck,
                        rideLineCount: rideCount,
                        gradeColor: Colors.blueAccent,
                        onTap: () {
                          final err = widget.onAddCard(card);
                          ScaffoldMessenger.of(context).clearSnackBars();
                          if (err != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(err),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added "${card.name}"'),
                                backgroundColor: Colors.greenAccent.shade700,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(milliseconds: 1200),
                              ),
                            );
                          }
                        },
                      );
                    },
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

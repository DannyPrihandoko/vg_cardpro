import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/card_provider.dart';
import '../models/saved_deck.dart';

class DeckListScreen extends ConsumerWidget {
  const DeckListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(deckManagerProvider);

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
              _buildHeader(context, ref),
              const SizedBox(height: 4),
              Expanded(
                child: decksAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent),
                  ),
                  error: (e, _) => Center(
                    child: Text('Error: $e',
                        style: const TextStyle(color: Colors.white54)),
                  ),
                  data: (decks) => decks.isEmpty
                      ? _buildEmptyState(context, ref)
                      : _buildDeckList(context, ref, decks),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFab(context, ref),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.blueAccent.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.layers_rounded,
                color: Colors.blueAccent, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Decks',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Vanguard Deck Collection',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withValues(alpha: 0.05),
              ),
              child: Icon(
                Icons.library_add_outlined,
                size: 80,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No decks yet',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tap the + button to create your first Vanguard deck.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white38, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => _showCreateDeckDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Create New Deck',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeckList(
      BuildContext context, WidgetRef ref, List<SavedDeck> decks) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: decks.length,
      itemBuilder: (context, index) {
        return _buildDeckCard(context, ref, decks[index]);
      },
    );
  }

  Widget _buildDeckCard(BuildContext context, WidgetRef ref, SavedDeck deck) {
    final totalCards = deck.totalMainCards;
    final progress = totalCards / 50.0;
    final nation = deck.nation;
    final isComplete = deck.isComplete;

    Color nationColor = Colors.blueAccent;
    IconData nationIcon = Icons.public;
    if (nation != null) {
      nationColor = _nationColor(nation);
      nationIcon = _nationIcon(nation);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push('/deck-editor', extra: deck),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isComplete
                    ? Colors.greenAccent.withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.07),
              ),
              boxShadow: isComplete
                  ? [
                      BoxShadow(
                        color: Colors.greenAccent.withValues(alpha: 0.06),
                        blurRadius: 16,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Row 1: Title + actions ───────────────────────────
                  Row(
                    children: [
                      // Nation icon bubble
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: nationColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: nationColor.withValues(alpha: 0.25)),
                        ),
                        child: Icon(nationIcon, color: nationColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              deck.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            if (nation != null)
                              Text(
                                nation,
                                style: TextStyle(
                                    color: nationColor.withValues(alpha: 0.8),
                                    fontSize: 11),
                              )
                            else
                              const Text(
                                'No ride line set',
                                style: TextStyle(
                                    color: Colors.white38, fontSize: 11),
                              ),
                          ],
                        ),
                      ),
                      // Complete badge
                      if (isComplete)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color:
                                    Colors.greenAccent.withValues(alpha: 0.35)),
                          ),
                          child: const Text(
                            '✓ Ready',
                            style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      const SizedBox(width: 4),
                      // Action menu
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert,
                            color: Colors.white38, size: 20),
                        color: const Color(0xFF334155),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        onSelected: (value) =>
                            _handleDeckAction(context, ref, deck, value),
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'rename',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined,
                                    color: Colors.white70, size: 18),
                                SizedBox(width: 10),
                                Text('Rename',
                                    style: TextStyle(color: Colors.white70)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline,
                                    color: Colors.redAccent, size: 18),
                                SizedBox(width: 10),
                                Text('Delete',
                                    style: TextStyle(color: Colors.redAccent)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ── Row 2: Stats chips ────────────────────────────────
                  Row(
                    children: [
                      _statChip(
                          Icons.style_outlined,
                          '$totalCards/50',
                          'cards',
                          totalCards == 50 ? Colors.greenAccent : Colors.white54),
                      const SizedBox(width: 8),
                      _statChip(
                          Icons.swap_vert_circle_outlined,
                          deck.isRideLineComplete ? '4/4' : '${_rideCount(deck)}/4',
                          'ride line',
                          deck.isRideLineComplete ? Colors.blueAccent : Colors.white38),
                      const SizedBox(width: 8),
                      _statChip(
                          Icons.bolt,
                          '${deck.triggerCount}/16',
                          'triggers',
                          deck.triggerCount >= 16
                              ? Colors.yellowAccent
                              : Colors.white38),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── Progress bar ──────────────────────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: Colors.black26,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        totalCards == 50 ? Colors.greenAccent : Colors.blueAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color.withValues(alpha: 0.8)),
            const SizedBox(width: 5),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                      maxLines: 1),
                  Text(label,
                      style: TextStyle(
                          color: color.withValues(alpha: 0.5), fontSize: 8),
                      maxLines: 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      backgroundColor: Colors.blueAccent,
      foregroundColor: Colors.white,
      elevation: 6,
      onPressed: () => _showCreateDeckDialog(context, ref),
      icon: const Icon(Icons.add),
      label: const Text('New Deck',
          style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  int _rideCount(SavedDeck deck) {
    int count = 0;
    for (int g = 0; g <= 3; g++) {
      if (deck.rideLineSlots[g] != null) count++;
    }
    return count;
  }

  Color _nationColor(String nation) {
    final n = nation.toLowerCase();
    if (n.contains('dragon')) return const Color(0xFFEF4444);
    if (n.contains('dark')) return const Color(0xFF6366F1);
    if (n.contains('brandt')) return const Color(0xFFF59E0B);
    if (n.contains('keter')) return const Color(0xFFA78BFA);
    if (n.contains('stoicheia')) return const Color(0xFF34D399);
    if (n.contains('lyrical')) return const Color(0xFFF472B6);
    return Colors.blueAccent;
  }

  IconData _nationIcon(String nation) {
    final n = nation.toLowerCase();
    if (n.contains('dragon')) return Icons.local_fire_department;
    if (n.contains('dark')) return Icons.nightlight_round;
    if (n.contains('brandt')) return Icons.bolt;
    if (n.contains('keter')) return Icons.auto_awesome;
    if (n.contains('stoicheia')) return Icons.eco;
    if (n.contains('lyrical')) return Icons.music_note;
    return Icons.public;
  }

  Future<void> _showCreateDeckDialog(
      BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('New Deck',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Give your new deck a name.',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. Dark States Aggro',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blueAccent),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white38)),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (confirmed == true && ctrl.text.trim().isNotEmpty && context.mounted) {
      final deck = await ref
          .read(deckManagerProvider.notifier)
          .createDeck(ctrl.text.trim());
      if (context.mounted) {
        context.push('/deck-editor', extra: deck);
      }
    }
  }

  Future<void> _handleDeckAction(
      BuildContext context, WidgetRef ref, SavedDeck deck, String action) async {
    if (action == 'rename') {
      await _showRenameDialog(context, ref, deck);
    } else if (action == 'delete') {
      await _showDeleteConfirmation(context, ref, deck);
    }
  }

  Future<void> _showRenameDialog(
      BuildContext context, WidgetRef ref, SavedDeck deck) async {
    final ctrl = TextEditingController(text: deck.name);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Rename Deck',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0F172A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blueAccent),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white38)),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true && ctrl.text.trim().isNotEmpty && context.mounted) {
      await ref
          .read(deckManagerProvider.notifier)
          .renameDeck(deck.id, ctrl.text.trim());
    }
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, SavedDeck deck) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Deck?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to permanently delete "${deck.name}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white38)),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(deckManagerProvider.notifier).deleteDeck(deck.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${deck.name}" deleted.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

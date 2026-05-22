import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../models/saved_deck.dart';
import '../providers/card_provider.dart';
import '../services/deck_share_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Deck Share Screen (shown as a modal bottom sheet)
// ─────────────────────────────────────────────────────────────────────────────

class DeckShareSheet extends ConsumerStatefulWidget {
  final SavedDeck deck;

  const DeckShareSheet({super.key, required this.deck});

  @override
  ConsumerState<DeckShareSheet> createState() => _DeckShareSheetState();
}

class _DeckShareSheetState extends ConsumerState<DeckShareSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final String _shareCode;
  bool _codeCopied = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _shareCode = DeckShareService.encode(widget.deck);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: _shareCode));
    setState(() => _codeCopied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _codeCopied = false);
  }

  Future<void> _shareViaSystem() async {
    final text = DeckShareService.shareText(widget.deck, _shareCode);
    await Share.share(text, subject: 'VG Deck: ${widget.deck.name}');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFFFD700).withOpacity(0.25)),
                    ),
                    child: const Icon(Icons.share_rounded,
                        color: Color(0xFFFFD700), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Share Deck',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold)),
                        Text(widget.deck.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Tab bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                        color: const Color(0xFFFFD700).withOpacity(0.4)),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: const Color(0xFFFFD700),
                  unselectedLabelColor: Colors.white54,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_2_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('QR Code'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.text_snippet_outlined, size: 16),
                          SizedBox(width: 6),
                          Text('Share ID'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Tab content — fixed height
            SizedBox(
              height: 340,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildQrTab(),
                  _buildShareIdTab(),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── QR Tab ─────────────────────────────────────────────────────────────────

  Widget _buildQrTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: QrImageView(
              data: _shareCode,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF0F172A),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Scan this QR code with VG CardPro to import "${widget.deck.name}"',
            textAlign: TextAlign.center,
            style:
                const TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 16),
          _buildShareButton(),
        ],
      ),
    );
  }

  // ── Share ID Tab ────────────────────────────────────────────────────────────

  Widget _buildShareIdTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Share Code',
            style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          // Code container
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  _shareCode,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10.5,
                    fontFamily: 'monospace',
                    height: 1.5,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 6,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        icon: _codeCopied
                            ? Icons.check_circle
                            : Icons.copy_rounded,
                        label: _codeCopied ? 'Copied!' : 'Copy Code',
                        color: _codeCopied
                            ? const Color(0xFF66BB6A)
                            : const Color(0xFFFFD700),
                        onTap: _copyCode,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _buildShareButton()),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: Colors.blueAccent.withOpacity(0.15)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    color: Colors.blueAccent, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Share this code with your opponent or teammate. '
                    'They can import it in VG CardPro → My Decks → Import Deck.',
                    style: TextStyle(
                        color: Colors.white54, fontSize: 11.5, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildDeckPreview(),
        ],
      ),
    );
  }

  Widget _buildShareButton() {
    return _actionButton(
      icon: Icons.ios_share_rounded,
      label: 'Share',
      color: Colors.blueAccent,
      onTap: _shareViaSystem,
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildDeckPreview() {
    final nation = widget.deck.nation ?? '—';
    final total = widget.deck.totalMainCards;
    final complete = widget.deck.isComplete;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.layers_rounded,
                color: Color(0xFFFFD700), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.deck.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 3),
                Text('$nation · $total/50 cards',
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          if (complete)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.greenAccent.withOpacity(0.3)),
              ),
              child: const Text('✓ Ready',
                  style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Import Deck Dialog
// ─────────────────────────────────────────────────────────────────────────────

class ImportDeckDialog extends ConsumerStatefulWidget {
  const ImportDeckDialog({super.key});

  @override
  ConsumerState<ImportDeckDialog> createState() => _ImportDeckDialogState();
}

class _ImportDeckDialogState extends ConsumerState<ImportDeckDialog> {
  int _activeTab = 0; // 0: Share Code, 1: Deck Log, 2: Plain Text
  final _shareCodeCtrl = TextEditingController();
  final _deckLogCtrl = TextEditingController();
  final _plainTextCtrl = TextEditingController();

  String? _error;
  bool _isImporting = false;

  // Post-import preview state
  SavedDeck? _importedDeck;
  List<String> _skippedItems = [];
  int _successCount = 0;
  int _totalCount = 0;

  @override
  void dispose() {
    _shareCodeCtrl.dispose();
    _deckLogCtrl.dispose();
    _plainTextCtrl.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    setState(() {
      _error = null;
      _isImporting = true;
    });

    try {
      SavedDeck? deck;
      List<String> skipped = [];
      int success = 0;
      int total = 0;

      if (_activeTab == 0) {
        // Custom base64 share code
        final code = _shareCodeCtrl.text.trim();
        if (code.isEmpty) {
          setState(() {
            _error = 'Please paste a share code.';
            _isImporting = false;
          });
          return;
        }
        final decoded = DeckShareService.decode(code);
        if (decoded == null) {
          setState(() {
            _error = 'Invalid share code. Please check and try again.';
            _isImporting = false;
          });
          return;
        }
        deck = decoded;
        success = decoded.totalMainCards + decoded.rideLineSlots.values.where((c) => c != null).length;
        total = success;
      } else if (_activeTab == 1) {
        // Bushiroad Deck Log URL or 5-digit code
        final input = _deckLogCtrl.text.trim();
        if (input.isEmpty) {
          setState(() {
            _error = 'Please paste a Deck Log URL or 5-digit code.';
            _isImporting = false;
          });
          return;
        }
        final result = await DeckShareService.importFromDeckLog(input);
        if (result == null) {
          setState(() {
            _error = 'Could not retrieve deck. Please verify the code/URL is correct and that you are online.';
            _isImporting = false;
          });
          return;
        }
        deck = result.deck;
        skipped = result.skippedCardNumbers;
        success = result.matchedCards.length;
        total = success + skipped.length;
      } else {
        // Plain text card list
        final text = _plainTextCtrl.text.trim();
        if (text.isEmpty) {
          setState(() {
            _error = 'Please paste your plain text card list.';
            _isImporting = false;
          });
          return;
        }
        final result = await DeckShareService.parsePlainText(text);
        deck = result.deck;
        skipped = result.skippedLines;
        success = result.matches.fold(0, (sum, m) => sum + m.quantity);
        total = success + skipped.length;
      }

      setState(() {
        _importedDeck = deck;
        _skippedItems = skipped;
        _successCount = success;
        _totalCount = total;
        _isImporting = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Import failed due to an unexpected error: $e';
        _isImporting = false;
      });
    }
  }

  Future<void> _saveDeck() async {
    if (_importedDeck == null) return;
    
    // Save to multi-deck provider
    await ref.read(deckManagerProvider.notifier).saveDeck(_importedDeck!);

    if (mounted) {
      Navigator.of(context).pop(_importedDeck);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '✓ "${_importedDeck!.name}" imported successfully!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.greenAccent.withValues(alpha: 0.3)),
          ),
        ),
      );
    }
  }

  void _copySkippedItems() {
    if (_skippedItems.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _skippedItems.join('\n')));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied unresolved items to clipboard!'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_importedDeck != null) {
      return _buildPreviewScreen();
    }

    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.file_download_outlined, color: Color(0xFFFFD700), size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Import Deck',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Segmented Tab Selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildTabButton(0, 'Share ID', Icons.text_fields),
                  _buildTabButton(1, 'Deck Log', Icons.language),
                  _buildTabButton(2, 'Text List', Icons.list_alt),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Tab Info / Input
            if (_activeTab == 0) ...[
              const Text(
                'Paste a custom base64 share code generated from another device.',
                style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 12),
              _buildInputField(
                controller: _shareCodeCtrl,
                hint: 'Paste share code here…',
                maxLines: 4,
              ),
            ] else if (_activeTab == 1) ...[
              const Text(
                'Enter an official Bushiroad Deck Log URL or 5-digit code (e.g. 4DWCZ). Requires internet connection.',
                style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 12),
              _buildInputField(
                controller: _deckLogCtrl,
                hint: 'https://decklog-en.bushiroad.com/ja/view/4DWCZ',
                maxLines: 2,
              ),
            ] else ...[
              const Text(
                'Paste raw text list (e.g. "4 DZ-BT03/001" or "4 Shojodoji"). Matches against your local card DB.',
                style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 12),
              _buildInputField(
                controller: _plainTextCtrl,
                hint: '4 DZ-SS14/002R Blaster Blade\n4 DZ-SS14/001R Alfred…',
                maxLines: 6,
              ),
            ],
            
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 11.5, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD700),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          onPressed: _isImporting ? null : _import,
          icon: _isImporting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.black),
                )
              : const Icon(Icons.download_rounded, size: 16),
          label: Text(
            _isImporting ? 'Importing…' : 'Import',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final active = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTab = index;
            _error = null;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFFFD700).withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: active
                ? Border.all(color: const Color(0xFFFFD700).withOpacity(0.3))
                : Border.all(color: Colors.transparent),
          ),
          child: Column(
            children: [
              Icon(icon, color: active ? const Color(0xFFFFD700) : Colors.white38, size: 16),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: active ? const Color(0xFFFFD700) : Colors.white38,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 12,
        fontFamily: 'monospace',
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
        filled: true,
        fillColor: const Color(0xFF020617),
        contentPadding: const EdgeInsets.all(14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
        ),
      ),
    );
  }

  // ── Premium Preview Screen ─────────────────────────────────────────────────

  Widget _buildPreviewScreen() {
    final deck = _importedDeck!;
    final totalMain = deck.totalMainCards;
    final nation = deck.nation ?? 'Unknown Nation';
    final hasSkipped = _skippedItems.isNotEmpty;

    // Check triggers limits
    int triggers = 0, heals = 0, overs = 0;
    for (final item in deck.mainCards) {
      final qty = item.quantity;
      if (item.card.isTriggerUnit) {
        triggers += qty;
        if (item.card.isHealTrigger) heals += qty;
        if (item.card.isOverTrigger) overs += qty;
      }
    }

    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.verified_rounded, color: Colors.greenAccent, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Review Import',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Deck Summary Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.layers_rounded, color: Color(0xFFFFD700), size: 24),
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
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$nation · $totalMain/50 cards',
                            style: const TextStyle(color: Colors.white54, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Match Success Indicator
              const Text(
                'IMPORT PROGRESS',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: _totalCount > 0 ? _successCount / _totalCount : 1.0,
                      backgroundColor: const Color(0xFF1E293B),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        hasSkipped ? const Color(0xFFFFD700) : Colors.greenAccent,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$_successCount/$_totalCount resolved',
                    style: TextStyle(
                      color: hasSkipped ? const Color(0xFFFFD700) : Colors.greenAccent,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Deck trigger validations
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPreviewStat('Triggers', '$triggers/16', triggers == 16 ? Colors.greenAccent : Colors.white70),
                    _buildPreviewStat('Heals', '$heals/4', heals <= 4 ? Colors.greenAccent : Colors.redAccent),
                    _buildPreviewStat('Overs', '$overs/1', overs <= 1 ? Colors.greenAccent : Colors.redAccent),
                  ],
                ),
              ),
              
              if (hasSkipped) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'UNRESOLVED ITEMS (${_skippedItems.length})',
                      style: const TextStyle(
                        color: Color(0xFFF87171),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    GestureDetector(
                      onTap: _copySkippedItems,
                      child: const Row(
                        children: [
                          Icon(Icons.copy_rounded, color: Colors.blueAccent, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'Copy List',
                            style: TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 110),
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.12)),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _skippedItems.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('⚠️', style: TextStyle(fontSize: 10)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _skippedItems[index],
                                style: const TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _importedDeck = null;
              _skippedItems = [];
            });
          },
          child: const Text('Back', style: TextStyle(color: Colors.white38)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.greenAccent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          onPressed: _saveDeck,
          icon: const Icon(Icons.check_rounded, size: 16),
          label: const Text(
            'Confirm & Save',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12.5),
        ),
      ],
    );
  }
}

/// Helper to open the share sheet as a bottom sheet.
void showDeckShareSheet(BuildContext context, SavedDeck deck) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DeckShareSheet(deck: deck),
  );
}

/// Helper to open the import dialog.
Future<SavedDeck?> showImportDeckDialog(BuildContext context) {
  return showDialog<SavedDeck>(
    context: context,
    builder: (_) => const ImportDeckDialog(),
  );
}

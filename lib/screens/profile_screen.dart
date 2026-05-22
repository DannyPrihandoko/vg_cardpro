import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../providers/card_provider.dart';
import '../models/saved_deck.dart';
import 'deck_share_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
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
          child: profileAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFD700))),
            error: (e, _) => Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: Colors.white54))),
            data: (profile) => FadeTransition(
              opacity: _fadeIn,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildHeroSection(profile, decksAsync),
                  ),
                  SliverToBoxAdapter(
                    child: _buildStatsSection(decksAsync),
                  ),
                  SliverToBoxAdapter(
                    child: _buildActionsSection(context),
                  ),
                  SliverToBoxAdapter(
                    child: _buildDeckList(context, decksAsync),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Hero Section ──────────────────────────────────────────────────────────

  Widget _buildHeroSection(
      UserProfile profile, AsyncValue<List<SavedDeck>> decksAsync) {
    final avatarColor = Color(profile.avatarColorValue);
    final initials = _initials(profile.displayName);
    final totalDecks = decksAsync.value?.length ?? 0;
    final completeDecks = decksAsync.value?.where((d) => d.isComplete).length ?? 0;

    return Stack(
      children: [
        // Background gradient blob
        Positioned(
          top: -60,
          left: -60,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  avatarColor.withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            children: [
              // Top row: title + edit button
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'My Profile',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  _iconButton(
                    icon: Icons.edit_outlined,
                    color: const Color(0xFFFFD700),
                    onTap: () => _showEditProfileSheet(profile),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // Avatar + info row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildAvatar(profile, avatarColor, initials),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.displayName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@${profile.username}',
                          style: TextStyle(
                              color: avatarColor.withOpacity(0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _miniStatBadge('$totalDecks', 'Decks',
                                Colors.blueAccent),
                            const SizedBox(width: 8),
                            _miniStatBadge('$completeDecks', 'Complete',
                                Colors.greenAccent),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(UserProfile profile, Color color, String initials) {
    return GestureDetector(
      onTap: () => _showEditProfileSheet(profile),
      child: Stack(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: profile.avatarPhotoPath != null
                ? ClipOval(
                    child: Image.file(
                      File(profile.avatarPhotoPath!),
                      fit: BoxFit.cover,
                      width: 90,
                      height: 90,
                      errorBuilder: (_, __, ___) =>
                          _avatarInitials(initials, color),
                    ),
                  )
                : _avatarInitials(initials, color),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0F172A), width: 2),
              ),
              child: const Icon(Icons.camera_alt, color: Colors.black, size: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarInitials(String initials, Color color) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
            color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _miniStatBadge(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color.withOpacity(0.7),
                  fontSize: 11)),
        ],
      ),
    );
  }

  // ── Stats Section ─────────────────────────────────────────────────────────

  Widget _buildStatsSection(AsyncValue<List<SavedDeck>> decksAsync) {
    final decks = decksAsync.value ?? [];
    final totalCards =
        decks.fold(0, (sum, d) => sum + d.totalMainCards);
    final rideLineComplete = decks.where((d) => d.isRideLineComplete).length;
    final triggerTotal =
        decks.fold(0, (sum, d) => sum + d.triggerCount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Statistics'),
          const SizedBox(height: 12),
          Row(
            children: [
              _statCard(
                icon: Icons.style_outlined,
                value: '$totalCards',
                label: 'Total Cards',
                color: const Color(0xFF60A5FA),
              ),
              const SizedBox(width: 10),
              _statCard(
                icon: Icons.swap_vert_circle_outlined,
                value: '$rideLineComplete',
                label: 'Ride Lines',
                color: const Color(0xFFA78BFA),
              ),
              const SizedBox(width: 10),
              _statCard(
                icon: Icons.bolt,
                value: '$triggerTotal',
                label: 'Triggers',
                color: const Color(0xFFFFD700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ── Actions Section ───────────────────────────────────────────────────────

  Widget _buildActionsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Quick Actions'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _actionCard(
                  icon: Icons.file_download_outlined,
                  label: 'Import Deck',
                  sublabel: 'Paste share code',
                  color: Colors.blueAccent,
                  onTap: () async {
                    final deck = await showImportDeckDialog(context);
                    if (deck != null && context.mounted) {
                      context.push('/deck-editor', extra: deck);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionCard(
                  icon: Icons.add_circle_outline,
                  label: 'New Deck',
                  sublabel: 'Start building',
                  color: const Color(0xFFFFD700),
                  onTap: () {
                    // Navigate to deck list tab
                    // The scaffold controller is managed by CupertinoTabScaffold
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  Text(sublabel,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Deck List ─────────────────────────────────────────────────────────────

  Widget _buildDeckList(
      BuildContext context, AsyncValue<List<SavedDeck>> decksAsync) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('My Decks'),
          const SizedBox(height: 12),
          decksAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFD700))),
            error: (e, _) => const SizedBox.shrink(),
            data: (decks) => decks.isEmpty
                ? _buildEmptyDecks()
                : Column(
                    children: decks
                        .map((d) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildDeckCard(context, d),
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDecks() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.layers_outlined, color: Colors.white24, size: 48),
          SizedBox(height: 12),
          Text('No decks yet',
              style: TextStyle(color: Colors.white54, fontSize: 15)),
          SizedBox(height: 4),
          Text('Go to My Decks tab to start building!',
              style: TextStyle(color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDeckCard(BuildContext context, SavedDeck deck) {
    final nation = deck.nation;
    final isComplete = deck.isComplete;

    return GestureDetector(
      onTap: () => context.push('/deck-editor', extra: deck),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isComplete
                ? Colors.greenAccent.withOpacity(0.25)
                : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.layers_rounded,
                  color: Colors.blueAccent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(deck.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(
                    '${nation ?? "No nation"} · ${deck.totalMainCards}/50',
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            // Share button
            GestureDetector(
              onTap: () => showDeckShareSheet(context, deck),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.2)),
                ),
                child: const Icon(Icons.share_rounded,
                    color: Color(0xFFFFD700), size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Edit Profile Sheet ────────────────────────────────────────────────────

  void _showEditProfileSheet(UserProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(profile: profile),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit Profile Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _EditProfileSheet extends ConsumerStatefulWidget {
  final UserProfile profile;
  const _EditProfileSheet({required this.profile});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _usernameCtrl;
  late int _selectedColor;
  String? _newPhotoPath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.displayName);
    _usernameCtrl = TextEditingController(text: widget.profile.username);
    _selectedColor = widget.profile.avatarColorValue;
    _newPhotoPath = widget.profile.avatarPhotoPath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (xfile != null) {
      setState(() => _newPhotoPath = xfile.path);
    }
  }

  Future<void> _removePhoto() async {
    setState(() => _newPhotoPath = null);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final notifier = ref.read(profileProvider.notifier);
    final updated = widget.profile.copyWith(
      displayName: _nameCtrl.text.trim().isEmpty
          ? widget.profile.displayName
          : _nameCtrl.text.trim(),
      username: _usernameCtrl.text.trim().isEmpty
          ? widget.profile.username
          : _usernameCtrl.text.trim().replaceAll(' ', '_').toLowerCase(),
      avatarColorValue: _selectedColor,
      avatarPhotoPath: _newPhotoPath,
    );
    await notifier.save(updated);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final avatarColor = Color(_selectedColor);
    final initials = _nameCtrl.text.trim().isEmpty
        ? '?'
        : _nameCtrl.text.trim().split(' ').take(2).map((p) => p[0]).join().toUpperCase();

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Edit Profile',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Avatar preview + photo picker
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                avatarColor,
                                avatarColor.withOpacity(0.6)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: avatarColor.withOpacity(0.35),
                                blurRadius: 20,
                              )
                            ],
                          ),
                          child: _newPhotoPath != null
                              ? ClipOval(
                                  child: Image.file(
                                    File(_newPhotoPath!),
                                    fit: BoxFit.cover,
                                    width: 96,
                                    height: 96,
                                    errorBuilder: (_, __, ___) =>
                                        _initialsWidget(initials),
                                  ),
                                )
                              : _initialsWidget(initials),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: _pickPhoto,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF0F172A), width: 2),
                              ),
                              child: const Icon(Icons.camera_alt,
                                  color: Colors.black, size: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_newPhotoPath != null) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _removePhoto,
                        child: const Text(
                          'Remove photo',
                          style: TextStyle(
                              color: Colors.redAccent, fontSize: 12),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickPhoto,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.1)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_library_outlined,
                                color: Colors.white70, size: 14),
                            SizedBox(width: 6),
                            Text('Choose from gallery',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Avatar color picker
              const Text('Avatar Color',
                  style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: UserProfile.availableColors.map((c) {
                    final isSelected = _selectedColor == c;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(c),
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Color(c).withOpacity(0.5),
                                    blurRadius: 10,
                                  )
                                ]
                              : [],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Display name
              _buildTextField(
                controller: _nameCtrl,
                label: 'Display Name',
                hint: 'e.g. Aichi Sendou',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),

              // Username
              _buildTextField(
                controller: _usernameCtrl,
                label: 'Username',
                hint: 'e.g. vanguard_fighter',
                icon: Icons.alternate_email,
              ),
              const SizedBox(height: 28),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _initialsWidget(String initials) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
            color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            prefixIcon: Icon(icon, color: Colors.white38, size: 18),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

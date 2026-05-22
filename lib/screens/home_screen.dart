import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/card_provider.dart';
import '../models/vg_card.dart';
import '../widgets/set_card_widget.dart';

// ── Official nation definitions (6 canonical nations) ──────────────
class _NationDef {
  final String name;
  final Color color;
  final Color colorDark;
  final IconData icon;
  final String subtitle;
  const _NationDef({
    required this.name,
    required this.color,
    required this.colorDark,
    required this.icon,
    required this.subtitle,
  });
}

const List<_NationDef> _kNations = [
  _NationDef(
    name: 'Dragon Empire',
    color: Color(0xFFEF4444),
    colorDark: Color(0xFF7F1D1D),
    icon: Icons.local_fire_department,
    subtitle: 'Power & Domination',
  ),
  _NationDef(
    name: 'Dark States',
    color: Color(0xFF6366F1),
    colorDark: Color(0xFF1E1B4B),
    icon: Icons.nightlight_round,
    subtitle: 'Chaos & Darkness',
  ),
  _NationDef(
    name: 'Brandt Gate',
    color: Color(0xFFF59E0B),
    colorDark: Color(0xFF78350F),
    icon: Icons.bolt,
    subtitle: 'Technology & Order',
  ),
  _NationDef(
    name: 'Keter Sanctuary',
    color: Color(0xFFA78BFA),
    colorDark: Color(0xFF4C1D95),
    icon: Icons.auto_awesome,
    subtitle: 'Holy & Divine',
  ),
  _NationDef(
    name: 'Stoicheia',
    color: Color(0xFF34D399),
    colorDark: Color(0xFF064E3B),
    icon: Icons.eco,
    subtitle: 'Nature & Balance',
  ),
  _NationDef(
    name: 'Lyrical Monasterio',
    color: Color(0xFFF472B6),
    colorDark: Color(0xFF831843),
    icon: Icons.music_note,
    subtitle: 'Music & Dreams',
  ),
];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(globalSearchQueryProvider.notifier).updateQuery(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedNation = ref.watch(nationFilterProvider);
    final globalQuery = ref.watch(globalSearchQueryProvider);
    final isFiltering = globalQuery.isNotEmpty || selectedNation != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: const Color(0xFF0A0F1E),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1A237E),
                      Color(0xFF0A0F1E),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.blueAccent.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Icon(Icons.style,
                                  color: Colors.blueAccent, size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Vanguard DB',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.layers_outlined,
                                  color: Colors.white70),
                              tooltip: 'Browse Sets',
                              onPressed: () => context.push('/sets'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              title: null,
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(58),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _buildSearchBar(isFiltering),
              ),
            ),
          ),

          // ── Nation Filter Chips ───────────────────────────────────
          SliverToBoxAdapter(
            child: _buildNationFilterSection(selectedNation),
          ),

          // ── Content area ─────────────────────────────────────────
          if (isFiltering)
            _buildGlobalSearchResults()
          else
            _buildSetsBrowseSection(),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isFiltering) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFiltering
              ? Colors.blueAccent.withValues(alpha: 0.6)
              : Colors.white10,
        ),
        boxShadow: isFiltering
            ? [
                BoxShadow(
                  color: Colors.blueAccent.withValues(alpha: 0.2),
                  blurRadius: 8,
                  spreadRadius: 0,
                )
              ]
            : [],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Search card name...',
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 15),
          prefixIcon: const Icon(Icons.search, color: Colors.blueAccent, size: 22),
          suffixIcon: isFiltering
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(globalSearchQueryProvider.notifier).updateQuery('');
                    ref.read(nationFilterProvider.notifier).selectNation(null);
                  },
                )
              : null,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildNationFilterSection(String? selectedNation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 14, 0, 10),
          child: Text(
            'FILTER BY NATION',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // ── "All" chip ──
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _buildNationCard(
                  label: 'All Nations',
                  subtitle: 'Show everything',
                  icon: Icons.public,
                  color: const Color(0xFF64748B),
                  colorDark: const Color(0xFF1E293B),
                  isSelected: selectedNation == null,
                  onTap: () =>
                      ref.read(nationFilterProvider.notifier).selectNation(null),
                ),
              ),
              // ── 6 official nations ──
              ..._kNations.map((nation) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _buildNationCard(
                    label: nation.name,
                    subtitle: nation.subtitle,
                    icon: nation.icon,
                    color: nation.color,
                    colorDark: nation.colorDark,
                    isSelected: selectedNation == nation.name,
                    onTap: () => ref
                        .read(nationFilterProvider.notifier)
                        .selectNation(nation.name),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Divider(
            color: Colors.white.withValues(alpha: 0.06),
            height: 1,
            thickness: 1),
      ],
    );
  }

  Widget _buildNationCard({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color colorDark,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 138,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, colorDark],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorDark.withValues(alpha: 0.6),
                    const Color(0xFF1E293B),
                  ],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.25),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.2)
                        : color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.6),
                          blurRadius: 4,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : color,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.65)
                        : Colors.white24,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalSearchResults() {
    final filteredAsync = ref.watch(globalFilteredCardsProvider);
    final selectedNation = ref.watch(nationFilterProvider);
    final query = ref.watch(globalSearchQueryProvider);

    return filteredAsync.when(
      data: (cards) {
        if (cards.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 72, color: Colors.white12),
                  const SizedBox(height: 16),
                  Text(
                    'No cards found',
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    query.isNotEmpty
                        ? 'Try a different search term'
                        : selectedNation != null
                            ? 'No cards for this nation'
                            : '',
                    style: const TextStyle(color: Colors.white24, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final card = cards[index];
                return _buildCardTile(card);
              },
              childCount: cards.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 0.72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
          ),
        );
      },
      loading: () => const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SliverFillRemaining(
        child: Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildSetsBrowseSection() {
    final setsAsync = ref.watch(setsProvider);

    return setsAsync.when(
      data: (sets) {
        if (sets.isEmpty) {
          return const SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.layers_clear, size: 72, color: Colors.white12),
                  SizedBox(height: 16),
                  Text(
                    'No sets available',
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        }

        final double screenWidth = MediaQuery.of(context).size.width;
        int crossAxisCount = 1;
        if (screenWidth >= 1200) {
          crossAxisCount = 4;
        } else if (screenWidth >= 900) {
          crossAxisCount = 3;
        } else if (screenWidth >= 600) {
          crossAxisCount = 2;
        }

        // Calculate aspect ratio dynamically so that height is consistently ~360
        final double paddingSpace = 16.0 * 2 + (crossAxisCount - 1) * 16.0;
        final double itemWidth = (screenWidth - paddingSpace) / crossAxisCount;
        final double childAspectRatio = itemWidth / 360.0;

        return SliverMainAxisGroup(
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 0, 14),
                child: Text(
                  'BROWSE SETS',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final setName = sets[index];
                    return VanguardSetCard(setName: setName);
                  },
                  childCount: sets.length,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: childAspectRatio > 0 ? childAspectRatio : 1.0,
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      ),
      error: (e, _) => SliverFillRemaining(
        child: Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildCardTile(VgCard card) {
    return GestureDetector(
      onTap: () => context.push('/detail', extra: card),
      child: Hero(
        tag: 'home-card-${card.id}',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: card.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: const Color(0xFF1E293B),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: const Color(0xFF1E293B),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.broken_image,
                        size: 32, color: Colors.white24),
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
        ),
      ),
    );
  }
}

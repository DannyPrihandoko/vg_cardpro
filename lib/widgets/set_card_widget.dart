import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/download_provider.dart';

class SetMetadata {
  final String title;
  final String category; // "Booster Pack" or "Constructed Deck"
  final String releaseDate;
  final String featuredText;
  final List<Color> bannerGradient;

  const SetMetadata({
    required this.title,
    required this.category,
    required this.releaseDate,
    required this.featuredText,
    required this.bannerGradient,
  });
}

class VanguardSetCard extends ConsumerWidget {
  final String setName;

  const VanguardSetCard({
    super.key,
    required this.setName,
  });

  // Comprehensive metadata catalog for all 30 sets
  static const Map<String, SetMetadata> _metadataMap = {
    'DZ-BT03': SetMetadata(
      title: 'Cardfight!! Vanguard Booster Pack 03: Dimensional Transcendence',
      category: 'Booster Pack',
      releaseDate: 'August 30, 2024',
      featuredText: 'Featured Nations: Dragon Empire, Dark States, Brandt Gate, Keter Sanctuary, Stoicheia',
      bannerGradient: [Color(0xFF4F46E5), Color(0xFFD946EF), Color(0xFF0F172A)],
    ),
    'DZ-BT04': SetMetadata(
      title: 'Cardfight!! Vanguard Booster Pack 04: Destined Showdown',
      category: 'Booster Pack',
      releaseDate: 'October 11, 2024',
      featuredText: 'Featured Nations: Dragon Empire, Dark States, Brandt Gate, Keter Sanctuary, Stoicheia, Lyrical Monasterio',
      bannerGradient: [Color(0xFFDC2626), Color(0xFF2563EB), Color(0xFF1E1B4B)],
    ),
    'DZ-BT05': SetMetadata(
      title: 'Cardfight!! Vanguard Booster Pack 05: Omniscient Awakening',
      category: 'Booster Pack',
      releaseDate: 'December 6, 2024',
      featuredText: 'Featured Nations: Dragon Empire, Dark States, Brandt Gate, Keter Sanctuary, Stoicheia, Lyrical Monasterio',
      bannerGradient: [Color(0xFF059669), Color(0xFFD97706), Color(0xFF1E293B)],
    ),
    'DZ-BT06': SetMetadata(
      title: 'Cardfight!! Vanguard Booster Pack 06: Generation Dragenesis',
      category: 'Booster Pack',
      releaseDate: 'February 7, 2025',
      featuredText: 'Featured Nations: Dragon Empire, Dark States, Brandt Gate, Keter Sanctuary, Stoicheia',
      bannerGradient: [Color(0xFF06B6D4), Color(0xFF7C3AED), Color(0xFF0F172A)],
    ),
    'DZ-BT07': SetMetadata(
      title: 'Cardfight!! Vanguard Booster Pack 07: Moon Fangs & Cerulean Blaze',
      category: 'Booster Pack',
      releaseDate: 'April 18, 2025',
      featuredText: 'Featured Nations: Dragon Empire, Dark States, Brandt Gate, Keter Sanctuary, Stoicheia, Lyrical Monasterio',
      bannerGradient: [Color(0xFF1E3A8A), Color(0xFF94A3B8), Color(0xFF0F172A)],
    ),
    'DZ-BT08': SetMetadata(
      title: 'Cardfight!! Vanguard Booster Pack 08: Knights of Rebirth',
      category: 'Booster Pack',
      releaseDate: 'June 20, 2025',
      featuredText: 'Featured Nations: Dragon Empire, Dark States, Brandt Gate, Keter Sanctuary, Stoicheia, Lyrical Monasterio',
      bannerGradient: [Color(0xFF7C3AED), Color(0xFFDC2626), Color(0xFF1E1B4B)],
    ),
    'DZ-BT09': SetMetadata(
      title: 'Cardfight!! Vanguard Booster Pack 09: Super Brave Detonation',
      category: 'Booster Pack',
      releaseDate: 'August 22, 2025',
      featuredText: 'Featured Nations: Dragon Empire, Dark States, Brandt Gate, Keter Sanctuary, Stoicheia',
      bannerGradient: [Color(0xFFEA580C), Color(0xFF475569), Color(0xFF0A0F1E)],
    ),
    'DZ-BT11': SetMetadata(
      title: 'Cardfight!! Vanguard Booster Pack 11: Symphony of Might & Bloom',
      category: 'Booster Pack',
      releaseDate: 'October 24, 2025',
      featuredText: 'Featured Nations: Dragon Empire, Dark States, Brandt Gate, Keter Sanctuary, Stoicheia, Lyrical Monasterio',
      bannerGradient: [Color(0xFF059669), Color(0xFFDB2777), Color(0xFF1E1B4B)],
    ),
    'DZ-BT12': SetMetadata(
      title: 'Cardfight!! Vanguard Booster Pack 12: Chasm of Lost Souls',
      category: 'Booster Pack',
      releaseDate: 'January 9, 2026',
      featuredText: 'Featured Nations: Dragon Empire, Dark States, Brandt Gate, Keter Sanctuary, Stoicheia',
      bannerGradient: [Color(0xFF6366F1), Color(0xFF06B6D4), Color(0xFF0A0F1E)],
    ),
    'DZ-BT13': SetMetadata(
      title: 'Cardfight!! Vanguard Booster Pack 13: Parallactic Clash',
      category: 'Booster Pack',
      releaseDate: 'May 8, 2026',
      featuredText: 'Featured Nations: Dragon Empire, Dark States, Brandt Gate, Keter Sanctuary, Stoicheia, Lyrical Monasterio',
      bannerGradient: [Color(0xFF4F46E5), Color(0xFFEC4899), Color(0xFF1E1B4B)],
    ),
    'DZ-BT14': SetMetadata(
      title: 'Cardfight!! Vanguard Booster Pack 14: Envoys of the Crimson Moon',
      category: 'Booster Pack',
      releaseDate: 'July 10, 2026',
      featuredText: 'Featured Nations: Dragon Empire, Dark States, Brandt Gate, Keter Sanctuary, Stoicheia, Lyrical Monasterio',
      bannerGradient: [Color(0xFF991B1B), Color(0xFF1E3A8A), Color(0xFF0F172A)],
    ),
    'DZ-LBT01': SetMetadata(
      title: 'Cardfight!! Vanguard Lyrical Booster 01: Sparkling Stars!',
      category: 'Booster Pack',
      releaseDate: 'September 27, 2024',
      featuredText: 'Featured Nation: Lyrical Monasterio',
      bannerGradient: [Color(0xFFEC4899), Color(0xFFF472B6), Color(0xFFFBBF24)],
    ),
    'DZ-LBT02': SetMetadata(
      title: 'Cardfight!! Vanguard Lyrical Booster 02: Season of Wonders',
      category: 'Booster Pack',
      releaseDate: 'March 14, 2025',
      featuredText: 'Featured Nation: Lyrical Monasterio',
      bannerGradient: [Color(0xFFEC4899), Color(0xFF06B6D4), Color(0xFF8B5CF6)],
    ),
    'DZ-SS01': SetMetadata(
      title: 'Cardfight!! Vanguard Special Series 01: Festival Booster 2024',
      category: 'Booster Pack',
      releaseDate: 'July 5, 2024',
      featuredText: 'Featured Nations: Dragon Empire, Dark States, Brandt Gate, Keter Sanctuary, Stoicheia, Lyrical Monasterio',
      bannerGradient: [Color(0xFFEA580C), Color(0xFFF59E0B), Color(0xFF2563EB)],
    ),
    'DZ-SS02': SetMetadata(
      title: 'Cardfight!! Vanguard Special Series 02: Stride Deckset -Harri-',
      category: 'Constructed Deck',
      releaseDate: 'May 17, 2024',
      featuredText: 'Featured Title: Dark States',
      bannerGradient: [Color(0xFFDB2777), Color(0xFF4F46E5), Color(0xFF0F172A)],
    ),
    'DZ-SS03': SetMetadata(
      title: 'Cardfight!! Vanguard Special Series 03: Stride Deckset -Nightrose-',
      category: 'Constructed Deck',
      releaseDate: 'May 17, 2024',
      featuredText: 'Featured Title: Stoicheia',
      bannerGradient: [Color(0xFF059669), Color(0xFF94A3B8), Color(0xFF0F172A)],
    ),
    'DZ-SS04': SetMetadata(
      title: 'Cardfight!! Vanguard Special Series 04: Stardust Blade',
      category: 'Constructed Deck',
      releaseDate: 'June 7, 2024',
      featuredText: 'Featured Nations: Dragon Empire, Dark States, Brandt Gate, Keter Sanctuary, Stoicheia, Lyrical Monasterio',
      bannerGradient: [Color(0xFF475569), Color(0xFF0EA5E9), Color(0xFF0F172A)],
    ),
    'DZ-SS07': SetMetadata(
      title: 'Cardfight!! Vanguard Special Series 07: Master Deckset -Michiru Hazama-',
      category: 'Constructed Deck',
      releaseDate: 'November 8, 2024',
      featuredText: 'Featured Title: Dragon Empire',
      bannerGradient: [Color(0xFFB91C1C), Color(0xFF7F1D1D), Color(0xFF1E293B)],
    ),
    'DZ-SS08': SetMetadata(
      title: 'Cardfight!! Vanguard Special Series 08: Festival Booster 2025',
      category: 'Booster Pack',
      releaseDate: 'July 4, 2025',
      featuredText: 'Featured Nations: Dragon Empire, Dark States, Brandt Gate, Keter Sanctuary, Stoicheia, Lyrical Monasterio',
      bannerGradient: [Color(0xFFD97706), Color(0xFF2563EB), Color(0xFFF472B6)],
    ),
    'DZ-SS09': SetMetadata(
      title: 'Cardfight!! Vanguard Special Series 09: Zero Tendo Start Deck',
      category: 'Constructed Deck',
      releaseDate: 'September 5, 2025',
      featuredText: 'Featured Title: Stoicheia',
      bannerGradient: [Color(0xFF10B981), Color(0xFF047857), Color(0xFF1F2937)],
    ),
    'DZ-SS10': SetMetadata(
      title: 'Cardfight!! Vanguard Special Series 10: Shiki Otei Start Deck',
      category: 'Constructed Deck',
      releaseDate: 'September 5, 2025',
      featuredText: 'Featured Title: Dark States',
      bannerGradient: [Color(0xFF8B5CF6), Color(0xFF4C1D95), Color(0xFF1F2937)],
    ),
    'DZ-SS11': SetMetadata(
      title: 'Cardfight!! Vanguard Special Series 11: Master Deckset -Hikari Myodo-',
      category: 'Constructed Deck',
      releaseDate: 'April 24, 2026',
      featuredText: 'Featured Title: Dark States',
      bannerGradient: [Color(0xFF6366F1), Color(0xFF4F46E5), Color(0xFF0F172A)],
    ),
    'DZ-SS12': SetMetadata(
      title: 'Cardfight!! Vanguard Special Series 12: Master Deckset -Erika Myojo-',
      category: 'Constructed Deck',
      releaseDate: 'April 24, 2026',
      featuredText: 'Featured Title: Keter Sanctuary',
      bannerGradient: [Color(0xFFFBBF24), Color(0xFF8B5CF6), Color(0xFF4C1D95)],
    ),
    'DZ-SS13': SetMetadata(
      title: 'Cardfight!! Vanguard Special Series 13: Start Deck -Blaster Blade-',
      category: 'Constructed Deck',
      releaseDate: 'September 4, 2026',
      featuredText: 'Featured Title: Keter Sanctuary',
      bannerGradient: [Color(0xFF1D4ED8), Color(0xFF60A5FA), Color(0xFFFFFFFF)],
    ),
    'DZ-SS14': SetMetadata(
      title: 'Cardfight!! Vanguard Special Series 14: Start Deck -Dragonic Overlord-',
      category: 'Constructed Deck',
      releaseDate: 'September 4, 2026',
      featuredText: 'Featured Title: Dragon Empire',
      bannerGradient: [Color(0xFFDC2626), Color(0xFFF97316), Color(0xFF1E293B)],
    ),
    'DZ-SS15': SetMetadata(
      title: 'Cardfight!! Vanguard Special Series 15: The Legendary Vanguards',
      category: 'Constructed Deck',
      releaseDate: 'November 13, 2026',
      featuredText: 'Featured Title: Dragon Empire, Keter Sanctuary',
      bannerGradient: [Color(0xFFD97706), Color(0xFFB91C1C), Color(0xFF7C3AED)],
    ),
    'DZ-SS16': SetMetadata(
      title: 'Cardfight!! Vanguard Special Series 16: Festival Booster 2026',
      category: 'Booster Pack',
      releaseDate: 'November 13, 2026',
      featuredText: 'Featured Nations: Dragon Empire, Dark States, Brandt Gate, Keter Sanctuary, Stoicheia, Lyrical Monasterio',
      bannerGradient: [Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFF0EA5E9)],
    ),
    'DZ-TB01': SetMetadata(
      title: 'Cardfight!! Vanguard Title Booster 01: Buddyfight ONLINE',
      category: 'Booster Pack',
      releaseDate: 'September 13, 2024',
      featuredText: 'Featured Title: Buddyfight',
      bannerGradient: [Color(0xFFF59E0B), Color(0xFF2563EB), Color(0xFF1E293B)],
    ),
    'DZ-TB02': SetMetadata(
      title: 'Cardfight!! Vanguard Title Booster 02: Touken Ranbu ONLINE 2025',
      category: 'Booster Pack',
      releaseDate: 'March 20, 2026',
      featuredText: 'Featured Title: Touken Ranbu',
      bannerGradient: [Color(0xFFEAB308), Color(0xFF1E293B), Color(0xFF78350F)],
    ),
    'PR': SetMetadata(
      title: 'Cardfight!! Vanguard Promo Cards',
      category: 'Booster Pack',
      releaseDate: 'Ongoing',
      featuredText: 'Featured Nations: Dragon Empire, Dark States, Brandt Gate, Keter Sanctuary, Stoicheia, Lyrical Monasterio',
      bannerGradient: [Color(0xFF06B6D4), Color(0xFFEC4899), Color(0xFFFBBF24)],
    ),
  };

  // Helper method to look up or generate dynamic fallback metadata
  SetMetadata _getMetadata() {
    if (_metadataMap.containsKey(setName)) {
      return _metadataMap[setName]!;
    }

    // Dynamic parsing fallback
    final isConstructed = setName.startsWith('DZ-SS');
    final isTitle = setName.startsWith('DZ-TB');
    final numStr = setName.replaceAll(RegExp(r'[^0-9]'), '');
    final setNum = numStr.isNotEmpty ? int.tryParse(numStr) ?? 0 : 0;
    
    String category = isConstructed ? 'Constructed Deck' : 'Booster Pack';
    String title = isConstructed
        ? 'Cardfight!! Vanguard Special Series ${setNum.toString().padLeft(2, '0')}: Special Deckset'
        : isTitle
            ? 'Cardfight!! Vanguard Title Booster ${setNum.toString().padLeft(2, '0')}: Collaboration Booster'
            : 'Cardfight!! Vanguard Booster Pack ${setNum.toString().padLeft(2, '0')}: Expansion Set';
            
    return SetMetadata(
      title: title,
      category: category,
      releaseDate: 'Ongoing',
      featuredText: 'Featured Nations: Dragon Empire, Dark States, Brandt Gate, Keter Sanctuary, Stoicheia, Lyrical Monasterio',
      bannerGradient: isConstructed
          ? [Color(0xFF2563EB), Color(0xFF1D4ED8), Color(0xFF0F172A)]
          : [Color(0xFF4F46E5), Color(0xFFD946EF), Color(0xFF0F172A)],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = _getMetadata();
    final downloadState = ref.watch(downloadProgressProvider);
    final progress = downloadState[setName];

    // Badge styling config
    final bool isBooster = meta.category == 'Booster Pack';
    final Color badgeBgColor = isBooster ? const Color(0xFFDC2626) : const Color(0xFF1D4ED8);

    // Dynamic scale/elevation behavior
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.push('/cards', extra: setName),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. The Landscape Artwork Banner (Dynamic Gradient + Styled Text)
                Stack(
                  children: [
                    Container(
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: meta.bannerGradient,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Abstract Background Geometry
                          Positioned(
                            right: -20,
                            top: -20,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Positioned(
                            left: -10,
                            bottom: -30,
                            child: Transform.rotate(
                              angle: 0.4,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                          ),
                          // Shimmer shine effect overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                                colors: [
                                  Colors.white.withValues(alpha: 0.1),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                                stops: const [0.3, 0.7],
                              ),
                            ),
                          ),
                          // Giant stylised background code
                          Center(
                            child: Opacity(
                              opacity: 0.09,
                              child: Text(
                                setName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),
                          // Stylized Neon Set Code Box
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              setName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                shadows: [
                                  Shadow(
                                    blurRadius: 4.0,
                                    color: Colors.black45,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Floating Frosted Download Action Overlay
                    Positioned(
                      top: 10,
                      right: 10,
                      child: ClipOval(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.35),
                          child: _buildDownloadButton(ref, progress),
                        ),
                      ),
                    ),
                  ],
                ),

                // 2. Category Banner ("Booster Pack" / "Constructed Deck")
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
                  color: badgeBgColor,
                  alignment: Alignment.center,
                  child: Text(
                    meta.category.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),

                // 3. Set Code & dynamic Title
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    '[VGE-$setName] ${meta.title}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const Spacer(),

                // 4. Bordered Release Date Box
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF374151), width: 0.75),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      meta.releaseDate,
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // 5. Featured Nations / Title details
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Text(
                    meta.featuredText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadButton(WidgetRef ref, double? progress) {
    if (progress == null) {
      return SizedBox(
        width: 32,
        height: 32,
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
          tooltip: 'Download Offline Images',
          onPressed: () async {
            await ref.read(downloadProgressProvider.notifier).downloadSetImages(setName);
          },
        ),
      );
    } else if (progress < 1.0) {
      return Container(
        width: 32,
        height: 32,
        padding: const EdgeInsets.all(6),
        child: CircularProgressIndicator(
          value: progress,
          strokeWidth: 2,
          color: Colors.white,
          backgroundColor: Colors.white24,
        ),
      );
    } else {
      return const SizedBox(
        width: 32,
        height: 32,
        child: Center(
          child: Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 18),
        ),
      );
    }
  }
}

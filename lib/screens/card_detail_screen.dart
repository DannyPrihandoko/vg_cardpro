import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/vg_card.dart';

class CardDetailScreen extends ConsumerWidget {
  final VgCard card;

  const CardDetailScreen({super.key, required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(card.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Image with gradient fade
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Hero(
                  tag: 'card-${card.id}',
                  child: CachedNetworkImage(
                    imageUrl: card.imageUrl,
                    height: 500,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    placeholder: (context, url) => Container(
                      height: 500,
                      color: Colors.grey[900],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 500,
                      color: Colors.grey[900],
                      child: const Icon(Icons.broken_image, size: 100),
                    ),
                  ),
                ),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Theme.of(context).scaffoldBackgroundColor,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Specs Row 1: Primary
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (card.clan.isNotEmpty && card.clan != '-') _buildSpecChip(context, Icons.shield, card.clan, Colors.blueAccent),
                      if (card.nation.isNotEmpty && card.nation != '-') _buildSpecChip(context, Icons.flag, card.nation, Colors.redAccent),
                      if (card.race.isNotEmpty && card.race != '-') _buildSpecChip(context, Icons.pets, card.race, Colors.green),
                      if (card.unitType.isNotEmpty && card.unitType != '-') _buildSpecChip(context, Icons.category, card.unitType, Colors.purpleAccent),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Specs Row 2: Stats
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (card.grade.isNotEmpty && card.grade != '-') _buildSpecChip(context, Icons.star, 'Grade ${card.grade}', Colors.orange),
                      if (card.power.isNotEmpty && card.power != '-') _buildSpecChip(context, Icons.flash_on, 'Power: ${card.power}', Colors.amber),
                      if (card.shield.isNotEmpty && card.shield != '-') _buildSpecChip(context, Icons.security, 'Shield: ${card.shield}', Colors.lightBlue),
                      if (card.critical.isNotEmpty && card.critical != '-') _buildSpecChip(context, Icons.crisis_alert, 'Crit: ${card.critical}', Colors.red),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Specs Row 3: Skills & Triggers
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (card.skill.isNotEmpty && card.skill != '-') _buildSpecChip(context, Icons.psychology, card.skill, Colors.cyan),
                      if (card.trigger.isNotEmpty && card.trigger != '-') _buildSpecChip(context, Icons.bolt, 'Trigger: ${card.trigger}', Colors.yellowAccent),
                    ],
                  ),
                  
                  if (card.effectText.isNotEmpty && card.effectText != '-') ...[
                    const SizedBox(height: 32),
                    const Text(
                      'Skill / Effect',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        card.effectText,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],

                  if (card.flavorText.isNotEmpty && card.flavorText != '-') ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        '“${card.flavorText}”',
                        style: const TextStyle(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          color: Colors.white60,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 16),
                  
                  // Metadata Section
                  const Text(
                    'Card Info',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMetaRow('Set', card.setName),
                  if (card.rarity.isNotEmpty && card.rarity != '-') _buildMetaRow('Rarity', card.rarity),
                  if (card.regulation.isNotEmpty && card.regulation != '-') _buildMetaRow('Regulation', card.regulation),
                  if (card.illustrator.isNotEmpty && card.illustrator != '-') _buildMetaRow('Illustrator', card.illustrator),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.info_outline,
                      color: Colors.blueAccent, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Open a deck from "My Decks" tab to add this card.',
                    style: TextStyle(color: Colors.white54, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecChip(BuildContext context, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

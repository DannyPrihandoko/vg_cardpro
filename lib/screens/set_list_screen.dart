import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/card_provider.dart';
import '../widgets/set_card_widget.dart';

class SetListScreen extends ConsumerWidget {
  const SetListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsAsync = ref.watch(setsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F1E),
        elevation: 0,
        title: const Text(
          'Vanguard Sets',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: setsAsync.when(
        data: (sets) {
          if (sets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.layers_clear, size: 80, color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  Text(
                    'No sets found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: sets.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: childAspectRatio > 0 ? childAspectRatio : 1.0,
            ),
            itemBuilder: (context, index) {
              final setName = sets[index];
              return VanguardSetCard(setName: setName);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Colors.blueAccent,
          ),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}


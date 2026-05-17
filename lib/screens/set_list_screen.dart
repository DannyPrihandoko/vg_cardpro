import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/card_provider.dart';
import '../providers/download_provider.dart';

class SetListScreen extends ConsumerWidget {
  const SetListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsAsync = ref.watch(setsProvider);
    final downloadState = ref.watch(downloadProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vanguard Sets', style: TextStyle(fontWeight: FontWeight.bold)),
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
          
          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: sets.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final setName = sets[index];
              final progress = downloadState[setName];
              Widget trailingWidget;

              if (progress == null) {
                trailingWidget = IconButton(
                  icon: const Icon(Icons.download, color: Colors.blueAccent),
                  onPressed: () async {
                    await ref.read(downloadProgressProvider.notifier).downloadSetImages(setName);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Download for $setName completed!'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                );
              } else if (progress < 1.0) {
                trailingWidget = SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    color: Colors.blueAccent,
                  ),
                );
              } else {
                trailingWidget = const Icon(Icons.check_circle, color: Colors.green);
              }

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: const Color(0xFF1E293B),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: const Icon(Icons.style, color: Colors.blueAccent, size: 32),
                  title: Text(
                    setName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      trailingWidget,
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: Colors.white54),
                    ],
                  ),
                  onTap: () {
                    // We'll pass the setName as an extra to CardListScreen
                    context.push('/cards', extra: setName);
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

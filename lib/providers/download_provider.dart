import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'card_provider.dart';

// State to keep track of download progress for sets. Key: setName, Value: progress (0.0 to 1.0)
class DownloadProgressNotifier extends Notifier<Map<String, double>> {
  @override
  Map<String, double> build() {
    return {};
  }

  Future<void> downloadSetImages(String setName) async {
    // If already downloading or finished (though we can re-download if we want, let's just start)
    if (state.containsKey(setName) && state[setName]! < 1.0) {
      return; // Already downloading
    }

    // Set initial progress
    state = {...state, setName: 0.0};

    // Get cards from the provider
    final cardsAsync = ref.read(cardListProvider);
    final allCards = cardsAsync.value ?? [];
    
    // Filter cards by set and those with a valid image URL
    final setCards = allCards
        .where((card) => card.setName == setName && card.imageUrl.isNotEmpty)
        .toList();

    if (setCards.isEmpty) {
      state = {...state, setName: 1.0};
      return;
    }

    int completed = 0;
    int total = setCards.length;

    // To prevent network overload, download sequentially (or you could batch them)
    for (var card in setCards) {
      try {
        await DefaultCacheManager().downloadFile(card.imageUrl);
      } catch (e) {
        // Ignore individual errors (like 404) and continue
      }
      completed++;
      
      // Update progress
      state = {...state, setName: completed / total};
    }
  }
}

final downloadProgressProvider = NotifierProvider<DownloadProgressNotifier, Map<String, double>>(() {
  return DownloadProgressNotifier();
});

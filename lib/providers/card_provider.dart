import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vg_card.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// Menggunakan AsyncNotifier untuk menerapkan arsitektur Offline-First
class CardListNotifier extends AsyncNotifier<List<VgCard>> {
  @override
  Future<List<VgCard>> build() async {
    // 1. Coba load dari local database terlebih dahulu
    final dbService = ref.read(databaseServiceProvider);
    final localCards = await dbService.getCards();

    // 2. Jika local DB kosong, langsung fetch dari API
    if (localCards.isEmpty) {
      return await _fetchAndCacheCards();
    }

    // 3. Jika local DB ada data, kembalikan data tersebut agar UI cepat merender.
    // Lalu jalankan sync background.
    _syncBackground();

    return localCards;
  }

  Future<void> _syncBackground() async {
    try {
      final newCards = await _fetchAndCacheCards();
      // Update state Riverpod dengan data terbaru secara reaktif
      state = AsyncData(newCards);
    } catch (e) {
      // Jika background sync gagal (misal tidak ada internet), 
      // kita diamkan saja dan biarkan state menggunakan data lokal (offline).
      // Anda bisa menambahkan logging di sini.
      debugPrint('Background sync failed: $e');
    }
  }

  Future<List<VgCard>> _fetchAndCacheCards() async {
    final apiService = ref.read(apiServiceProvider);
    final dbService = ref.read(databaseServiceProvider);

    // Ambil dari server (dummy untuk saat ini)
    final remoteCards = await apiService.fetchCards();
    
    // Simpan ke local DB
    if (remoteCards.isNotEmpty) {
      await dbService.insertCards(remoteCards);
    }
    
    return remoteCards;
  }
  
  // Method untuk interaksi User (misal pull-to-refresh)
  Future<void> refresh() async {
    state = const AsyncLoading(); // Set UI ke loading sementara fetch
    try {
      final newCards = await _fetchAndCacheCards();
      state = AsyncData(newCards);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final cardListProvider = AsyncNotifierProvider<CardListNotifier, List<VgCard>>(() {
  return CardListNotifier();
});

// Notifier untuk menyimpan teks pencarian user
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query;
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

// Provider turunan untuk menghasilkan list kartu yang sudah di-filter berdasarkan setName dan query
final filteredCardsProvider = Provider.family<AsyncValue<List<VgCard>>, String>((ref, setName) {
  final cardsAsync = ref.watch(cardListProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  return cardsAsync.whenData((cards) {
    var filtered = cards.where((card) => card.setName == setName).toList();
    if (query.isNotEmpty) {
      filtered = filtered
          .where((card) => card.name.toLowerCase().contains(query))
          .toList();
    }
    return filtered;
  });
});

// Provider to extract unique sets from the card list
final setsProvider = Provider<AsyncValue<List<String>>>((ref) {
  final cardsAsync = ref.watch(cardListProvider);
  return cardsAsync.whenData((cards) {
    final sets = cards
        .map((c) => c.setName)
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    sets.sort();
    return sets;
  });
});

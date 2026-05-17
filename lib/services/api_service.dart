import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/vg_card.dart';

class ApiService {
  // Service to simulate backend DB fetch by loading from local JSON asset
  Future<List<VgCard>> fetchCards() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/vanguard_combined.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      List<VgCard> allCards = [];
      for (var setJson in jsonList) {
        if (setJson['cards'] != null) {
          final List<dynamic> cardsList = setJson['cards'];
          allCards.addAll(cardsList.map((json) => VgCard.fromScrapedJson(json)));
        }
      }
      return allCards;
    } catch (e) {
      print('Error loading cards from JSON: $e');
      return [];
    }
  }
}

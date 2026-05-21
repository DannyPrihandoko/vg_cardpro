class VgCard {
  final String id;
  final String name;
  final String imageUrl;
  final String unitType;
  final String clan;
  final String nation;
  final String race;
  final String grade;
  final String power;
  final String critical;
  final String shield;
  final String skill;
  final String trigger;
  final String effectText;
  final String setName;
  final String rarity;
  final String regulation;
  final String illustrator;
  final String flavorText;

  VgCard({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.unitType,
    required this.clan,
    required this.nation,
    required this.race,
    required this.grade,
    required this.power,
    required this.critical,
    required this.shield,
    required this.skill,
    required this.trigger,
    required this.effectText,
    required this.setName,
    required this.rarity,
    required this.regulation,
    required this.illustrator,
    required this.flavorText,
  });

  factory VgCard.fromJson(Map<String, dynamic> json) {
    return VgCard(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      unitType: json['unitType'] ?? '',
      clan: json['clan'] ?? '',
      nation: json['nation'] ?? '',
      race: json['race'] ?? '',
      grade: json['grade'] ?? '',
      power: json['power'] ?? '',
      critical: json['critical'] ?? '',
      shield: json['shield'] ?? '',
      skill: json['skill'] ?? '',
      trigger: json['trigger'] ?? '',
      effectText: (json['effectText'] ?? '').replaceAll(r'\n', '\n'),
      setName: json['setName'] ?? '',
      rarity: json['rarity'] ?? '',
      regulation: json['regulation'] ?? '',
      illustrator: json['illustrator'] ?? '',
      flavorText: (json['flavorText'] ?? '').replaceAll(r'\n', '\n'),
    );
  }

  factory VgCard.fromScrapedJson(Map<String, dynamic> json) {
    return VgCard(
      id: json['card_number'] ?? '',
      name: json['name']?['translated'] ?? json['name']?['original'] ?? '',
      imageUrl: json['image_url'] ?? '',
      unitType: json['unit_type'] ?? '',
      clan: json['clan'] ?? '',
      nation: json['nation'] ?? '',
      race: json['race'] ?? '',
      grade: json['grade'] ?? '',
      power: json['power'] ?? '',
      critical: json['critical'] ?? '',
      shield: json['shield'] ?? '',
      skill: json['skill'] ?? '',
      trigger: json['trigger'] ?? '',
      effectText: (json['effect_text']?['translated'] ?? json['effect_text']?['original'] ?? '').replaceAll(r'\n', '\n'),
      setName: json['set_name'] ?? '',
      rarity: json['rarity'] ?? '',
      regulation: json['regulation'] ?? '',
      illustrator: json['illustrator'] ?? '',
      flavorText: (json['flavor_text']?['translated'] ?? json['flavor_text']?['original'] ?? '').replaceAll(r'\n', '\n'),
    );
  }

  // ── Trigger helpers ──────────────────────────────────────────────────────
  /// True if this card has any trigger icon (heal, crit, draw, front, over)
  bool get isTriggerUnit {
    final t = trigger.trim().toLowerCase();
    return t.isNotEmpty && t != '-' && t != 'none';
  }

  /// True if this card is a Heal Trigger
  bool get isHealTrigger {
    final t = trigger.trim().toLowerCase();
    return t.contains('heal');
  }

  /// True if this card is an Over Trigger
  bool get isOverTrigger {
    final t = trigger.trim().toLowerCase();
    return t.contains('over');
  }

  /// True if this card has an explicit nation (not empty, not '-')
  bool get hasNation {
    return nation.trim().isNotEmpty && nation.trim() != '-';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'unitType': unitType,
      'clan': clan,
      'nation': nation,
      'race': race,
      'grade': grade,
      'power': power,
      'critical': critical,
      'shield': shield,
      'skill': skill,
      'trigger': trigger,
      'effectText': effectText,
      'setName': setName,
      'rarity': rarity,
      'regulation': regulation,
      'illustrator': illustrator,
      'flavorText': flavorText,
    };
  }
}

/// Enum representing all recognized mechanic functions a Vanguard card can have.
/// Tags are parsed automatically from the card's English effect text.
enum MechanicTag {
  /// "draw 1 card", "add ... to your hand"
  drawEngine,

  /// "Soul Charge (X)"
  soulCharger,

  /// "Counter Charge (X)"
  counterCharger,

  /// "+5000 Power", "+10000 Power", "Power +"
  powerBooster,

  /// "retire", "move to drop zone" (opponent's units)
  retire,

  /// "look at the top X cards", "search your deck"
  searcher,

  /// "Persona Shield Ticket", "Persona Ride"
  personalRideSupport,

  /// "call ... from the drop zone"
  callFromDrop,

  /// "[Stand]" — stand a unit
  standUnit,

  /// "cannot intercept", "cannot stand" (lock/pressure effects)
  pressureLock,

  /// Heal Trigger icon
  healTrigger,

  /// Uses "Soul Blast" as part of COST
  soulBlastCost,

  /// Uses "Counter Blast" as part of COST
  counterBlastCost,

  /// Uses "Energy Blast" as part of COST
  energyBlastCost,

  /// Synergy with Normal Order or Set Order cards
  orderSynergy,

  /// Synergy with the bind zone
  bindZoneSynergy,

  /// Moves self or another unit to the Guardian Circle (G)
  guardianCaller,

  /// Buffs front row units
  frontRow,

  /// Over Trigger icon
  overTrigger,

  /// Critical Trigger icon
  critTrigger,

  /// Draw Trigger icon
  drawTrigger,

  /// Front Trigger icon
  frontTrigger,
}

/// Extension to get a human-readable display label for each tag.
extension MechanicTagLabel on MechanicTag {
  String get label {
    switch (this) {
      case MechanicTag.drawEngine:       return 'Draw Engine';
      case MechanicTag.soulCharger:      return 'Soul Charger';
      case MechanicTag.counterCharger:   return 'Counter Charger';
      case MechanicTag.powerBooster:     return 'Power Booster';
      case MechanicTag.retire:           return 'Retire';
      case MechanicTag.searcher:         return 'Searcher';
      case MechanicTag.personalRideSupport: return 'Persona Ride';
      case MechanicTag.callFromDrop:     return 'Drop Call';
      case MechanicTag.standUnit:        return 'Stand';
      case MechanicTag.pressureLock:     return 'Lock/Pressure';
      case MechanicTag.healTrigger:      return 'Heal Trigger';
      case MechanicTag.soulBlastCost:    return 'Soul Blast';
      case MechanicTag.counterBlastCost: return 'Counter Blast';
      case MechanicTag.energyBlastCost:  return 'Energy Blast';
      case MechanicTag.orderSynergy:     return 'Order Synergy';
      case MechanicTag.bindZoneSynergy:  return 'Bind Zone';
      case MechanicTag.guardianCaller:   return 'Guardian Caller';
      case MechanicTag.frontRow:         return 'Front Row';
      case MechanicTag.overTrigger:      return 'Over Trigger';
      case MechanicTag.critTrigger:      return 'Crit Trigger';
      case MechanicTag.drawTrigger:      return 'Draw Trigger';
      case MechanicTag.frontTrigger:     return 'Front Trigger';
    }
  }

  /// Serialize to a string key for DB storage.
  String get key => name;

  /// Deserialize from a string key.
  static MechanicTag? fromKey(String key) {
    return MechanicTag.values.where((t) => t.name == key).firstOrNull;
  }
}

/// Utility: serialize/deserialize a list of tags to/from a comma-separated string.
class MechanicTagCodec {
  static String encode(List<MechanicTag> tags) =>
      tags.map((t) => t.key).join(',');

  static List<MechanicTag> decode(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    return raw
        .split(',')
        .map((k) => MechanicTagLabel.fromKey(k.trim()))
        .whereType<MechanicTag>()
        .toList();
  }
}

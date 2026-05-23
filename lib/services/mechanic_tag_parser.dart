import '../models/mechanic_tag.dart';

/// Automatically parses mechanic tags from a card's English effect text.
///
/// All matching is case-insensitive and based on regex patterns derived from
/// the translated effect text in the Vanguard card database.
class MechanicTagParser {
  MechanicTagParser._();

  // ── Pre-compiled patterns (case-insensitive) ──────────────────────────────

  static final _drawEngine = RegExp(
    r'draw \d+ card|add .{1,30} to (your )?hand|add .{1,30} to hand',
    caseSensitive: false,
  );

  static final _soulCharger = RegExp(
    r'soul charge',
    caseSensitive: false,
  );

  static final _counterCharger = RegExp(
    r'counter charge',
    caseSensitive: false,
  );

  static final _powerBooster = RegExp(
    r'power \+\d|gets \+\d+000 power|\+\d+000 power|power\+\d',
    caseSensitive: false,
  );

  static final _retire = RegExp(
    r'\bretire\b',
    caseSensitive: false,
  );

  static final _searcher = RegExp(
    r'look at (the )?top \d+ card|look at \d+ card|search your deck',
    caseSensitive: false,
  );

  static final _personalRideSupport = RegExp(
    r'persona shield|persona ride',
    caseSensitive: false,
  );

  static final _callFromDrop = RegExp(
    r'call .{1,40} from (the )?drop zone|call from (the )?drop',
    caseSensitive: false,
  );

  static final _standUnit = RegExp(
    r'\[stand\]|make .{1,20} \[stand\]',
    caseSensitive: false,
  );

  static final _pressureLock = RegExp(
    r'cannot intercept|cannot .{0,10}stand during|cannot (be )?stand',
    caseSensitive: false,
  );

  static final _soulBlastCost = RegExp(
    r'cost \[soul blast|soul blast \(',
    caseSensitive: false,
  );

  static final _counterBlastCost = RegExp(
    r'cost \[counter blast|counter blast \(',
    caseSensitive: false,
  );

  static final _energyBlastCost = RegExp(
    r'cost \[energy blast|energy blast \(',
    caseSensitive: false,
  );

  static final _orderSynergy = RegExp(
    r'normal order|set order',
    caseSensitive: false,
  );

  static final _bindZone = RegExp(
    r'bind zone|bind this card|banish',
    caseSensitive: false,
  );

  static final _guardianCaller = RegExp(
    r'move .{1,20} to \(g\)|placed on \(g\)|call .{1,20} to \(g\)',
    caseSensitive: false,
  );

  static final _frontRow = RegExp(
    r'front row',
    caseSensitive: false,
  );

  // Trigger icon patterns — also check the `trigger` field separately
  static final _healTrigger = RegExp(
    r'heal trigger',
    caseSensitive: false,
  );
  static final _overTrigger = RegExp(
    r'over trigger',
    caseSensitive: false,
  );
  static final _critTrigger = RegExp(
    r'critical trigger|crit trigger',
    caseSensitive: false,
  );
  static final _drawTrigger = RegExp(
    r'draw trigger',
    caseSensitive: false,
  );
  static final _frontTrigger = RegExp(
    r'front trigger',
    caseSensitive: false,
  );

  // ── Public API ────────────────────────────────────────────────────────────

  /// Parse [effectText] and optionally [triggerField] (the card's `trigger`
  /// field, e.g. "heal", "critical") to produce a deduplicated list of tags.
  ///
  /// [effectText] should be the translated English text.
  static List<MechanicTag> parse(String effectText, {String triggerField = ''}) {
    final text = effectText.toLowerCase();
    final triggerLower = triggerField.toLowerCase().trim();
    final tags = <MechanicTag>{};

    if (_drawEngine.hasMatch(text))           tags.add(MechanicTag.drawEngine);
    if (_soulCharger.hasMatch(text))          tags.add(MechanicTag.soulCharger);
    if (_counterCharger.hasMatch(text))       tags.add(MechanicTag.counterCharger);
    if (_powerBooster.hasMatch(text))         tags.add(MechanicTag.powerBooster);
    if (_retire.hasMatch(text))               tags.add(MechanicTag.retire);
    if (_searcher.hasMatch(text))             tags.add(MechanicTag.searcher);
    if (_personalRideSupport.hasMatch(text))  tags.add(MechanicTag.personalRideSupport);
    if (_callFromDrop.hasMatch(text))         tags.add(MechanicTag.callFromDrop);
    if (_standUnit.hasMatch(text))            tags.add(MechanicTag.standUnit);
    if (_pressureLock.hasMatch(text))         tags.add(MechanicTag.pressureLock);
    if (_soulBlastCost.hasMatch(text))        tags.add(MechanicTag.soulBlastCost);
    if (_counterBlastCost.hasMatch(text))     tags.add(MechanicTag.counterBlastCost);
    if (_energyBlastCost.hasMatch(text))      tags.add(MechanicTag.energyBlastCost);
    if (_orderSynergy.hasMatch(text))         tags.add(MechanicTag.orderSynergy);
    if (_bindZone.hasMatch(text))             tags.add(MechanicTag.bindZoneSynergy);
    if (_guardianCaller.hasMatch(text))       tags.add(MechanicTag.guardianCaller);
    if (_frontRow.hasMatch(text))             tags.add(MechanicTag.frontRow);

    // Trigger tags — check both effect text and dedicated trigger field
    if (_healTrigger.hasMatch(text) || triggerLower.contains('heal'))
      tags.add(MechanicTag.healTrigger);
    if (_overTrigger.hasMatch(text) || triggerLower.contains('over'))
      tags.add(MechanicTag.overTrigger);
    if (_critTrigger.hasMatch(text) || triggerLower.contains('crit'))
      tags.add(MechanicTag.critTrigger);
    if (_drawTrigger.hasMatch(text) || triggerLower.contains('draw'))
      tags.add(MechanicTag.drawTrigger);
    if (_frontTrigger.hasMatch(text) || triggerLower.contains('front'))
      tags.add(MechanicTag.frontTrigger);

    return tags.toList();
  }
}

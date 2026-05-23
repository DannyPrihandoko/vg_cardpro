# 🧠 AI Rekomendasi Pengganti Kartu — Master Context

> **Dokumen ini dibuat sebagai acuan jika sesi AI habis.**
> Jika Anda adalah AI baru yang membaca ini: baca seluruh dokumen sebelum melakukan apapun.
> Update bagian `## ✅ Progress Checkpoint` setiap kali satu komponen selesai dikerjakan.

---

## 📌 Informasi Proyek

| Field | Value |
|-------|-------|
| **Nama Proyek** | VG CardPro |
| **Lokasi** | `g:\Project\VG_cardpro\vg_cardpro` |
| **Framework** | Flutter (Dart) |
| **State Management** | Riverpod (`flutter_riverpod: ^2.5.1`) |
| **Database Lokal** | SQLite via `sqflite` |
| **Navigasi** | CupertinoTabScaffold (3 tab: Cards, My Decks, Profile) |

---

## 🎯 Tujuan Fitur

Membangun sistem AI **fully offline** (tanpa internet, tanpa ML eksternal) yang:
1. Merekomendasikan **kartu pengganti** berdasarkan kesamaan efek/mekanik
2. Mempertimbangkan **format regulasi** (D-Standard / Premium)
3. Mempertimbangkan **konteks deck** pengguna (kartu apa yang sudah ada)
4. Berjalan **100% on-device** menggunakan algoritma similarity scoring di Dart

---

## 🏗️ Arsitektur Sistem

```
effect_text (translated, Bahasa Inggris)
        │
        ▼
[1] MechanicTagParser          ← Parser regex otomatis → list tag mekanik
        │ List<MechanicTag>
        ▼
[2] CardSimilarityEngine       ← Hitung skor kesamaan antar 2 kartu
        │ double score (0.0 – 1.0)
        ▼
[3] RecommendationProvider     ← Riverpod: terima input kartu & deck context
        │ List<CardRecommendation>
        ▼
[4] RecommendationScreen       ← UI hasil rekomendasi
```

---

## 📂 Struktur File yang Akan Dibuat / Dimodifikasi

### File BARU (8 file)

| Path | Status | Keterangan |
|------|--------|-----------|
| `lib/models/mechanic_tag.dart` | ⬜ TODO | Enum 22 tag mekanik kartu |
| `lib/models/card_recommendation.dart` | ⬜ TODO | Model hasil rekomendasi |
| `lib/models/deck_context.dart` | ⬜ TODO | Konteks deck untuk rekomendasi |
| `lib/services/mechanic_tag_parser.dart` | ⬜ TODO | Parser otomatis effect_text → tags |
| `lib/services/card_similarity_engine.dart` | ⬜ TODO | Engine hitung similarity score |
| `lib/services/tag_initialization_service.dart` | ⬜ TODO | Inisialisasi tag saat DB upgrade |
| `lib/providers/recommendation_provider.dart` | ⬜ TODO | Riverpod provider rekomendasi |
| `lib/screens/recommendation_screen.dart` | ⬜ TODO | UI halaman rekomendasi |

### File DIMODIFIKASI (3 file)

| Path | Status | Perubahan |
|------|--------|-----------|
| `lib/models/vg_card.dart` | ⬜ TODO | Tambah field `mechanicTags` + getter lazy parse |
| `lib/services/database_service.dart` | ⬜ TODO | Upgrade ke DB versi 5, tambah kolom `mechanicTags` |
| `lib/screens/card_detail_screen.dart` | ⬜ TODO | Tambah tombol "Find Replacements" di bottom bar |

---

## 🗂️ Detail Data & Model

### Struktur `vanguard_database.json` (SUDAH ADA)
```json
{
  "card_number": "DZ-SS16/001",
  "name": { "original": "...", "translated": "..." },
  "image_url": "...",
  "unit_type": "normal unit",
  "grade": "2",
  "nation": "dragon empire",
  "clan": "",
  "race": "dragonoid",
  "power": "10000",
  "shield": "5000",
  "critical": "1",
  "skill": "intercept",
  "trigger": "-",
  "rarity": "",
  "regulation": "",
  "illustrator": "",
  "effect_text": { "original": "...", "translated": "..." },
  "flavor_text": { "original": "...", "translated": "..." }
}
```

### Model `VgCard` (SUDAH ADA, di `lib/models/vg_card.dart`)
Fields: `id, name, imageUrl, unitType, clan, nation, race, grade, power, critical, shield, skill, trigger, effectText, setName, rarity, regulation, illustrator, flavorText`

**Yang perlu ditambah:** `List<MechanicTag> mechanicTags`

---

## 🏷️ MechanicTag Enum (22 Tag)

```dart
enum MechanicTag {
  drawEngine,          // "draw 1 card", "add to hand"
  soulCharger,         // "Soul Charge"
  counterCharger,      // "Counter Charge"
  powerBooster,        // "+5000 Power", "+10000 Power"
  retire,              // "retire", "move to drop zone"
  searcher,            // "look at top X cards", "search your deck"
  personalRideSupport, // "Persona Shield Ticket", "Persona Ride"
  callFromDrop,        // "call from drop zone"
  standUnit,           // "[Stand]" unit
  pressureLock,        // "cannot intercept", "cannot stand"
  healTrigger,         // "Heal Trigger"
  soulBlastCost,       // uses "Soul Blast" as cost
  counterBlastCost,    // uses "Counter Blast" as cost
  energyBlastCost,     // uses "Energy Blast" as cost
  orderSynergy,        // "Normal Order", "Set Order"
  bindZoneSynergy,     // "bind zone"
  guardianCaller,      // moves to (G)
  frontRow,            // front row power boost
  overTrigger,         // "Over Trigger"
  critTrigger,         // "Critical Trigger"
  drawTrigger,         // "Draw Trigger"
  frontTrigger,        // "Front Trigger"
}
```

---

## 🔍 MechanicTagParser — Pola Regex

Parser membaca `card.effectText` (translated, Bahasa Inggris). Case-insensitive matching:

| Pattern | Tag yang dihasilkan |
|---------|-------------------|
| `draw \d+ card` / `add .+ to (your )?hand` | `drawEngine` |
| `Soul Charge` | `soulCharger` |
| `Counter Charge` | `counterCharger` |
| `\+\d+000 Power` / `Power \+` | `powerBooster` |
| `retire` | `retire` |
| `look at (the )?top \d+ card` / `search your deck` | `searcher` |
| `Persona Shield` / `Persona Ride` | `personalRideSupport` |
| `call .+ from (the )?drop zone` | `callFromDrop` |
| `\[Stand\]` (lawan/friendly) | `standUnit` |
| `cannot intercept` / `cannot .+ stand` | `pressureLock` |
| `COST \[Soul Blast` | `soulBlastCost` |
| `COST \[Counter Blast` | `counterBlastCost` |
| `COST \[Energy Blast` | `energyBlastCost` |
| `Normal Order` / `Set Order` | `orderSynergy` |
| `bind zone` | `bindZoneSynergy` |
| `move .+ to \(G\)` | `guardianCaller` |
| `front row` | `frontRow` |
| `Heal Trigger` / `trigger: heal` | `healTrigger` |
| `Over Trigger` / `trigger: over` | `overTrigger` |
| `Critical Trigger` / `trigger: crit` | `critTrigger` |
| `Draw Trigger` / `trigger: draw` | `drawTrigger` |
| `Front Trigger` / `trigger: front` | `frontTrigger` |

---

## ⚖️ Formula Similarity Scoring

**Total skor = 0.0 – 1.0** (dinormalisasi dari bobot di bawah)

| Dimensi | Bobot | Logika |
|---------|-------|--------|
| **Mechanic Tag Overlap** | 40% | Jaccard: `intersection / union` dari tag set |
| **Grade Match** | 20% | Grade sama = 1.0, beda 1 = 0.5, beda >1 = 0.0 |
| **Nation Compatibility** | 15% | Nation sama = 1.0, kosong/no-nation = 0.7, beda = 0.0 |
| **Regulation Match** | 15% | Format sama = 1.0, salah satu kosong = 0.5, beda = 0.0 |
| **Power/Shield Match** | 10% | `1 - abs(targetPower - candidatePower) / 20000` |

**Bonus dari DeckContext (opsional, tambahan):**
- `+0.05` jika kartu belum ada di deck (prioritas alternatif baru)
- `+0.03` jika grade slot di deck masih punya ruang

**Formula:**
```dart
double score = (tagScore * 0.40) +
               (gradeScore * 0.20) +
               (nationScore * 0.15) +
               (regulationScore * 0.15) +
               (statScore * 0.10);
score = (score + deckBonus).clamp(0.0, 1.0);
```

---

## 📊 Model Hasil Rekomendasi

```dart
class CardRecommendation {
  final VgCard card;
  final double similarityScore;        // 0.0 – 1.0
  final List<MechanicTag> matchedTags; // Tag yang sama dengan target
  final List<String> reasons;          // Penjelasan human-readable, contoh:
                                       // "Same grade (2)"
                                       // "Shares: Draw Engine, Power Booster"
                                       // "Compatible with Dragon Empire deck"
  final bool isInDeck;                 // Sudah ada di deck?
  final bool regulationMatch;          // Format regulasi sama?
}
```

---

## 🃏 DeckContext Model

```dart
class DeckContext {
  final String? deckId;
  final String? deckNation;            // mis. "dragon empire"
  final String? regulationFormat;      // mis. "D-Standard", "Premium"
  final List<String> existingCardIds;  // ID kartu yang sudah ada di deck
  final Map<int, int> gradeCounts;     // grade → jumlah kartu (untuk slot check)
}
```

---

## 🗄️ Database Upgrade (v4 → v5)

Di `database_service.dart`:

```dart
// Versi dari 4 ke 5
version: 5,

// Di _onUpgrade:
if (oldVersion < 5) {
  await db.execute('ALTER TABLE cards ADD COLUMN mechanicTags TEXT');
}

// Method baru:
Future<void> updateCardMechanicTags(String cardId, String tagsString);
// tagsString = tag dipisah koma: "drawEngine,soulCharger,powerBooster"
```

---

## 🎨 UI RecommendationScreen — Layout

```
┌─────────────────────────────────────┐
│  AppBar: "Find Replacements"        │
│  subtitle: [Nama Kartu Target]      │
├─────────────────────────────────────┤
│  Filter Bar:                        │
│  [Regulation: All ▼] [Nation: All ▼]│
│  [Deck: No Deck ▼]                  │
├─────────────────────────────────────┤
│  Target Card Mini Preview:          │
│  [Gambar kecil] Nama | Grade | Tags │
├─────────────────────────────────────┤
│  ─── Hasil Rekomendasi (X kartu) ── │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ [Gambar] Nama Kartu         │   │
│  │ ████████░░  82%             │   │
│  │ ✓ Draw  ✓ Boost  ✓ Soul     │   │
│  │ "Grade sama • Nation cocok" │   │
│  │             [➕ Add to Deck] │   │
│  └─────────────────────────────┘   │
│  (scroll, 15 hasil)                 │
└─────────────────────────────────────┘
```

**Design style:** Dark mode (warna utama `0xFF111827`), accent `0xFF60A5FA` (biru), animasi score bar, chip tag dengan warna berbeda per kategori.

---

## 🔗 Entry Point ke RecommendationScreen

### 1. Dari CardDetailScreen (UTAMA)
Ganti bottom bar info text dengan tombol aktif:
```dart
// Di card_detail_screen.dart — bottomNavigationBar
ElevatedButton.icon(
  icon: Icon(Icons.auto_awesome),
  label: Text('Find Replacements'),
  onPressed: () => Navigator.push(context,
    MaterialPageRoute(builder: (_) => 
      RecommendationScreen(targetCard: card))
  ),
)
```

### 2. Dari BuildDeckScreen (SEKUNDER — implementasi menyusul)
Tombol ikon kecil per kartu di daftar deck → buka RecommendationScreen dengan deck context aktif.

---

## 🔄 Alur Inisialisasi Tag (Sekali Jalan)

```
App pertama kali dibuka (atau DB diupgrade ke v5)
    │
    ▼
CardListNotifier.build() memanggil TagInitializationService
    │
    ▼
Cek: apakah semua kartu sudah punya mechanicTags di DB?
    │
    ├─ Ya → skip, lanjut normal
    │
    └─ Tidak → parse semua kartu:
           for each card in allCards:
             tags = MechanicTagParser.parse(card.effectText)
             db.updateCardMechanicTags(card.id, tags.join(','))
           (Dilakukan di background isolate jika perlu)
```

---

## ✔️ Keputusan Desain yang Sudah Dikonfirmasi User

| # | Pertanyaan | Jawaban |
|---|------------|--------|
| 1 | Kartu dengan regulasi kosong | **Tampilkan dengan skor netral** (label "Unknown") |
| 2 | Sumber data kartu | **`vanguard_combined.json`** (yang sedang dipakai app) |
| 3 | Entry point BuildDeckScreen | **Cek detail** → tombol per kartu di `_buildCardItem` di `_MainDeckTab` |

### Detail Entry Point BuildDeckScreen
- Di `_MainDeckTab._buildCardItem()` (sekitar baris 1627), setiap kartu ditampilkan sebagai `Card` dengan `InkWell`
- Di sebelah kanan sudah ada tombol `+` dan `-` untuk quantity
- Tambahkan tombol ikon `Icons.auto_awesome` kecil di row yang sama
- Pass `deck context` (nation, existingCardIds) ke `RecommendationScreen`
- **Ini implementasi sekunder** — prioritas utama tetap dari `CardDetailScreen`

---

## ✅ Progress Checkpoint

### Phase 0: Persiapan
| # | Task | Status | Catatan |
|---|------|--------|---------|
| 0.1 | Buat dokumen context ini | ✅ | |
| 0.2 | Konfirmasi semua keputusan desain dari user | ✅ | |

### Phase 1: Model & Enum
| # | Task | Status | Catatan |
|---|------|--------|---------|
| 1.1 | Buat `lib/models/mechanic_tag.dart` | ✅ | 22 tag + codec |
| 1.2 | Buat `lib/models/card_recommendation.dart` | ✅ | |
| 1.3 | Buat `lib/models/deck_context.dart` | ✅ | |
| 1.4 | Modifikasi `lib/models/vg_card.dart` (tambah mechanicTags) | ✅ | `resolvedTags` getter + lazy parse |

### Phase 2: Services (Core AI Logic)
| # | Task | Status | Catatan |
|---|------|--------|---------|
| 2.1 | Buat `lib/services/mechanic_tag_parser.dart` | ✅ | Regex parser |
| 2.2 | Buat `lib/services/card_similarity_engine.dart` | ✅ | Weighted formula |
| 2.3 | Buat `lib/services/tag_initialization_service.dart` | ✅ | compute isolate |
| 2.4 | Modifikasi `lib/services/database_service.dart` (v5 upgrade) | ✅ | ALTER TABLE + bulk update |

### Phase 3: State Management
| # | Task | Status | Catatan |
|---|------|--------|---------|
| 3.1 | Buat `lib/providers/recommendation_provider.dart` | ✅ | |
| 3.2 | Hook inisialisasi tag di `card_provider.dart` | ✅ | `_initTagsInBackground()` |

### Phase 4: UI
| # | Task | Status | Catatan |
|---|------|--------|---------|
| 4.1 | Buat `lib/screens/recommendation_screen.dart` | ⬜ | |
| 4.2 | Modifikasi `lib/screens/card_detail_screen.dart` | ⬜ | Tambah tombol |
| 4.3 | (Opsional) Widget `lib/widgets/recommendation_card_widget.dart` | ⬜ | |

### Phase 5: Testing & Polish
| # | Task | Status | Catatan |
|---|------|--------|---------|
| 5.1 | Build & run app, verifikasi tidak ada error kompilasi | ⬜ | |
| 5.2 | Test alur: buka kartu → Find Replacements → hasil muncul | ⬜ | |
| 5.3 | Test filter regulasi | ⬜ | |
| 5.4 | Test dengan deck context aktif | ⬜ | |

---

## 🐛 Known Issues / Catatan Teknis

- **Field `regulation` banyak yang kosong** di `vanguard_database.json` — handling dengan skor netral
- **Field `clan` banyak yang kosong** di era DZ — tidak digunakan untuk filtering utama
- **DB versi saat ini: 4** — upgrade ke 5 dengan `ALTER TABLE cards ADD COLUMN mechanicTags TEXT`
- **`sqflite_common_ffi`** sudah ada di pubspec.yaml (untuk Windows support)
- **`assets/`** di pubspec sudah include semua file di folder assets

---

## 📋 Cara Melanjutkan (Instruksi untuk AI Baru)

Jika Anda adalah AI baru yang membaca ini, lakukan langkah berikut:

1. **Baca dokumen ini sampai selesai**
2. **Cek kolom Status di Progress Checkpoint** — lanjutkan dari task yang belum selesai
3. **Jangan mengubah file yang sudah selesai** kecuali ada bug yang perlu diperbaiki
4. **Setelah selesai setiap phase**, update kolom Status di tabel di atas
5. **Jika ada pertanyaan yang belum dikonfirmasi user**, tanyakan sebelum implementasi
6. **Ikuti pola kode yang sudah ada:**
   - Riverpod untuk state management
   - Singleton pattern untuk services
   - `AsyncNotifier` untuk operasi async
   - Dark mode colors: background `0xFF111827`, surface `0xFF1E293B`, accent `0xFF60A5FA`

---

*Dokumen terakhir diupdate: 2026-05-23 | Phase: 0 (Perencanaan)*

#!/usr/bin/env python3
"""
============================================================
  One Piece Card Game – Web Scraper (v2)
  Scrape per-set, simpan gambar booster & link gambar kartu
============================================================

INSTALL:
    pip install playwright beautifulsoup4
    playwright install chromium

CARA PAKAI:
    # Scrape satu set (OP-15)
    python onepiece_scraper.py --set OP-15

    # Scrape semua set sekaligus
    python onepiece_scraper.py --all

    # Lihat daftar set yang tersedia
    python onepiece_scraper.py --list

    # Parse dari file HTML tersimpan (tanpa browser)
    python onepiece_scraper.py --set OP-15 --from-file halaman.html

OUTPUT (per set):
    output/
    ├── sets_index.json          ← metadata + image semua set
    ├── OP-15/
    │   ├── cards.json
    │   └── cards.csv
    ├── OP-14/
    │   ├── cards.json
    │   └── cards.csv
    └── ...
"""

import argparse, csv, json, re, sys, time
from pathlib import Path

BASE_URL   = "https://asia-en.onepiece-cardgame.com"
OUTPUT_DIR = Path("output")
USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/124.0.0.0 Safari/537.36"
)

# ─── Database Set ─────────────────────────────────────────────────────────────
# Format: set_code → {series_id, name, type, release_date, product_page}
# Image URL booster digenerate otomatis dari pola URL yang ditemukan

SETS: dict[str, dict] = {
    # ── BOOSTER PACK (OP) ──────────────────────────────────────────────
    "OP-01": {
        "series_id": "556101",
        "name": "ROMANCE DAWN",
        "type": "BOOSTER PACK",
        "release_date": "2022-12-02",
        "product_page": f"{BASE_URL}/products/boosters/op01.php",
    },
    "OP-02": {
        "series_id": "556102",
        "name": "Paramount War",
        "type": "BOOSTER PACK",
        "release_date": "2023-03-10",
        "product_page": f"{BASE_URL}/products/boosters/op02.php",
    },
    "OP-03": {
        "series_id": "556103",
        "name": "Pillars of Strength",
        "type": "BOOSTER PACK",
        "release_date": "2023-06-09",
        "product_page": f"{BASE_URL}/products/boosters/op03.php",
    },
    "OP-04": {
        "series_id": "556104",
        "name": "Kingdoms of Intrigue",
        "type": "BOOSTER PACK",
        "release_date": "2023-09-22",
        "product_page": f"{BASE_URL}/products/boosters/op04.php",
    },
    "OP-05": {
        "series_id": "556105",
        "name": "Awakening of the New Era",
        "type": "BOOSTER PACK",
        "release_date": "2023-12-08",
        "product_page": f"{BASE_URL}/products/boosters/op05.php",
    },
    "OP-06": {
        "series_id": "556106",
        "name": "Wings of Captain",
        "type": "BOOSTER PACK",
        "release_date": "2023-11-25",
        "product_page": f"{BASE_URL}/products/boosters/op06.php",
    },
    "OP-07": {
        "series_id": "556107",
        "name": "500 Years in the Future",
        "type": "BOOSTER PACK",
        "release_date": "2024-02-24",
        "product_page": f"{BASE_URL}/products/boosters/op07.php",
    },
    "OP-08": {
        "series_id": "556108",
        "name": "Two Legends",
        "type": "BOOSTER PACK",
        "release_date": "2024-05-25",
        "product_page": f"{BASE_URL}/products/boosters/op08.php",
    },
    "OP-09": {
        "series_id": "556109",
        "name": "Emperors in the New World",
        "type": "BOOSTER PACK",
        "release_date": "2024-08-31",
        "product_page": f"{BASE_URL}/products/boosters/op09.php",
    },
    "OP-10": {
        "series_id": "556110",
        "name": "Royal Blood",
        "type": "BOOSTER PACK",
        "release_date": "2024-11-30",
        "product_page": f"{BASE_URL}/products/boosters/op10.php",
    },
    "OP-11": {
        "series_id": "556111",
        "name": "A Fist of Divine Speed",
        "type": "BOOSTER PACK",
        "release_date": "2025-03-01",
        "product_page": f"{BASE_URL}/products/boosters/op11.php",
    },
    "OP-12": {
        "series_id": "556112",
        "name": "Legacy of the Master",
        "type": "BOOSTER PACK",
        "release_date": "2025-05-31",
        "product_page": f"{BASE_URL}/products/boosters/op12.php",
    },
    "OP-13": {
        "series_id": "556113",
        "name": "Carrying on His Will",
        "type": "BOOSTER PACK",
        "release_date": "2025-08-23",
        "product_page": f"{BASE_URL}/products/boosters/op13.php",
    },
    "OP-14": {
        "series_id": "556114",
        "name": "The Azure Sea's Seven",
        "type": "BOOSTER PACK",
        "release_date": "2025-11-22",
        "product_page": f"{BASE_URL}/products/boosters/op14.php",
    },
    "OP-15": {
        "series_id": "556115",
        "name": "Adventure on KAMI's Island",
        "type": "BOOSTER PACK",
        "release_date": "2026-02-28",
        "product_page": f"{BASE_URL}/products/boosters/op15.php",
    },
    # ── EXTRA BOOSTER (EB) ─────────────────────────────────────────────
    "EB-01": {
        "series_id": "556201",
        "name": "Memorial Collection",
        "type": "EXTRA BOOSTER",
        "release_date": "2024-01-27",
        "product_page": f"{BASE_URL}/products/boosters/eb01.php",
    },
    "EB-02": {
        "series_id": "556202",
        "name": "Anime 25th collection",
        "type": "EXTRA BOOSTER",
        "release_date": "2025-01-25",
        "product_page": f"{BASE_URL}/products/boosters/eb02.php",
    },
    "EB-03": {
        "series_id": "556203",
        "name": "ONE PIECE Heroines Edition",
        "type": "EXTRA BOOSTER",
        "release_date": "2025-10-25",
        "product_page": f"{BASE_URL}/products/boosters/eb03.php",
    },
    "EB-04": {
        "series_id": "556204",
        "name": "EGGHEAD CRISIS",
        "type": "EXTRA BOOSTER",
        "release_date": "2026-01-31",
        "product_page": f"{BASE_URL}/products/boosters/eb04.php",
    },
    # ── PREMIUM BOOSTER (PRB) ──────────────────────────────────────────
    "PRB-01": {
        "series_id": "556301",
        "name": "ONE PIECE CARD THE BEST",
        "type": "PREMIUM BOOSTER",
        "release_date": "2024-07-27",
        "product_page": f"{BASE_URL}/products/boosters/prb01.php",
    },
    "PRB-02": {
        "series_id": "556302",
        "name": "ONE PIECE CARD THE BEST vol.2",
        "type": "PREMIUM BOOSTER",
        "release_date": "2025-07-26",
        "product_page": f"{BASE_URL}/products/boosters/prb02.php",
    },
    # ── STARTER DECK (ST) ──────────────────────────────────────────────
    "ST-01": {
        "series_id": "556401",
        "name": "Straw Hat Crew",
        "type": "STARTER DECK",
        "release_date": "2022-12-02",
        "product_page": f"{BASE_URL}/products/decks/st01.php",
    },
    "ST-02": {
        "series_id": "556402",
        "name": "Worst Generation",
        "type": "STARTER DECK",
        "release_date": "2022-12-02",
        "product_page": f"{BASE_URL}/products/decks/st02.php",
    },
    "ST-03": {
        "series_id": "556403",
        "name": "The Seven Warlords of the Sea",
        "type": "STARTER DECK",
        "release_date": "2022-12-02",
        "product_page": f"{BASE_URL}/products/decks/st03.php",
    },
    "ST-04": {
        "series_id": "556404",
        "name": "Animal Kingdom Pirates",
        "type": "STARTER DECK",
        "release_date": "2023-03-10",
        "product_page": f"{BASE_URL}/products/decks/st04.php",
    },
    "ST-05": {
        "series_id": "556405",
        "name": "ONE PIECE FILM edition",
        "type": "STARTER DECK",
        "release_date": "2023-03-10",
        "product_page": f"{BASE_URL}/products/decks/st05.php",
    },
    "ST-06": {
        "series_id": "556406",
        "name": "The Navy",
        "type": "STARTER DECK",
        "release_date": "2023-06-09",
        "product_page": f"{BASE_URL}/products/decks/st06.php",
    },
    "ST-07": {
        "series_id": "556407",
        "name": "Big Mom Pirates",
        "type": "STARTER DECK",
        "release_date": "2023-06-09",
        "product_page": f"{BASE_URL}/products/decks/st07.php",
    },
    "ST-08": {
        "series_id": "556408",
        "name": "Side Monkey.D.Luffy",
        "type": "STARTER DECK",
        "release_date": "2023-09-22",
        "product_page": f"{BASE_URL}/products/decks/st08.php",
    },
    "ST-09": {
        "series_id": "556409",
        "name": "Side Yamato",
        "type": "STARTER DECK",
        "release_date": "2023-09-22",
        "product_page": f"{BASE_URL}/products/decks/st09.php",
    },
    "ST-10": {
        "series_id": "556410",
        "name": "The Three Captains",
        "type": "ULTIMATE DECK",
        "release_date": "2023-12-08",
        "product_page": f"{BASE_URL}/products/decks/st10.php",
    },
    "ST-11": {
        "series_id": "556411",
        "name": "Side Uta",
        "type": "STARTER DECK",
        "release_date": "2023-09-22",
        "product_page": f"{BASE_URL}/products/decks/st11.php",
    },
    "ST-12": {
        "series_id": "556412",
        "name": "Zoro & Sanji",
        "type": "STARTER DECK",
        "release_date": "2024-02-24",
        "product_page": f"{BASE_URL}/products/decks/st12.php",
    },
    "ST-13": {
        "series_id": "556413",
        "name": "The Three Brothers Bond",
        "type": "ULTIMATE DECK",
        "release_date": "2024-05-25",
        "product_page": f"{BASE_URL}/products/decks/st13.php",
    },
    "ST-14": {
        "series_id": "556414",
        "name": "3D2Y",
        "type": "STARTER DECK",
        "release_date": "2024-08-31",
        "product_page": f"{BASE_URL}/products/decks/st14.php",
    },
    "ST-15": {
        "series_id": "556415",
        "name": "Red Edward.Newgate",
        "type": "STARTER DECK",
        "release_date": "2024-08-31",
        "product_page": f"{BASE_URL}/products/decks/st15.php",
    },
    "ST-16": {
        "series_id": "556416",
        "name": "Green Uta",
        "type": "STARTER DECK",
        "release_date": "2024-02-24",
        "product_page": f"{BASE_URL}/products/decks/st16.php",
    },
    "ST-17": {
        "series_id": "556417",
        "name": "Blue Donquixote Doflamingo",
        "type": "STARTER DECK",
        "release_date": "2024-11-30",
        "product_page": f"{BASE_URL}/products/decks/st17.php",
    },
    "ST-18": {
        "series_id": "556418",
        "name": "Purple Monkey.D.Luffy",
        "type": "STARTER DECK",
        "release_date": "2024-11-30",
        "product_page": f"{BASE_URL}/products/decks/st18.php",
    },
    "ST-19": {
        "series_id": "556419",
        "name": "Black Smoker",
        "type": "STARTER DECK",
        "release_date": "2024-11-30",
        "product_page": f"{BASE_URL}/products/decks/st19.php",
    },
    "ST-20": {
        "series_id": "556420",
        "name": "Yellow Charlotte Katakuri",
        "type": "STARTER DECK",
        "release_date": "2024-11-30",
        "product_page": f"{BASE_URL}/products/decks/st20.php",
    },
    "ST-21": {
        "series_id": "556421",
        "name": "GEAR5",
        "type": "STARTER DECK EX",
        "release_date": "2025-03-01",
        "product_page": f"{BASE_URL}/products/decks/st21.php",
    },
    "ST-22": {
        "series_id": "556422",
        "name": "Ace & Newgate",
        "type": "STARTER DECK",
        "release_date": "2025-03-01",
        "product_page": f"{BASE_URL}/products/decks/st22.php",
    },
    "ST-23": {
        "series_id": "556423",
        "name": "Red Shanks",
        "type": "STARTER DECK",
        "release_date": "2025-05-31",
        "product_page": f"{BASE_URL}/products/decks/st23.php",
    },
    "ST-24": {
        "series_id": "556424",
        "name": "Green Jewelry Bonney",
        "type": "STARTER DECK",
        "release_date": "2025-05-31",
        "product_page": f"{BASE_URL}/products/decks/st24.php",
    },
    "ST-25": {
        "series_id": "556425",
        "name": "Blue Buggy",
        "type": "STARTER DECK",
        "release_date": "2025-08-23",
        "product_page": f"{BASE_URL}/products/decks/st25.php",
    },
    "ST-26": {
        "series_id": "556426",
        "name": "Purple/Black Monkey.D.Luffy",
        "type": "STARTER DECK",
        "release_date": "2025-08-23",
        "product_page": f"{BASE_URL}/products/decks/st26.php",
    },
    "ST-27": {
        "series_id": "556427",
        "name": "Black Marshall.D.Teach",
        "type": "STARTER DECK",
        "release_date": "2025-11-22",
        "product_page": f"{BASE_URL}/products/decks/st27.php",
    },
    "ST-28": {
        "series_id": "556428",
        "name": "Green/Yellow Yamato",
        "type": "STARTER DECK",
        "release_date": "2025-11-22",
        "product_page": f"{BASE_URL}/products/decks/st28.php",
    },
    "ST-29": {
        "series_id": "556429",
        "name": "EGGHEAD",
        "type": "STARTER DECK",
        "release_date": "2026-01-31",
        "product_page": f"{BASE_URL}/products/decks/st29.php",
    },
    "ST-30": {
        "series_id": "556430",
        "name": "Luffy & Ace",
        "type": "STARTER DECK EX",
        "release_date": "2026-02-28",
        "product_page": f"{BASE_URL}/products/decks/st30.php",
    },
}


def get_set_images(set_code: str) -> dict[str, str]:
    """
    Hasilkan URL gambar untuk sebuah set berdasarkan pola URL yang ditemukan.
    Pola: /renewal/images/products/{kategori}/{kode}/img_item01.webp
    Contoh kartu: /renewal/images/products/boosters/op15/cards/{CARD_ID}.webp
    """
    code_lower = set_code.lower().replace("-", "")  # "op15", "st01", "eb04"

    # Tentukan subfolder berdasarkan tipe
    info = SETS.get(set_code, {})
    ptype = info.get("type", "")
    if "STARTER" in ptype or "ULTIMATE" in ptype:
        category = "decks"
    else:
        category = "boosters"

    img_base = f"{BASE_URL}/renewal/images/products/{category}/{code_lower}"
    return {
        "box_image":    f"{img_base}/img_item01.webp",
        "banner_image": f"{img_base}/mv.webp",
        "bg_image":     f"{img_base}/sp/bg_mv.webp",
        "cards_folder": f"{img_base}/cards/",   # + {CARD_ID}.webp
    }


def card_image_url(card_id: str) -> str:
    """
    URL gambar individual kartu di halaman card list.
    Pola: /images/cardlist/card/{CARD_ID}_p1.png
    """
    return f"{BASE_URL}/images/cardlist/card/{card_id}_p1.png"


# ─── Parser ───────────────────────────────────────────────────────────────────

CARD_ID_RE = re.compile(
    r"^([A-Z]{1,5}\d*-\d+)\s*\|\s*([A-Z]+)\s*\|\s*(LEADER|CHARACTER|EVENT|STAGE)",
    re.IGNORECASE,
)
SPLIT_RE = re.compile(
    r"(?=(?:OP|ST|EB|PRB)\d*-\d+\s*\|\s*"
    r"(?:L|C|UC|R|SR|SEC|SP|RR|RRR)\s*\|\s*"
    r"(?:LEADER|CHARACTER|EVENT|STAGE))",
    re.IGNORECASE,
)
LABELS = {
    "cost": "cost",
    "life": "life",
    "attribute": "attribute",
    "power": "power",
    "counter": "counter",
    "color": "color",
    "block   icon": "block_icon",
    "block icon": "block_icon",
    "type": "type",
    "effect": "effect",
    "trigger": "trigger",
    "card set(s)": "card_set",
    "card sets": "card_set",
}
NOISE = {"ボタン", "TEXT VIEW", "CARD VIEW", "[TEXT VIEW]", "[CARD VIEW]"}


def parse_cards_from_html(html: str) -> list[dict]:
    from bs4 import BeautifulSoup
    soup = BeautifulSoup(html, "html.parser")
    for tag in soup(["script", "style", "noscript"]):
        tag.decompose()
    raw = soup.get_text(separator="\n")
    sections = [s.strip() for s in SPLIT_RE.split(raw) if s.strip()]

    cards, seen = [], set()
    for sec in sections:
        card = _parse_section(sec)
        if card and card["card_id"] not in seen:
            seen.add(card["card_id"])
            # Tambahkan URL gambar kartu
            card["card_image_url"] = card_image_url(card["card_id"])
            cards.append(card)
    return cards


def _parse_section(section: str) -> dict | None:
    lines = [l.strip() for l in section.splitlines() if l.strip()]
    if not lines:
        return None
    m = CARD_ID_RE.match(lines[0])
    if not m:
        return None

    card_id   = m.group(1).strip()
    rarity    = m.group(2).strip()
    card_type = m.group(3).strip().title()

    name = ""
    for ln in lines[1:]:
        if ln in NOISE or ln.startswith("http") or ln.startswith("!["):
            continue
        name = ln
        break

    card = dict(
        card_id=card_id, name=name, rarity=rarity, card_type=card_type,
        cost=None, life=None, attribute=None, power=None, counter=None,
        color=None, block_icon=None, type=None, effect=None,
        trigger=None, card_set=None, card_image_url=None,
    )

    i = 0
    while i < len(lines):
        field = LABELS.get(lines[i].lower())
        if field:
            vals, i = [], i + 1
            while i < len(lines) and lines[i].lower() not in LABELS:
                if lines[i] not in NOISE and not lines[i].startswith("http"):
                    if lines[i] != "-":
                        vals.append(lines[i])
                i += 1
            card[field] = "\n".join(vals).strip() or None
        else:
            i += 1
    return card


# ─── Deteksi set dari card_id ─────────────────────────────────────────────────

_SET_CODE_RE = re.compile(r"^([A-Z]+)(\d+)-\d+$", re.IGNORECASE)

def detect_set_code(card_id: str) -> str | None:
    """'OP15-001' → 'OP-15',  'ST01-001' → 'ST-01',  'EB04-001' → 'EB-04'"""
    m = _SET_CODE_RE.match(card_id)
    if not m:
        return None
    prefix = m.group(1).upper()   # OP, ST, EB, PRB
    num    = m.group(2).lstrip("0") or "0"  # "15"
    return f"{prefix}-{num.zfill(2)}"       # "OP-15"


# ─── Scraper (Playwright) ─────────────────────────────────────────────────────

def scrape_set(series_id: str, delay: float = 0) -> list[dict]:
    """Scrape satu set berdasarkan series_id."""
    try:
        from playwright.sync_api import sync_playwright, TimeoutError as PWTimeout
    except ImportError:
        print("❌  Playwright belum terinstall.")
        print("    pip install playwright && playwright install chromium")
        sys.exit(1)

    url = f"{BASE_URL}/cardlist/?series={series_id}"
    if delay:
        time.sleep(delay)

    with sync_playwright() as p:
        browser = p.chromium.launch(
            headless=True,
            args=["--no-sandbox", "--disable-blink-features=AutomationControlled"],
        )
        ctx = browser.new_context(
            user_agent=USER_AGENT, locale="en-US",
            viewport={"width": 1280, "height": 900},
        )
        page = ctx.new_page()
        page.route("**/*.{png,jpg,jpeg,gif,webp,svg,woff,woff2,ttf}",
                   lambda r: r.abort())
        page.goto(url, wait_until="domcontentloaded", timeout=60_000)

        # Tunggu kartu muncul
        try:
            page.wait_for_selector("dl, .resultCol", timeout=20_000)
        except Exception:
            pass

        # Klik "Add more" sampai habis
        for _ in range(20):
            try:
                btn = page.query_selector(
                    "a:has-text('Add more'), button:has-text('Add more')"
                )
                if btn and btn.is_visible():
                    btn.scroll_into_view_if_needed()
                    btn.click()
                    page.wait_for_timeout(1500)
                else:
                    break
            except Exception:
                break

        page.wait_for_timeout(1000)
        html = page.content()
        browser.close()

    return parse_cards_from_html(html)


def parse_from_file(filepath: str) -> list[dict]:
    path = Path(filepath)
    if not path.exists():
        print(f"❌  File tidak ditemukan: {filepath}")
        sys.exit(1)
    html = path.read_text(encoding="utf-8", errors="replace")
    return parse_cards_from_html(html)


# ─── Output ───────────────────────────────────────────────────────────────────

def save_cards(cards: list[dict], directory: Path, set_code: str) -> None:
    directory.mkdir(parents=True, exist_ok=True)
    json_path = directory / "cards.json"
    csv_path  = directory / "cards.csv"

    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(cards, f, ensure_ascii=False, indent=2)

    if cards:
        with open(csv_path, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=list(cards[0].keys()))
            writer.writeheader()
            writer.writerows(cards)

    print(f"  💾  {set_code}: {len(cards)} kartu → {directory}")


def save_sets_index(results: dict[str, dict], path: Path) -> None:
    """Simpan index semua set + metadata + image URL."""
    index = {}
    for set_code, info in results.items():
        entry = {**SETS.get(set_code, {})}
        entry["set_code"]    = set_code
        entry["cardlist_url"] = (
            f"{BASE_URL}/cardlist/?series={entry.get('series_id','')}"
        )
        entry["images"]      = get_set_images(set_code)
        entry["total_cards"] = info.get("total_cards", 0)
        entry["scraped"]     = info.get("scraped", False)
        index[set_code]      = entry

    with open(path, "w", encoding="utf-8") as f:
        json.dump(index, f, ensure_ascii=False, indent=2)
    print(f"\n📋  Sets index → {path}  ({len(index)} set)")


# ─── CLI ──────────────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(
        description="One Piece TCG Scraper – per set, dengan gambar",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("--set", metavar="CODE",
        help="Kode set, contoh: OP-15, ST-01, EB-04")
    parser.add_argument("--all", action="store_true",
        help="Scrape semua set")
    parser.add_argument("--list", action="store_true",
        help="Tampilkan daftar set yang tersedia")
    parser.add_argument("--from-file", metavar="FILE",
        help="Parse dari file HTML tersimpan (tanpa browser)")
    parser.add_argument("--output-dir", default="output",
        help="Direktori output (default: ./output)")
    parser.add_argument("--delay", type=float, default=2.0,
        help="Jeda antar set dalam detik (default: 2)")
    args = parser.parse_args()

    global OUTPUT_DIR
    OUTPUT_DIR = Path(args.output_dir)

    # ── --list ────────────────────────────────────────────────────────
    if args.list:
        print(f"\n{'SET CODE':<10} {'TYPE':<20} {'NAME':<40} {'RELEASE':<12}")
        print("─" * 85)
        for code, info in SETS.items():
            print(
                f"{code:<10} {info['type']:<20} "
                f"{info['name']:<40} {info['release_date']}"
            )
        print(f"\nTotal: {len(SETS)} set")
        return

    # ── Tentukan target set ───────────────────────────────────────────
    if args.all:
        targets = list(SETS.keys())
    elif args.set:
        code = args.set.upper()
        if code not in SETS:
            print(f"❌  Set '{code}' tidak dikenal. Gunakan --list untuk melihat daftar.")
            sys.exit(1)
        targets = [code]
    else:
        parser.print_help()
        sys.exit(0)

    results: dict[str, dict] = {}

    for i, set_code in enumerate(targets):
        info     = SETS[set_code]
        delay    = args.delay if i > 0 else 0
        print(f"\n🗂️  [{i+1}/{len(targets)}] {set_code} – {info['name']}")

        if args.from_file:
            cards = parse_from_file(args.from_file)
            # Filter hanya kartu yang sesuai set ini
            cards = [c for c in cards
                     if detect_set_code(c["card_id"]) == set_code]
        else:
            try:
                cards = scrape_set(info["series_id"], delay=delay)
            except Exception as e:
                print(f"  ⚠️  Gagal scrape {set_code}: {e}")
                results[set_code] = {"total_cards": 0, "scraped": False}
                continue

        set_dir = OUTPUT_DIR / set_code
        save_cards(cards, set_dir, set_code)
        results[set_code] = {"total_cards": len(cards), "scraped": True}

    # Tambahkan entry untuk set yang belum di-scrape ke index
    if args.all:
        for code in SETS:
            if code not in results:
                results[code] = {"total_cards": 0, "scraped": False}

    # Simpan index
    save_sets_index(results, OUTPUT_DIR / "sets_index.json")

    total = sum(v["total_cards"] for v in results.values())
    scraped_ok = sum(1 for v in results.values() if v["scraped"])
    print(f"\n✅  Selesai! {scraped_ok}/{len(results)} set, {total} kartu total")
    print(f"    Output: {OUTPUT_DIR.resolve()}/")


if __name__ == "__main__":
    main()

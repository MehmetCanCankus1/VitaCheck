"""
VitaCheck — Google Cloud Vision OCR Engine  v1.0
=================================================
EasyOCR / Tesseract'ı tamamen bırakıp Google Cloud Vision API'ya geçiyoruz.

Mimari:
  vision_ocr.py   ← Bu dosya: OCR + JSON dönüştürücü + hata yakalama
  risk_analyzer.py← Beyin katmanı: 10 hastalık filtresi + karar mekanizması

Kullanım:
  python vision_ocr.py <görsel_yolu> [--disease diyabet]
  python vision_ocr.py gorsel.jpg --disease hipertansiyon
  python vision_ocr.py gorsel.jpg          # sadece JSON çıktısı

Gereksinimler:
  pip install google-cloud-vision
  credentials.json  ← Google Cloud service-account JSON anahtar dosyası
                       (proje kök dizinine koy, ben otomatik okuyacağım)
"""

from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path
from typing import Any

# ── Kimlik bilgisi: credentials.json proje kökünde bekleniyor ─────────────────
_CRED_FILE = Path(__file__).parent.parent / "credentials.json"
if _CRED_FILE.exists():
    os.environ.setdefault("GOOGLE_APPLICATION_CREDENTIALS", str(_CRED_FILE))


# ─────────────────────────────────────────────────────────────────────────────
# BÖLÜM 1 — BESİN ADI EŞLEŞTİRME
# ─────────────────────────────────────────────────────────────────────────────

# Canonical JSON çıktı anahtarları
STANDARD_KEYS = {
    "Energy_kcal",
    "Energy_kJ",
    "Fat_g",
    "SaturatedFat_g",
    "Carbohydrate_g",
    "Sugar_g",
    "Fiber_g",
    "Protein_g",
    "Salt_g",
    "Sodium_mg",
    "Potassium_mg",
    "Calcium_mg",
    "Magnesium_mg",
    "Zinc_mg",
    "VitaminC_mg",
    "VitaminD_mcg",
    "VitaminB6_mg",
    "Serving_g",       # porsiyon gramajı (metadan)
}

# Türkçe / İngilizce OCR metni → standart JSON anahtarı
_NAME_MAP: dict[str, str] = {
    # Enerji
    "enerji": "Energy_kcal",
    "energy": "Energy_kcal",
    "eneigy": "Energy_kcal",
    "enerj": "Energy_kcal",
    "enerjikcal": "Energy_kcal",
    "kj": "Energy_kJ",
    # Yağ
    "yag": "Fat_g",
    "yaglar": "Fat_g",
    "fat": "Fat_g",
    "fats": "Fat_g",
    "toplam yag": "Fat_g",
    "total fat": "Fat_g",
    # Doymuş yağ
    "doymus yag": "SaturatedFat_g",
    "saturated fat": "SaturatedFat_g",
    "saturates": "SaturatedFat_g",
    "of which saturates": "SaturatedFat_g",
    "doymus": "SaturatedFat_g",
    # Karbonhidrat
    "karbonhidrat": "Carbohydrate_g",
    "karbonhidratlar": "Carbohydrate_g",
    "carbohydrate": "Carbohydrate_g",
    "carbohydrates": "Carbohydrate_g",
    "toplam karbonhidrat": "Carbohydrate_g",
    # Şeker
    "seker": "Sugar_g",
    "sekerler": "Sugar_g",
    "sugar": "Sugar_g",
    "sugars": "Sugar_g",
    "of which sugars": "Sugar_g",
    # Lif
    "lif": "Fiber_g",
    "fiber": "Fiber_g",
    "fibre": "Fiber_g",
    "dietary fiber": "Fiber_g",
    # Protein
    "protein": "Protein_g",
    "proteinler": "Protein_g",
    "prolein": "Protein_g",
    # Tuz
    "tuz": "Salt_g",
    "salt": "Salt_g",
    "iuzl": "Salt_g",
    # Sodyum
    "sodyum": "Sodium_mg",
    "sodium": "Sodium_mg",
    # Potasyum
    "potasyum": "Potassium_mg",
    "potassium": "Potassium_mg",
    "polasyum": "Potassium_mg",
    # Kalsiyum
    "kalsiyum": "Calcium_mg",
    "calcium": "Calcium_mg",
    # Magnezyum
    "magnezyum": "Magnesium_mg",
    "magnesium": "Magnesium_mg",
    # Çinko
    "cinko": "Zinc_mg",
    "zinc": "Zinc_mg",
    # Vitaminler
    "c vitamini": "VitaminC_mg",
    "vitamin c": "VitaminC_mg",
    "d vitamini": "VitaminD_mcg",
    "vitamin d": "VitaminD_mcg",
    "b6 vitamini": "VitaminB6_mg",
    "vitamin b6": "VitaminB6_mg",
    # Porsiyon / Servis — metadata satırı (Serving_g key'e yönlendir)
    "porsiyon": "Serving_g",
    "porsiyonbasi": "Serving_g",
    "servis": "Serving_g",
    "servis basina": "Serving_g",
    "net agirlik": "Serving_g",
    "net weight": "Serving_g",
    "adet": "Serving_g",
    "portion": "Serving_g",
    "serving": "Serving_g",
    "serving size": "Serving_g",
    "per portion": "Serving_g",
    "per serving": "Serving_g",
    "pack": "Serving_g",
    "paket": "Serving_g",
}


def _normalize_text(s: str) -> str:
    """Türkçe karakterleri ASCII'ye indir, küçük harf yap."""
    return (
        s.lower()
        .replace("ı", "i").replace("ş", "s").replace("ğ", "g")
        .replace("ü", "u").replace("ö", "o").replace("ç", "c")
        .replace("â", "a").replace("î", "i").replace("û", "u")
        .strip()
    )


def _find_standard_key(raw_name: str) -> str | None:
    """Ham besin adından standart JSON anahtarını bul."""
    norm = _normalize_text(raw_name)
    # Doğrudan eşleşme
    if norm in _NAME_MAP:
        return _NAME_MAP[norm]
    # Alt-dizi araması (örn. "of which sugars" içinde "sugar" geçiyor)
    for alias, key in _NAME_MAP.items():
        if alias in norm:
            return key
    return None


# ─────────────────────────────────────────────────────────────────────────────
# BÖLÜM 2 — DEĞER TEMİZLEME
# ─────────────────────────────────────────────────────────────────────────────

def _clean_numeric(raw: str) -> tuple[float | None, str]:
    """
    Ham değer dizgesinden (numeric_float, birim) döndür.
    Virgül → nokta dönüşümü, OCR gürültüsü temizleme.
    Kritik kural: 6.2 → 6.2 (620 değil!)
    """
    s = raw.strip()
    # Yaygın OCR hatalarını düzelt: O/o -> 0, I/l -> 1
    s = s.replace("O", "0").replace("o", "0")
    
    # Boşluk içindeki rakamları birleştir: "6 .2" → "6.2"
    s = re.sub(r"(\d)\s+\.\s*(\d)", r"\1.\2", s)

    # Virgülü ondalık ayracı olarak kabul et: "6,2" → "6.2"
    if s.count(",") == 1 and re.search(r"\d,\d", s):
        s = s.replace(",", ".")

    # OCR artefaktı: "6.2g" → sayı "6.2", birim "g"
    m = re.match(
        r"^([0-9]+(?:\.[0-9]+)?)\s*"
        r"(kcal|kj|g|mg|mcg|µg|ml|l|%)?",
        s,
        re.IGNORECASE,
    )
    if not m:
        return None, ""

    val_str = m.group(1)
    unit = (m.group(2) or "").lower().strip()

    try:
        val = float(val_str)
    except ValueError:
        return None, unit

    return val, unit


# ─────────────────────────────────────────────────────────────────────────────
# BÖLÜM 3 — GÖRÜNTÜ ÖN İŞLEME & GOOGLE CLOUD VISION API ENTEGRASYONU
# ─────────────────────────────────────────────────────────────────────────────

def _preprocess_for_ocr(image_path: str) -> bytes:
    """
    Kavisli yüzeylerden (şişe, kutu vb.) gelen görseller için
    OCR öncesi görüntü ısılahı (image enhancement) uygular.

    Adımlar:
      1. Bilateral filter — gürültü azaltma, kenar koruma
      2. CLAHE          — yerel kontrast normaliz., düzensiz aydınlatmaya karşı
      3. Unsharp masking — metin netl iği artırma
    """
    try:
        import cv2
        import numpy as np

        img = cv2.imread(image_path)
        if img is None:
            with open(image_path, "rb") as f:
                return f.read()

        # 1. Bilateral filter: gürültü azaltır, metin kenarlarını korur
        filtered = cv2.bilateralFilter(img, d=9, sigmaColor=75, sigmaSpace=75)

        # 2. CLAHE: her renk kanalına ayrı ayrı uygula (kavisli yüzeylerdeki
        #    düzensiz aydınlatmayı dengeler)
        lab = cv2.cvtColor(filtered, cv2.COLOR_BGR2LAB)
        l_ch, a_ch, b_ch = cv2.split(lab)
        clahe = cv2.createCLAHE(clipLimit=2.5, tileGridSize=(8, 8))
        l_ch = clahe.apply(l_ch)
        enhanced = cv2.merge([l_ch, a_ch, b_ch])
        enhanced = cv2.cvtColor(enhanced, cv2.COLOR_LAB2BGR)

        # 3. Unsharp masking: metin netliğini artırır
        blurred = cv2.GaussianBlur(enhanced, (0, 0), sigmaX=3)
        sharpened = cv2.addWeighted(enhanced, 1.5, blurred, -0.5, 0)

        _, buf = cv2.imencode(".jpg", sharpened, [cv2.IMWRITE_JPEG_QUALITY, 95])
        return buf.tobytes()

    except ImportError:
        # OpenCV yoksa orijinal dosyayı kullan
        with open(image_path, "rb") as f:
            return f.read()


# —— Inline Regex Fallback ————————————————————————————————————————————————————

# Besin adı → standart anahtar eşleşmesi (inline regex için)
_INLINE_KEY_MAP: list[tuple[re.Pattern, str]] = [
    (re.compile(r'enerj|energy|energ',                  re.I), 'Energy_kcal'),
    (re.compile(r'\bkj\b|kilojoule',                   re.I), 'Energy_kJ'),
    (re.compile(r'doymu[sş]|saturated|saturates',       re.I), 'SaturatedFat_g'),
    (re.compile(r'ya[gğ]|\bfat\b|lipid',              re.I), 'Fat_g'),
    (re.compile(r'karbonhidrat|carbohydrate|carb',      re.I), 'Carbohydrate_g'),
    (re.compile(r'[sş]eker|\bsugar',                   re.I), 'Sugar_g'),
    (re.compile(r'\blif\b|fiber|fibre',                re.I), 'Fiber_g'),
    (re.compile(r'protein|eiwei[sß]|proteine',          re.I), 'Protein_g'),
    (re.compile(r'\btuz\b|\bsalt\b|\bsalz\b',         re.I), 'Salt_g'),
    (re.compile(r'sodyum|sodium|natrium',               re.I), 'Sodium_mg'),
]

# "Keyword [sep] number [unit]" — tek satır veya bitişik metin
_INLINE_VALUE_RE = re.compile(
    r'(?P<num>\d+(?:[.,]\d+)?)\s*'
    r'(?P<unit>kcal|kj|g|mg|mcg|ml|%)?',
    re.IGNORECASE,
)


def _inline_fallback_extract(raw_text: str) -> dict[str, Any]:
    """
    Düz metin (inline) içinden 'Anahtar Kelime — Değer — Birim' üçlü sünü
    regex ile çıkarır.

    Örnek: 'Şeker / Sugars 9,5 g' → Sugar_g: {value: 9.5, unit: 'g'}
    Tablo yapısı bozuk veya sütun çıkarması başarısız olduğunda
    son çare (last-resort) olarak çağrılır.
    """
    result: dict[str, Any] = {}
    lines = [ln.strip() for ln in raw_text.replace('\r', '\n').splitlines() if ln.strip()]

    for line in lines:
        norm_line = _normalize_text(line)

        for pattern, std_key in _INLINE_KEY_MAP:
            if not pattern.search(norm_line):
                continue
            if std_key in result:
                continue

            # Değer + birim ara
            m = _INLINE_VALUE_RE.search(line)
            if not m:
                continue

            raw_num = m.group('num').replace(',', '.')
            try:
                val = float(raw_num)
            except ValueError:
                continue

            unit = (m.group('unit') or '').lower()

            # kcal / kJ ayrımı
            if std_key == 'Energy_kcal':
                if 'kj' in norm_line:
                    std_key = 'Energy_kJ'
                    unit = 'kJ'
                else:
                    unit = unit or 'kcal'

            result[std_key] = {
                'value':      val,
                'unit':       unit,
                'confidence': 0.55,   # inline regex — orta güven
                'source':     'inline_regex_fallback',
            }
            break   # bu satır için ilk eşleşme yeterli

    return result


def _call_vision_api(image_path: str) -> tuple[list[dict], str]:
    """
    Görseli Google Cloud Vision DOCUMENT_TEXT_DETECTION ile tara.
    Döner: (words_list, raw_full_text)
      words_list : [{"text", "x", "y", "x_min", "x_max", "y_min", "y_max", "confidence"}, ...]
      raw_full_text : Google Vision'un ham tam metin çıktısı (str)
    """
    try:
        from google.cloud import vision  # type: ignore
    except ImportError:
        raise ImportError(
            "google-cloud-vision paketi bulunamadı.\n"
            "Yüklemek için: pip install google-cloud-vision"
        )

    client = vision.ImageAnnotatorClient()

    # Ön işleme: kavisli yüzey ve düzensiz aydınlatma düzeltmesi
    content = _preprocess_for_ocr(image_path)

    image = vision.Image(content=content)
    response = client.document_text_detection(image=image)

    if response.error.message:
        raise RuntimeError(
            f"Google Cloud Vision API hatası: {response.error.message}\n"
            "Yardım: https://cloud.google.com/apis/design/errors"
        )

    # Ham tam metin (normalize edilmemiş)
    raw_text: str = response.full_text_annotation.text or ""

    words: list[dict] = []
    for page in response.full_text_annotation.pages:
        for block in page.blocks:
            for paragraph in block.paragraphs:
                for word in paragraph.words:
                    word_text = "".join(
                        symbol.text for symbol in word.symbols
                    )
                    # Güven skoru: sembol bazlı ortalama
                    sym_confs = [
                        s.confidence for s in word.symbols
                        if hasattr(s, "confidence") and s.confidence is not None
                    ]
                    word_conf = round(
                        (sum(sym_confs) / len(sym_confs)) if sym_confs else 0.0, 4
                    )
                    verts = word.bounding_box.vertices
                    xs = [v.x for v in verts]
                    ys = [v.y for v in verts]
                    words.append({
                        "text": word_text,
                        "x": (min(xs) + max(xs)) / 2,
                        "y": (min(ys) + max(ys)) / 2,
                        "x_min": min(xs),
                        "x_max": max(xs),
                        "y_min": min(ys),
                        "y_max": max(ys),
                        "confidence": word_conf,
                    })

    return words, raw_text


def _group_into_lines(words: list[dict], y_tolerance: float = 12.0) -> list[list[dict]]:
    """
    Kelime kutucuklarını Y koordinatına göre satırlara grupla.
    y_tolerance: piksel cinsinden satır yüksekliği payı.
    """
    if not words:
        return []

    sorted_words = sorted(words, key=lambda w: w["y"])
    lines: list[list[dict]] = []
    current_line: list[dict] = [sorted_words[0]]

    for w in sorted_words[1:]:
        avg_y = sum(x["y"] for x in current_line) / len(current_line)
        if abs(w["y"] - avg_y) <= y_tolerance:
            current_line.append(w)
        else:
            current_line.sort(key=lambda x: x["x"])
            lines.append(current_line)
            current_line = [w]

    if current_line:
        current_line.sort(key=lambda x: x["x"])
        lines.append(current_line)

    return lines


def _is_noise_line(line_texts: list[str]) -> bool:
    joined = _normalize_text(" ".join(line_texts))
    # Sadece çok belirgin gürültüleri filtrele
    critical_noise = {"isletme kayit", "uretici", "manufacturer", "address:", "osb"}
    return any(kw in joined for kw in critical_noise)



# ─────────────────────────────────────────────────────────────────────────────
# PORSIYON & ÇOKL U SÜTUN YARDIMCILARI
# ─────────────────────────────────────────────────────────────────────────────

# Porsiyon bilgisi için arama kalıpları
_SERVING_PATTERNS = [
    # "1 porsiyon (30g)", "Porsiyon: 30g", "Servis başına 40g"
    re.compile(
        r'(?:porsiyon|servi[sş]|serving|portion|paket|pack)'
        r'[^\d]{0,20}?(\d+(?:[.,]\d+)?)\s*g',
        re.IGNORECASE | re.UNICODE),
    # "Per 40g", "Per serving (40g)"
    re.compile(
        r'per\s+(?:serving|portion)?\s*\(?\s*(\d+(?:[.,]\d+)?)\s*g',
        re.IGNORECASE),
    # "net ağırlık 30g" / "Net weight 30g"
    re.compile(
        r'net\s+(?:a[gğ]\u0131rl[iı]k|weight)[^\d]{0,10}(\d+(?:[.,]\d+)?)\s*g',
        re.IGNORECASE | re.UNICODE),
]


def extract_serving_size(raw_text: str) -> float | None:
    """
    Ham OCR metninden porsiyon gramını çıkarır.
    Döndürür: gram cinsinden float, bulunamazsa None.

    Örnekler:
      '1 porsiyon (30g)'   → 30.0
      'Per serving (40 g)' → 40.0
      'Paket: 21 g'        → 21.0
    """
    for pat in _SERVING_PATTERNS:
        m = pat.search(raw_text)
        if m:
            try:
                val = float(m.group(1).replace(',', '.'))
                if 5.0 <= val <= 1000.0:   # makul aralık
                    return val
            except ValueError:
                continue
    return None


def _detect_table_columns(lines: list[list[dict]]) -> tuple[float | None, float | None]:
    """
    Tablo başlık satırından '100g' ve 'porsiyon/serving' sütunlarının
    X koordinatlarını tespit eder.

    Döndürür: (x_100g, x_portion)
      Her biri None olabilir (tespit edilemezse).
    """
    KW_100G    = {'100', '100g', '100ml', '100gr'}
    KW_PORTION = {'porsiyon', 'servis', 'serving', 'portion', 'paket', 'pack'}

    x_100g: float | None    = None
    x_portion: float | None = None

    for line in lines:
        texts_lower = [w['text'].lower().strip('.()') for w in line]
        for i, (tok, w) in enumerate(zip(texts_lower, line)):
            if tok in KW_100G and x_100g is None:
                x_100g = float(w['x'])
            if any(kw in tok for kw in KW_PORTION) and x_portion is None:
                x_portion = float(w['x'])
        if x_100g is not None and x_portion is not None:
            break

    return x_100g, x_portion


def _parse_lines(
    lines: list[list[dict]],
    x_100g: float | None = None,
    x_portion: float | None = None,
) -> dict[str, Any]:
    """
    Satır listesinden besin adı → değer çiftlerini çıkar.
    """
    parsed: dict[str, Any] = {}

    for line in lines:
        if not line:
            continue
        
        texts = [w["text"] for w in line]
        line_str = " ".join(texts)
        if _is_noise_line(texts):
           continue

        # 1. Satırdaki tüm potansiyel nutrient anahtarlarını ve konumlarını bul
        found_keys: list[tuple[str, int, int]] = []
        i = 0
        while i < len(texts):
            best_match = None
            for length in range(4, 0, -1):
                if i + length > len(texts):
                    continue
                phrase = " ".join(texts[i : i + length])
                key = _find_standard_key(phrase)
                if key:
                    best_match = (key, i, i + length - 1)
                    break
            if best_match:
                found_keys.append(best_match)
                i = best_match[2] + 1
            else:
                i += 1

        if not found_keys:
            continue

        # DEBUG
        # print(f"[DEBUG] Satır: '{line_str}' | Bulunan Anahtarlar: {[f[0] for f in found_keys]}")

        # 2. Satırdaki tüm sayısal adayları bul
        # Tuple: (val, unit, raw_text, x_min, confidence)
        numeric_candidates: list[tuple[float, str, str, float, float]] = []
        j = 0
        while j < len(line):
            txt = line[j]["text"]
            test_txt = txt.replace("O", "0").replace("o", "0")
            if re.search(r"\d", test_txt) or txt in {".", ","}:
                combined = txt
                start_x_min = line[j]["x_min"]
                word_conf = line[j].get("confidence", 0.0)
                k = j + 1
                while k < len(line):
                    next_txt = line[k]["text"]
                    if (re.search(r"\d", next_txt.replace("O","0").replace("o","0")) or next_txt in {".", ","}) and (line[k]["x_min"] - line[k-1]["x_max"] < 30):
                        combined += next_txt
                        # Birleşen kelimenin güvenini de ortala
                        word_conf = (word_conf + line[k].get("confidence", 0.0)) / 2
                        k += 1
                    else:
                        break
                val, unit = _clean_numeric(combined)
                if val is not None:
                    numeric_candidates.append((val, unit, combined, start_x_min, round(word_conf, 4)))
                j = k
            else:
                j += 1

        # 3. Eşleştirme: her anahtar için birincil (100g) + ikincil (porsiyon) değer bul
        for idx, (key, k_start, k_end) in enumerate(found_keys):
            key_x_max = line[k_end]["x_max"]
            limit_x = 99999.0
            if idx + 1 < len(found_keys):
                limit_x = line[found_keys[idx+1][1]]["x_min"]

            # Geçerli aday sayısal değerler: anahtardan sağda, limit_x solunda
            valid_cands: list[tuple[float, str, str, float, float]] = [
                (val, unit, raw, v_x, conf)
                for val, unit, raw, v_x, conf in numeric_candidates
                if v_x < limit_x and (v_x - key_x_max) > -150
            ]
            if not valid_cands:
                continue

            # Enerji satırında "100g" başlığı sayısal değer gibi algılanabiliyor.
            # Eğer değer 100 ve birim 'g' ise (veya 'g' yoksa ama metin '100g' içeriyorsa), bunu atla.
            if key in ("Energy_kcal", "Energy_kJ"):
                valid_cands = [c for c in valid_cands if not (c[0] == 100.0 and (c[1] == "g" or "100g" in c[2].lower()))]
                if not valid_cands:
                    continue

            # X pozisyonuna göre sırala
            valid_cands.sort(key=lambda c: c[3])

            # Çoklu sütun: 100g başlığının X koordinatına en yakın olanı seç. 
            # Eğer başlık okunamadıysa varsayılan olarak en soldakini (ilkini) al.
            val_main: tuple | None   = None   # (val, unit, raw, conf)
            val_portion: tuple | None = None

            if valid_cands:
                if x_100g is not None:
                    c = min(valid_cands, key=lambda c: abs(c[3] - x_100g))
                else:
                    c = valid_cands[0]
                val_main = (c[0], c[1], c[2], c[4])

            if val_main is None:
                continue

            val, unit, raw, conf = val_main

            if not unit and key not in ("Energy_kcal", "Energy_kJ"):
                unit = "g"

            # ── Enerji özel durumu: kJ/kcal çift sütun ──────────────────────
            if key == "Energy_kcal":
                if "kj" in raw.lower() or val > 500:
                    # val=kJ(100g)  val_portion[0]=kJ(porsiyon)
                    kj_100g = val
                    kj_por  = val_portion[0] if val_portion else None

                    if "Energy_kJ" not in parsed:
                        kj_e: dict[str, Any] = {
                            "per_100g":   kj_100g,
                            "unit":       "kJ",
                            "confidence": conf,
                        }
                        if kj_por is not None:
                            kj_e["per_portion"] = kj_por
                        parsed["Energy_kJ"] = kj_e

                    if "Energy_kcal" not in parsed:
                        kc_e: dict[str, Any] = {
                            "per_100g":   round(kj_100g / 4.184, 1),
                            "unit":       "kcal",
                            "confidence": conf,
                        }
                        if kj_por is not None:
                            kc_e["per_portion"] = round(kj_por / 4.184, 1)
                        parsed["Energy_kcal"] = kc_e
                    continue

            if key not in parsed:
                entry: dict[str, Any] = {
                    "per_100g":   val,
                    "unit":       unit,
                    "confidence": conf,
                }
                if val_portion is not None:
                    pv, pu, _, pc = val_portion
                    if not pu and key not in ("Energy_kcal", "Energy_kJ", "Serving_g"):
                        pu = "g"
                    entry["per_portion"] = pv
                    if key == "Serving_g":
                        entry["per_100g"] = pv
                parsed[key] = entry

    return parsed



# ─────────────────────────────────────────────────────────────────────────────
# BÖLÜM 4 — ANA ANALİZ FONKSİYONU
# ─────────────────────────────────────────────────────────────────────────────

def analyze_image(image_path: str) -> dict[str, Any]:
    """
    Bir gıda etiketi görselini Google Cloud Vision ile tara,
    besin değerlerini standart JSON'a dönüştür.
    """
    import os, json, sys
    from pathlib import Path
    
    if not os.path.isfile(image_path):
        return {"status": "error", "message": f"Görsel bulunamadı: {image_path}", "data": {}}

    try:
        words, raw_text = _call_vision_api(image_path)
    except ImportError as e:
        return {"status": "error", "message": str(e), "data": {}, "raw_text": ""}
    except RuntimeError as e:
        return {"status": "error", "message": str(e), "data": {}, "raw_text": ""}
    except Exception as e:
        return {
            "status": "error",
            "message": (
                f"API çağrısı başarısız: {e}\n"
                "Olası nedenler: internet bağlantısı, proje izinleri veya API kotası."
            ),
            "data": {},
        }

    if not words:
        return {
            "status": "low_quality",
            "message": (
                "Google Vision görselden hiç metin okuyamadı.\n"
                "Lütfen daha yüksek çözünürlüklü veya net bir görsel deneyin."
            ),
            "data": {},
            "raw_text": "",
        }

    # Y toleransı: Tekrar 0.5 çarpanına çektik
    heights = [w["y_max"] - w["y_min"] for w in words if w["y_max"] > w["y_min"]]
    avg_h = (sum(heights) / len(heights)) if heights else 20.0
    y_tol = max(6.0, avg_h * 0.5)

    lines = _group_into_lines(words, y_tolerance=y_tol)

    # Porsiyon boyutu ve sütun konumlarını tespit et
    serving_g          = extract_serving_size(raw_text)
    x_100g, x_portion  = _detect_table_columns(lines)

    parsed = _parse_lines(lines, x_100g=x_100g, x_portion=x_portion)

    if not parsed:
        # Son çare: ham metinden inline regex ile çıkarma dene
        parsed = _inline_fallback_extract(raw_text)

    if not parsed:
        return {
            "status": "low_quality",
            "message": (
                "Görsel okundu fakat tanınan besin değeri bulunamadı.\n"
                "Etiket formatı standart dışı veya tablo çok bozuk olabilir."
            ),
            "data": {},
            "raw_text": raw_text,
        }

    # ── Matematiksel Oran Validas yonu ────────────────────────────────────────────
    # serving_g biliniyorsa: per_100g / per_portion ≈ 100 / serving_g mi?
    if serving_g and serving_g > 0:
        ratio_expected = 100.0 / serving_g
        for key, entry in parsed.items():
            if key in ("Serving_g",):
                continue
            v100 = entry.get("per_100g")
            vpor = entry.get("per_portion")
            if v100 and vpor and vpor > 0 and v100 > 0:
                ratio_actual = v100 / vpor
                # ±25% tolerans
                ratio_ok = abs(ratio_actual - ratio_expected) / ratio_expected <= 0.25
                entry["ratio_ok"] = ratio_ok
                if not ratio_ok:
                    # Değerler yer değiştirildiyse düzelt
                    swapped_ratio = vpor / v100 if v100 > 0 else 0
                    if abs(swapped_ratio - ratio_expected) / ratio_expected <= 0.25:
                        entry["per_100g"], entry["per_portion"] = vpor, v100
                        entry["ratio_ok"]   = True
                        entry["_corrected"] = "per_100g/per_portion swap düzeldi"
            elif v100 and v100 > 0:
                entry["ratio_ok"] = None   # porsiyon verisi yok

    return {
        "status":     "ok",
        "data":       parsed,
        "raw_text":   raw_text,
        "serving_g":  serving_g,      # None veya float (gram)
        "col_detected": {             # çift sütun algı bilgisi
            "x_100g":    x_100g,
            "x_portion": x_portion,
        },
    }


# ─────────────────────────────────────────────────────────────────────────────
# BÖLÜM 5 — KOMut SATIRI ARAYÜZÜ
# ─────────────────────────────────────────────────────────────────────────────

def main() -> None:
    import argparse

    parser = argparse.ArgumentParser(
        description="VitaCheck — Google Cloud Vision Gıda Etiketi Okuyucu"
    )
    parser.add_argument("image", help="Görsel dosya yolu (.jpg / .png / .webp)")
    parser.add_argument(
        "--disease",
        "--hastalik",
        dest="disease",
        default=None,
        help=(
            "Risk analizi yapılacak hastalık. "
            "Seçenekler: diyabet, colyak, hipertansiyon, obesite, "
            "kalp, bobrek, karaciger, fenilketonuri, hipoglisemi, osteoporoz"
        ),
    )
    args = parser.parse_args()

    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]

    print(f"\n{'═'*55}")
    print(f"  VitaCheck — Görsel: {Path(args.image).name}")
    print(f"{'═'*55}")

    result = analyze_image(args.image)
    print("\n📦 OCR JSON Çıktısı:")
    print(json.dumps(result, ensure_ascii=False, indent=2))

    if result["status"] == "ok" and args.disease:
        from risk_analyzer import RiskAnalyzer  # type: ignore

        analyzer = RiskAnalyzer()
        risk_result = analyzer.analyze(result["data"], args.disease)
        print(f"\n{'─'*55}")
        print("🩺 Risk Analizi Sonucu:")
        print(json.dumps(risk_result, ensure_ascii=False, indent=2))

    print(f"\n{'═'*55}\n")


if __name__ == "__main__":
    main()

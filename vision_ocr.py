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
_CRED_FILE = Path(__file__).parent / "credentials.json"
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
# BÖLÜM 3 — GOOGLE CLOUD VISION API ENTEGRASYONU
# ─────────────────────────────────────────────────────────────────────────────

def _call_vision_api(image_path: str) -> list[dict]:
    """
    Görseli Google Cloud Vision DOCUMENT_TEXT_DETECTION ile tara.
    Döner: [{"text": ..., "x": ..., "y": ..., "width": ..., "height": ...}, ...]
    Her öğe bir 'word' seviyesi kutucuktur.
    """
    try:
        from google.cloud import vision  # type: ignore
    except ImportError:
        raise ImportError(
            "google-cloud-vision paketi bulunamadı.\n"
            "Yüklemek için: pip install google-cloud-vision"
        )

    client = vision.ImageAnnotatorClient()

    with open(image_path, "rb") as f:
        content = f.read()

    image = vision.Image(content=content)
    response = client.document_text_detection(image=image)

    if response.error.message:
        raise RuntimeError(
            f"Google Cloud Vision API hatası: {response.error.message}\n"
            "Yardım: https://cloud.google.com/apis/design/errors"
        )

    words: list[dict] = []
    for page in response.full_text_annotation.pages:
        for block in page.blocks:
            for paragraph in block.paragraphs:
                for word in paragraph.words:
                    word_text = "".join(
                        symbol.text for symbol in word.symbols
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
                    })

    return words


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


def _parse_lines(lines: list[list[dict]]) -> dict[str, Any]:
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
        numeric_candidates: list[tuple[float, str, str, float]] = []
        j = 0
        while j < len(line):
            txt = line[j]["text"]
            # 'O' harfini sayısal kontrolde 0 gibi düşün
            test_txt = txt.replace("O", "0").replace("o", "0")
            if re.search(r"\d", test_txt) or txt in {".", ","}:
                combined = txt
                start_x_min = line[j]["x_min"]
                k = j + 1
                while k < len(line):
                    next_txt = line[k]["text"]
                    # Eğer sonraki kutu rakam/nokta ise ve çok yakınsa birleştir
                    if (re.search(r"\d", next_txt.replace("O","0").replace("o","0")) or next_txt in {".", ","}) and (line[k]["x_min"] - line[k-1]["x_max"] < 30):
                        combined += next_txt
                        k += 1
                    else:
                        break
                val, unit = _clean_numeric(combined)
                if val is not None:
                    numeric_candidates.append((val, unit, combined, start_x_min))
                j = k
            else:
                j += 1

        # 3. Eşleştirme (Overlap ve sağdakileri yakala)
        for idx, (key, k_start, k_end) in enumerate(found_keys):
            key_x_max = line[k_end]["x_max"]
            limit_x = 99999.0
            if idx + 1 < len(found_keys):
                limit_x = line[found_keys[idx+1][1]]["x_min"]

            best_val_info = None
            min_abs_dist = 99999.0
            
            for val, unit, raw, v_x in numeric_candidates:
                # Değer, bir sonraki anahtar kelimeden önce olmalı
                if v_x < limit_x:
                    dist = v_x - key_x_max
                    # Çok solda değilse (-150px tolerans) en yakın olanı seç
                    if dist > -150:
                        if abs(dist) < min_abs_dist:
                            min_abs_dist = abs(dist)
                            best_val_info = (val, unit, raw)

            if best_val_info:
                val, unit, raw = best_val_info
                
                if not unit and key not in ("Energy_kcal", "Energy_kJ"):
                    unit = "g"
                
                # Enerji özel durumu: kcal/kJ ikilisi
                if key == "Energy_kcal":
                    if "kj" in raw.lower() or val > 500:
                        parsed["Energy_kJ"] = {"value": val, "unit": "kJ"}
                        # Eğer kcal zaten bulunduysa (başka bir adaydan), onu ezme
                        if "Energy_kcal" not in parsed:
                             val = round(val / 4.184, 1)
                             unit = "kcal"
                        else:
                             continue # kJ değerini Energy_kJ'ye yazdık zaten
                
                if key not in parsed:
                    parsed[key] = {"value": val, "unit": unit}

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
        words = _call_vision_api(image_path)
    except ImportError as e:
        return {"status": "error", "message": str(e), "data": {}}
    except RuntimeError as e:
        return {"status": "error", "message": str(e), "data": {}}
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
        }

    # Y toleransı: Tekrar 0.5 çarpanına çektik
    heights = [w["y_max"] - w["y_min"] for w in words if w["y_max"] > w["y_min"]]
    avg_h = (sum(heights) / len(heights)) if heights else 20.0
    y_tol = max(6.0, avg_h * 0.5)

    lines = _group_into_lines(words, y_tolerance=y_tol)
    parsed = _parse_lines(lines)

    if not parsed:
        return {
            "status": "low_quality",
            "message": (
                "Görsel okundu fakat tanınan besin değeri bulunamadı.\n"
                "Etiket formatı standart dışı veya tablo çok bozuk olabilir."
            ),
            "data": {},
        }

    return {
        "status": "ok",
        "data": parsed,
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

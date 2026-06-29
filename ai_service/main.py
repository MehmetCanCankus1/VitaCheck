"""
VitaCheck — Core Engine  v3.1  (Porsiyon Bazlı Analiz)
=======================================================
Pipeline: Kalite Kontrolü → OCR → Normalizasyon → Porsiyon & Risk Analizi

Kullanım:
    python ai_service/main.py <görsel> [-o sonuc.json]
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Any

# ── Proje kök dizini & credentials ───────────────────────────────────────────
# main.py artık ai_service/ kök dizininde, dolayısıyla parent = proje kökü
PROJECT_ROOT = Path(__file__).resolve().parent
CREDENTIALS  = PROJECT_ROOT / "credentials.json"
if CREDENTIALS.exists():
    os.environ.setdefault("GOOGLE_APPLICATION_CREDENTIALS", str(CREDENTIALS))

# Model dizini koke gore (main.py üst seviyeye taşındı)
_ROOT = PROJECT_ROOT

from ai_service.vision_ocr import analyze_image  # noqa: E402
from ai_service.doctor_service import DoctorService  # noqa: E402

# Google AI Studio'dan aldığın anahtarı buraya yapıştır
GEMINI_API_KEY = "AIzaSyBiUuo619zHN2SKLjce69tUhsR3Gsu7YaM"

# ── Saglik Risk Modeli — Lazy Load (RAM'e bir kez yukle) ─────────────────────
_RISK_MODEL  = None
_RISK_SCALER = None
_MODEL_PATH  = _ROOT / "models" / "health_risk_model.joblib"
_SCALER_PATH = _ROOT / "models" / "scaler.joblib"


def _load_risk_model() -> bool:
    """Modeli RAM'e yukler; yoksa sessizce False doner."""
    global _RISK_MODEL, _RISK_SCALER
    if _RISK_MODEL is not None:
        return True
    if not (_MODEL_PATH.exists() and _SCALER_PATH.exists()):
        return False
    try:
        import joblib
        _RISK_MODEL  = joblib.load(_MODEL_PATH)
        _RISK_SCALER = joblib.load(_SCALER_PATH)
        return True
    except Exception:
        return False


# Baslangicta bir kez yukle (zero-latency inference icin)
_load_risk_model()

# ── Türkçe besin etiketleri ───────────────────────────────────────────────────
_LABELS: dict[str, str] = {
    "Energy_kcal":    "Enerji",
    "Energy_kJ":      "Enerji",
    "Fat_g":          "Yağ",
    "SaturatedFat_g": "Doymuş Yağ",
    "Carbohydrate_g": "Karbonhidrat",
    "Sugar_g":        "Şeker",
    "Fiber_g":        "Lif",
    "Protein_g":      "Protein",
    "Salt_g":         "Tuz",
    "Sodium_mg":      "Sodyum",
    "Potassium_mg":   "Potasyum",
    "Calcium_mg":     "Kalsiyum",
}

# ── Risk eşikleri (per 100g) — AB Nutri-Score kaynaklı ───────────────────────
# (low_limit, high_limit)  → altı "düşük risk", üstü "yüksek risk"
_RISK_THRESHOLDS: dict[str, tuple[float, float]] = {
    "Sugar_g":        (5.0,  22.5),
    "Fat_g":          (3.0,  17.5),
    "SaturatedFat_g": (1.5,   5.0),
    "Salt_g":         (0.3,   1.5),
    "Energy_kcal":    (100,  450.0),
    "Energy_kJ":      (418,  1880.0),
}

_RISK_EMOJI = {"düşük": "🟢", "orta": "🟡", "yüksek": "🔴"}


def _risk_label(value: float, key: str) -> str:
    """Değer için risk seviyesi döndürür: 'düşük' / 'orta' / 'yüksek'."""
    if key not in _RISK_THRESHOLDS:
        return ""
    lo, hi = _RISK_THRESHOLDS[key]
    if value <= lo:
        return "düşük"
    elif value <= hi:
        return "orta"
    else:
        return "yüksek"


# ══════════════════════════════════════════════════════════════════════════════
# ADIM 1 — KALİTE KONTROLÜ
# ══════════════════════════════════════════════════════════════════════════════

BLUR_THRESHOLD  = 50.0
GLARE_THRESHOLD = 0.20
MIN_DIMENSION   = 100

_FAIL_MSGS: dict[str, str] = {
    "missing":     "Dosya bulunamadı.",
    "format":      "Desteklenmeyen dosya formatı.",
    "corrupt":     "Görüntü bozuk veya okunamıyor.",
    "too_small":   "Görüntü çok küçük, daha yüksek çözünürlükte çekin.",
    "blur":        "Görüntü bulanık, lütfen daha net çekin.",
    "glare":       "Parlama tespit edildi, flaşsız veya gölgede çekin.",
    "dark":        "Görüntü çok karanlık, daha aydınlık ortamda çekin.",
    "overexposed": "Görüntü aşırı parlak/yanmış, pozlamayı düşürün.",
}


def image_quality_check(image_path: str) -> dict[str, Any]:
    qr: dict[str, Any] = {
        "passed": False, "failure_reason": None, "message": "",
        "width": None, "height": None,
        "blur_score": None, "brightness": None, "glare_score": None,
    }
    path = Path(image_path)

    if not path.is_file():
        qr["failure_reason"] = "missing"
        qr["message"] = f"Dosya bulunamadı: {image_path}"
        return qr

    supported = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}
    if path.suffix.lower() not in supported:
        qr["failure_reason"] = "format"
        qr["message"] = f"Desteklenmeyen format: {path.suffix}"
        return qr

    try:
        import cv2
        import numpy as np

        img = cv2.imread(str(path))
        if img is None:
            qr["failure_reason"] = "corrupt"
            qr["message"] = "Görüntü okunamadı."
            return qr

        h, w = img.shape[:2]
        qr["width"], qr["height"] = w, h

        if w < MIN_DIMENSION or h < MIN_DIMENSION:
            qr["failure_reason"] = "too_small"
            qr["message"] = f"Görüntü çok küçük ({w}×{h} px)."
            return qr

        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

        blur_score = float(cv2.Laplacian(gray, cv2.CV_64F).var())
        qr["blur_score"] = round(blur_score, 2)
        if blur_score < BLUR_THRESHOLD:
            qr["failure_reason"] = "blur"
            qr["message"] = f"Bulanık ({blur_score:.1f})"
            return qr

        hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
        glare_ratio = float(np.sum(hsv[:, :, 2] > 240)) / (w * h)
        qr["glare_score"] = round(glare_ratio * 100, 1)
        if glare_ratio > GLARE_THRESHOLD:
            qr["failure_reason"] = "glare"
            qr["message"] = f"Parlama %{qr['glare_score']}"
            return qr

        gray2 = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        brightness = float(gray2.mean())
        qr["brightness"] = round(brightness, 2)
        if brightness < 30.0:
            qr["failure_reason"] = "dark"
            qr["message"] = f"Goruntu cok karanlik ({brightness:.1f})"
            return qr

        qr["passed"] = True
        qr["message"] = "OK"
        return qr

    except Exception as e:
        qr["failure_reason"] = "error"
        qr["message"] = f"Kalite kontrol hatasi: {e}"
        return qr


# ==============================================================================
# SAGLIK RISKI ANALIZ MOTORU
# ==============================================================================

# VitaCheck normalized_data key -> model feature adi eslesmeleri
_NORM_TO_FEAT: dict[str, str] = {
    "Energy_kcal":    "energy_kcal_100g",
    "Fat_g":          "fat_100g",
    "SaturatedFat_g": "saturated_fat_100g",
    "TransFat_g":     "trans_fat_100g",
    "Cholesterol_mg": "cholesterol_100g",
    "Carbohydrate_g": "carbohydrates_100g",
    "Sugar_g":        "sugars_100g",
    "Fiber_g":        "fiber_100g",
    "Protein_g":      "proteins_100g",
    "Salt_g":         "salt_100g",
    "Sodium_mg":      "sodium_100g",
    "Potassium_mg":   "potassium_100g",
    "Calcium_mg":     "calcium_100g",
    "Iron_mg":        "iron_100g",
    "Magnesium_mg":   "magnesium_100g",
    "Zinc_mg":        "zinc_100g",
    "Phosphorus_mg":  "phosphorus_100g",
    "VitaminA_mcg":   "vitamin_a_100g",
    "VitaminC_mg":    "vitamin_c_100g",
    "VitaminD_mcg":   "vitamin_d_100g",
    "VitaminB12_mcg": "vitamin_b12_100g",
    "VitaminB6_mg":   "vitamin_b6_100g",
    "Alcohol_g":      "alcohol_100g",
}

# Hastalik bazi risk aciklamasi: hastalik -> (tetikleyici besin, Turkce mesaj)
_DISEASE_REASON: dict[str, tuple[str, str]] = {
    "Diyabet":          ("Sugar_g",        "seker orani WHO limitlerinin ustunde"),
    "Hipertansiyon":    ("Salt_g",          "tuz/sodyum orani yuksek"),
    "Obezite":          ("Energy_kcal",     "kalori yogunlugu fazla"),
    "KVH":              ("SaturatedFat_g",  "doymus yag orani kritik seviyede"),
    "Hiperlipidemi":    ("SaturatedFat_g",  "doymus yag kolesterol riskini artiriyor"),
    "Bobrek":           ("Protein_g",       "yuksek protein bobrek yukunu artiriyor"),
    "Metabolik_Sendrom":("Sugar_g",         "seker + yag kombinasyonu metabolik risk"),
    "NAFLD":            ("Fat_g",           "yag + seker karaciger yaglenmasi riski"),
    "Malnutrisyon":     ("Protein_g",       "protein ve mikro besin eksikligi"),
    "Mineral_Dengesi":  ("Sodium_mg",       "sodyum/potasyum dengesi bozuk"),
}

_MODEL_FEATURES = [
    "energy_kcal_100g","fat_100g","saturated_fat_100g","trans_fat_100g",
    "cholesterol_100g","carbohydrates_100g","sugars_100g","fiber_100g",
    "proteins_100g","salt_100g","sodium_100g","potassium_100g",
    "calcium_100g","iron_100g","magnesium_100g","zinc_100g",
    "phosphorus_100g","vitamin_a_100g","vitamin_c_100g","vitamin_d_100g",
    "vitamin_b12_100g","vitamin_b6_100g","alcohol_100g",
]


def _norm_to_features(norm: dict) -> dict:
    """normalized_data'yi model input dict'ine donusturur."""
    feat: dict = {}
    for nkey, fname in _NORM_TO_FEAT.items():
        info = norm.get(nkey, {})
        val  = info.get("per_100g") if isinstance(info, dict) else None
        feat[fname] = float(val) if val is not None else 0.0
    return feat


def _run_risk_inference(norm: dict) -> dict[str, float] | None:
    """RAM'deki modeli kullanarak risk skorlarini hesaplar."""
    if _RISK_MODEL is None or _RISK_SCALER is None:
        return None
    try:
        import numpy as np
        feat = _norm_to_features(norm)
        row  = [feat.get(f, 0.0) for f in _MODEL_FEATURES]
        X    = np.array(row, dtype="float32").reshape(1, -1)
        X_s  = _RISK_SCALER.transform(X)
        preds = _RISK_MODEL.predict(X_s)[0]
        diseases = [
            "Diyabet","Hipertansiyon","Obezite","KVH","Hiperlipidemi",
            "Bobrek","Metabolik_Sendrom","NAFLD","Malnutrisyon","Mineral_Dengesi",
        ]
        results = {d: round(float(p), 1) for d, p in zip(diseases, preds)}

        # ── HARD-LOGIC OVERRIDE (Kesin Mantik) ───────────────────────────
        # Eger ML modeli eksik veriden dolayi saparsa, WHO'nun kirmizi cizgileri
        # asildiginda puani zorla %85'e ceker.
        if feat.get("sugars_100g", 0) > 22.5:
            results["Diyabet"] = max(results["Diyabet"], 85.0)
            results["Obezite"] = max(results["Obezite"], 80.0)
        if feat.get("salt_100g", 0) > 1.5:
            results["Hipertansiyon"] = max(results["Hipertansiyon"], 85.0)
            results["KVH"] = max(results["KVH"], 80.0)
        if feat.get("saturated_fat_100g", 0) > 5.0:
            results["Hiperlipidemi"] = max(results["Hiperlipidemi"], 85.0)
            results["KVH"] = max(results["KVH"], 85.0)
        if feat.get("energy_kcal_100g", 0) > 450.0:
            results["Obezite"] = max(results["Obezite"], 85.0)

        return results
    except Exception as e:
        print(f"  [Risk model hatasi: {e}]")
        return None


def _print_risk_report(risk: dict[str, float], norm: dict,
                       serving: float | None) -> None:
    """Risk skorlarini terminal tablosu + akilli oneri olarak yazdirir."""
    W = 68
    print(f"\n{'='*W}")
    print("  SAGLIK RISKI ANALIZI  (100g Baz)")
    print(f"{'='*W}")

    # GLOBAL UYARI NOTU
    print("  [UYARI]: Lutfen tum besin degerlerinin (Kalori, Seker, Tuz, Yag)")
    print("           eksiksiz girildiginden emin olun. Eksik veri girisi,")
    print("           analiz sonuclarinin tibbi hassasiyetini etkileyebilir.")
    print(f"  {'─'*64}\n")

    print(f"  {'HASTALIK':<24} {'RISK':<8} {'DURUM':<10} ACIKLAMA")
    print(f"  {'─'*64}")

    high_risks = []
    for disease, score in risk.items():
        if score < 30:
            label, sym = "DUSUK",  "[v]"
        elif score < 60:
            label, sym = "ORTA",   "[~]"
        else:
            label, sym = "YUKSEK", "[!]"
            high_risks.append((disease, score))

        score_bar = int(score / 5)
        bar = "#" * score_bar + "." * (20 - score_bar)
        print(f"  {disease:<24} {score:>5.1f}%  {sym} {label:<7} {bar}")

    print(f"  {'─'*56}")

    # Akilli oneriler (> 50% riskli hastalıklar)
    warnings_printed = False
    for disease, score in risk.items():
        if score < 50:
            continue
        if not warnings_printed:
            print("\n  AKILLI ONERILER:")
            warnings_printed = True
        trigger_key, reason = _DISEASE_REASON.get(disease, (None, "risk yuksek"))
        # Tetikleyici degeri goster
        val_str = ""
        if trigger_key:
            info = norm.get(trigger_key, {})
            val  = info.get("per_100g") if isinstance(info, dict) else None
            if val is not None:
                unit = info.get("unit", "g") if isinstance(info, dict) else "g"
                val_str = f" ({val}{unit}/100g)"
        print(f"  [{score:.0f}%] {disease}: {reason}{val_str}.")

        # Porsiyon tavsiyesi
        if score >= 60:
            if serving:
                half = serving / 2
                print(f"        --> Bu porsiyonu {half:.0f}g'a indirmeniz onerilir.")
            else:
                print(f"        --> Porsiyon miktarini azaltmaniz onerilir.")

    if not warnings_printed:
        print("\n  Bu urun secilen besinler icin dusuk/orta risk tasimaktadir.")

    print()


# ══════════════════════════════════════════════════════════════════════════════
# ADIM 2 — NORMALİZASYON (per_100g + per_portion)
# ══════════════════════════════════════════════════════════════════════════════

_STANDARD_UNITS: dict[str, str] = {
    "Energy_kcal": "kcal", "Energy_kJ": "kJ",
    "Fat_g": "g",          "SaturatedFat_g": "g",
    "Carbohydrate_g": "g", "Sugar_g": "g",
    "Fiber_g": "g",        "Protein_g": "g",
    "Salt_g": "g",         "Sodium_mg": "mg",
    "Potassium_mg": "mg",  "Calcium_mg": "mg",
}

_VALID_RANGES: dict[str, tuple[float, float]] = {
    "Energy_kcal": (0, 900),    "Energy_kJ": (0, 3765),
    "Fat_g": (0, 100),          "SaturatedFat_g": (0, 100),
    "Carbohydrate_g": (0, 100), "Sugar_g": (0, 100),
    "Fiber_g": (0, 50),         "Protein_g": (0, 100),
    "Salt_g": (0, 10),          "Sodium_mg": (0, 4000),
}


def normalize(
    ocr_data: dict[str, Any],
    serving_g: float | None = None,
) -> dict[str, Any]:
    """
    OCR çıktısını normalize eder.
    Yeni flat format: {"per_100g": 6.9, "per_portion": 1.5, "unit": "g", "confidence": 0.89}
    """
    out: dict[str, Any] = {}

    for key, info in ocr_data.items():
        if key == "Serving_g":
            continue   # porsiyon metasini normalize'a taşıma

        # Yeni flat format
        v100 = info.get("per_100g")
        unit = info.get("unit", "") or ""
        conf = info.get("confidence", 0.0)

        # Eski format uyumlulugu (value field)
        if v100 is None:
            v100 = info.get("value")
        if v100 is None:
            continue

        if not unit and key in _STANDARD_UNITS:
            unit = _STANDARD_UNITS[key]

        if key in _VALID_RANGES:
            lo, hi = _VALID_RANGES[key]
            if not (lo <= v100 <= hi):
                continue

        entry: dict[str, Any] = {
            "per_100g":   v100,
            "unit":       unit,
            "confidence": round(conf, 4),
        }
        if info.get("source"):
            entry["source"] = info["source"]
        if info.get("ratio_ok") is not None:
            entry["ratio_ok"] = info["ratio_ok"]
        if info.get("_corrected"):
            entry["_corrected"] = info["_corrected"]

        # per_portion: OCR'dan gelen veya serving_g ile hesaplanan
        vpor = info.get("per_portion")
        if vpor is not None:
            # per_portion zaten sayisal deger (flat format)
            if isinstance(vpor, (int, float)):
                entry["per_portion"] = vpor
            elif isinstance(vpor, dict):
                entry["per_portion"] = vpor.get("value")
        elif serving_g is not None:
            entry["per_portion"] = round(v100 * serving_g / 100, 2)
            entry["per_portion_src"] = f"hesaplama ({serving_g}g)"

        out[key] = entry

    return out


# ══════════════════════════════════════════════════════════════════════════════
# ADIM 3 — RİSK DEĞERLENDİRMESİ
# ══════════════════════════════════════════════════════════════════════════════

def risk_assessment(
    normalized: dict[str, Any],
    serving_g: float | None,
) -> list[str]:
    """
    Her besin için 100g ve porsiyon bazlı risk değerlendirmesi yapar.
    Sadece ilginç (orta/yüksek) risk mesajlarını döndürür.
    """
    messages: list[str] = []

    for key, info in normalized.items():
        if key not in _RISK_THRESHOLDS:
            continue
        label = _LABELS.get(key, key)
        v100  = info.get("per_100g", {}).get("value")
        unit  = info.get("per_100g", {}).get("unit", "")
        if v100 is None:
            continue

        r100 = _risk_label(v100, key)
        emoji = _RISK_EMOJI.get(r100, "")

        if serving_g and "per_portion" in info:
            vpor  = info["per_portion"]["value"]
            rpor  = _risk_label(vpor, key)
            epor  = _RISK_EMOJI.get(rpor, "")

            if r100 != rpor:
                # Risk seviyeleri farklıysa karşılaştırmalı mesaj ver
                messages.append(
                    f"{emoji} {label}: 100g'da {r100} risk ({v100}{unit}) — "
                    f"ancak {serving_g:.0f}g (1 porsiyon) tüketiminde "
                    f"{epor} {rpor} risk ({vpor}{unit})."
                )
            elif r100 in ("yüksek", "orta"):
                messages.append(
                    f"{emoji} {label}: 100g'da ve porsiyon başına {r100} risk "
                    f"(100g={v100}{unit} | porsiyon={vpor}{unit})."
                )
        else:
            if r100 in ("yüksek", "orta"):
                messages.append(
                    f"{emoji} {label}: 100g'da {r100} risk ({v100}{unit})."
                )

    return messages


# ══════════════════════════════════════════════════════════════════════════════
# DÜZENLEME & ONAY ŞEMASI  (Edit & Confirm)
# ══════════════════════════════════════════════════════════════════════════════

# Standart beklenen besin alanları  (key, Türkçe label, birim)
_EXPECTED_NUTRIENTS: list[tuple[str, str, str]] = [
    ("Energy_kcal",    "Enerji",        "kcal"),
    ("Energy_kJ",      "Enerji (kJ)",   "kJ"),
    ("Fat_g",          "Yağ",           "g"),
    ("SaturatedFat_g", "Doymuş Yağ",   "g"),
    ("Carbohydrate_g", "Karbonhidrat",  "g"),
    ("Sugar_g",        "Şeker",         "g"),
    ("Fiber_g",        "Lif",           "g"),
    ("Protein_g",      "Protein",       "g"),
    ("Salt_g",         "Tuz",           "g"),
    ("Sodium_mg",      "Sodyum",        "mg"),
    ("Potassium_mg",   "Potasyum",      "mg"),
    ("Calcium_mg",     "Kalsiyum",      "mg"),
]


def build_edit_schema(
    normalized: dict[str, Any],
    serving_g: float | None = None,
    image_name: str = "",
) -> dict[str, Any]:
    """
    OCR çıktısından kullanıcı düzenleme/onay şeması oluşturur.

    Her besin için:
      - Bulundu  → OCR değerleri, needs_input: false
      - Bulunamadı → null değer, needs_input: true  ('Elle girmek ister misiniz?' bayrağı)
    extra_nutrients: kullanıcının tablo dışı mineral/vitamin ekleyebileceği liste.
    """
    fields: dict[str, Any] = {}

    for key, label, unit in _EXPECTED_NUTRIENTS:
        if key in normalized:
            info = normalized[key]
            fields[key] = {
                "label":           label,
                "per_100g":        info.get("per_100g"),
                "per_portion":     info.get("per_portion"),
                "unit":            info.get("unit") or unit,
                "confidence":      round(info.get("confidence", 0.0), 4),
                "needs_input":     False,
                "manual_override": False,
                "source":          info.get("source", "ocr"),
                "ratio_ok":        info.get("ratio_ok"),
            }
        else:
            fields[key] = {
                "label":           label,
                "per_100g":        None,
                "per_portion":     None,
                "unit":            unit,
                "confidence":      0.0,
                "needs_input":     True,
                "manual_override": False,
                "source":          "missing",
                "ratio_ok":        None,
            }

    missing_cnt = sum(1 for f in fields.values() if f["needs_input"])
    found_cnt   = len(fields) - missing_cnt

    return {
        "schema_version":  "1.0",
        "image":           image_name,
        "serving_g":       serving_g,
        "fields":          fields,
        "extra_nutrients": [],
        "meta": {
            "ocr_found_count":    found_cnt,
            "needs_input_count":  missing_cnt,
            "total_fields":       len(fields),
        },
    }


_LOG_PATH = PROJECT_ROOT / "corrections.log"


def log_correction(
    image_name: str,
    nutrient_key: str,
    ai_value: float | None,
    user_value: float | None,
    log_path: Path = _LOG_PATH,
) -> None:
    """
    Kullanıcı, AI'nın bulduğu değeri değiştirdiğinde kaydeder.
    Format: timestamp | image | key | ai=X | user=Y | delta=Z
    """
    from datetime import datetime, timezone
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    if ai_value is not None and ai_value != 0 and user_value is not None:
        delta     = user_value - ai_value
        delta_pct = (delta / ai_value) * 100
        delta_str = f"delta={delta:+.2f} ({delta_pct:+.1f}%)"
    else:
        delta_str = f"delta=N/A (ai={ai_value} → user={user_value})"
    line = f"{ts} | {image_name} | {nutrient_key} | ai={ai_value} | user={user_value} | {delta_str}\n"
    with open(log_path, "a", encoding="utf-8") as f:
        f.write(line)


def apply_override(
    edit_schema: dict[str, Any],
    overrides: dict[str, Any],
    log_path: Path = _LOG_PATH,
) -> dict[str, Any]:
    """
    Kullanıcı düzeltmelerini edit_schema'ya uygular ve log'a yazar.

    overrides formatı:
    {
      "fields": {
        "Protein_g": {"per_100g": 6.0, "per_portion": 1.3}
      },
      "extra_nutrients": [
        {"name": "Demir", "key": "Iron_mg", "per_100g": 2.5, "unit": "mg"}
      ]
    }
    """
    image  = edit_schema.get("image", "?")
    schema = dict(edit_schema)
    schema["fields"] = {k: dict(v) for k, v in edit_schema["fields"].items()}

    for key, user_data in overrides.get("fields", {}).items():
        if key not in schema["fields"]:
            continue
        field = schema["fields"][key]
        changed = False
        for sub in ("per_100g", "per_portion"):
            if sub in user_data:
                ai_val, user_val = field.get(sub), user_data[sub]
                if ai_val != user_val:
                    log_correction(image, f"{key}.{sub}", ai_val, user_val, log_path)
                    field[sub]              = user_val
                    field["manual_override"] = True
                    field["source"]         = "user"
                    changed = True
        if changed and field.get("per_100g") is not None:
            field["needs_input"] = False

    # Tablo dışı ek besinler
    for item in overrides.get("extra_nutrients", []):
        schema["extra_nutrients"].append({
            "name":            item.get("name", "?"),
            "key":             item.get("key", "custom"),
            "per_100g":        item.get("per_100g"),
            "per_portion":     item.get("per_portion"),
            "unit":            item.get("unit", "g"),
            "manual_override": True,
            "source":          "user",
        })

    schema["meta"]["needs_input_count"] = sum(
        1 for f in schema["fields"].values() if f["needs_input"]
    )
    schema["meta"]["override_count"] = sum(
        1 for f in schema["fields"].values() if f.get("manual_override")
    )
    return schema


# ══════════════════════════════════════════════════════════════════════════════
# PIPELINE
# ══════════════════════════════════════════════════════════════════════════════

def run(image_path: str) -> dict[str, Any]:
    result: dict[str, Any] = {
        "image":           Path(image_path).name,
        "status":          "unknown",
        "quality_report":  {},
        "serving_g":       None,
        "normalized_data": {},
        "edit_schema":     {},
    }

    # 1. Kalite
    qr = image_quality_check(image_path)
    result["quality_report"] = qr
    if not qr["passed"]:
        result["status"] = "quality_failed"
        # return result (Kaldırıldı: Kalite düşük olsa bile OCR denenecek)

    # 2. OCR
    ocr = analyze_image(image_path)
    if ocr.get("status") != "ok" and result["status"] == "unknown":
        result["status"] = "ocr_failed"
        result["ocr_error"] = ocr.get("message", "Bilinmeyen OCR hatası.")

    serving_g = ocr.get("serving_g") if isinstance(ocr, dict) else None
    result["serving_g"] = serving_g

    # 3. Normalize (100g + porsiyon)
    norm = normalize(ocr.get("data", {}), serving_g=serving_g) if isinstance(ocr, dict) else {}
    if not norm and result["status"] == "unknown":
        result["status"] = "no_nutrients"

    result["normalized_data"] = norm
    result["edit_schema"]     = build_edit_schema(
        norm, serving_g=serving_g, image_name=Path(image_path).name
    )
    if result["status"] == "unknown":
        result["status"] = "ok"
    return result




# ==============================================================================
# TERMINAL & INTERAKTIF DUZENLEME  v4.0 — Fuzzy + Index + Command System
# ==============================================================================

def _fmt(v):
    if v is None:
        return "—"
    try:
        f = float(v)
        s = f"{f:.2f}".rstrip("0").rstrip(".")
        return s
    except (TypeError, ValueError):
        return str(v)


# ── Genis Fuzzy Sozluk (TR/EN/hatali yazim -> standart anahtar) ───────────────
_INPUT_ALIAS = {
    # Enerji
    "enerji":"Energy_kcal","energy":"Energy_kcal","kalori":"Energy_kcal",
    "kcal":"Energy_kcal","cal":"Energy_kcal","energi":"Energy_kcal",
    "kalorisi":"Energy_kcal","energy_kcal":"Energy_kcal","enerji_kcal":"Energy_kcal",
    "kj":"Energy_kJ","kilojoule":"Energy_kJ","kilo_joule":"Energy_kJ",
    # Yag
    "yag":"Fat_g","fat":"Fat_g","yaglar":"Fat_g","total_fat":"Fat_g",
    "toplam_yag":"Fat_g","fats":"Fat_g","yagi":"Fat_g","ya":"Fat_g",
    # Doymus Yag
    "doymus":"SaturatedFat_g","doymusyag":"SaturatedFat_g","doymus_yag":"SaturatedFat_g",
    "saturated":"SaturatedFat_g","saturated_fat":"SaturatedFat_g","saturatedfat":"SaturatedFat_g",
    "doymus_yaglar":"SaturatedFat_g","doymussyag":"SaturatedFat_g","saturates":"SaturatedFat_g",
    "doymusfat":"SaturatedFat_g","sat_fat":"SaturatedFat_g",
    # Trans Yag
    "trans":"TransFat_g","trans_yag":"TransFat_g","trans_fat":"TransFat_g",
    "transfat":"TransFat_g","transyag":"TransFat_g",
    # Karbonhidrat
    "karb":"Carbohydrate_g","karbonhidrat":"Carbohydrate_g","karbonhidratlar":"Carbohydrate_g",
    "carb":"Carbohydrate_g","carbohydrate":"Carbohydrate_g","carbohydrates":"Carbohydrate_g",
    "toplam_karb":"Carbohydrate_g","karbohidrat":"Carbohydrate_g","carbs":"Carbohydrate_g",
    # Seker
    "seker":"Sugar_g","sekerler":"Sugar_g","sugar":"Sugar_g","sugars":"Sugar_g",
    "seker_g":"Sugar_g","sugars_100g":"Sugar_g","tatli":"Sugar_g","sekeri":"Sugar_g",
    "total_sugar":"Sugar_g","toplam_seker":"Sugar_g",
    # Lif
    "lif":"Fiber_g","fiber":"Fiber_g","fibre":"Fiber_g","dietary_fiber":"Fiber_g",
    "dietary_fibre":"Fiber_g","diyet_lif":"Fiber_g","lifler":"Fiber_g",
    # Protein
    "protein":"Protein_g","proteinler":"Protein_g","proteins":"Protein_g",
    "protein_g":"Protein_g","proteini":"Protein_g",
    # Tuz
    "tuz":"Salt_g","salt":"Salt_g","tuzu":"Salt_g","sodyumklorur":"Salt_g",
    "sodium_chloride":"Salt_g",
    # Sodyum
    "sodyum":"Sodium_mg","sodium":"Sodium_mg","na":"Sodium_mg","sodyum_mg":"Sodium_mg",
    # Potasyum
    "potasyum":"Potassium_mg","potassium":"Potassium_mg","k":"Potassium_mg",
    # Kalsiyum
    "kalsiyum":"Calcium_mg","calcium":"Calcium_mg","ca":"Calcium_mg",
    # Magnezyum
    "magnezyum":"Magnesium_mg","magnesium":"Magnesium_mg","mg":"Magnesium_mg",
    # Demir
    "demir":"Iron_mg","iron":"Iron_mg","fe":"Iron_mg",
    # Kolesterol
    "kolesterol":"Cholesterol_mg","cholesterol":"Cholesterol_mg","kolestrol":"Cholesterol_mg",
    # Vitamin C
    "vitamin_c":"VitaminC_mg","vitaminc":"VitaminC_mg","c_vitamini":"VitaminC_mg",
    "askorbik":"VitaminC_mg","ascorbic":"VitaminC_mg",
    # Vitamin D
    "vitamin_d":"VitaminD_mcg","vitamind":"VitaminD_mcg","d_vitamini":"VitaminD_mcg",
    # Vitamin B12
    "b12":"VitaminB12_mcg","vitamin_b12":"VitaminB12_mcg","b12_vitamini":"VitaminB12_mcg",
    # Vitamin A
    "vitamin_a":"VitaminA_mcg","vitamina":"VitaminA_mcg","a_vitamini":"VitaminA_mcg",
}


# Unicode codepoint tablosu — PowerShell heredoc encoding sorununu asarak TR char donusumu
_TR_TABLE = str.maketrans({
    0x0131: "i", 0x0130: "i",   # i I
    0x015f: "s", 0x015e: "s",   # s S
    0x011f: "g", 0x011e: "g",   # g G
    0x00fc: "u", 0x00dc: "u",   # u U
    0x00f6: "o", 0x00d6: "o",   # o O
    0x00e7: "c", 0x00c7: "c",   # c C
    ord(" "): "_", ord("-"): "_",
})


def _normalize_key(raw: str) -> str:
    """TR ozel karakterleri ASCII'ye indirgeyip kucuk harf yapar."""
    return raw.lower().translate(_TR_TABLE).strip()


def _resolve_label(raw: str):
    """Fuzzy sozlukten standart anahtar bul; bulunamazsa None."""
    return _INPUT_ALIAS.get(_normalize_key(raw))


def _detect_type(val_str: str):
    """(deger, tip) -> numeric veya text"""
    try:
        return float(val_str.replace(",",".")), "numeric"
    except ValueError:
        return val_str, "text"


# ── Indeksli Birlesik Tablo ───────────────────────────────────────────────────

def _build_index(norm: dict, overrides: dict, extra_data: dict) -> list:
    """
    Tum verileri (OCR + extra) sirali bir liste olarak dondurur.
    Her eleman: {"idx":N, "type":"ocr"/"extra", "key":..., "label":...,
                  "v100":..., "vpor":..., "unit":..., "conf":...,
                  "tip":...}
    """
    entries = []
    idx = 1
    for key, info in norm.items():
        if key == "Energy_kcal" and "Energy_kJ" in norm:
            continue
        ovr   = overrides.get(key, {})
        v100  = ovr.get("per_100g",  info.get("per_100g"))
        vpor  = ovr.get("per_portion", info.get("per_portion"))
        unit  = info.get("unit","")
        conf  = info.get("confidence", 0.0)
        label = _LABELS.get(key, key)
        entries.append({
            "idx":   idx, "type": "ocr", "key": key,
            "label": label, "v100": v100, "vpor": vpor,
            "unit":  unit,  "conf": conf, "tip": "numeric",
            "modified": key in overrides,
        })
        idx += 1
    for name, info in extra_data.items():
        entries.append({
            "idx":   idx, "type": "extra", "key": name,
            "label": name, "v100": info.get("per_100g","—"),
            "vpor":  info.get("per_portion","—"),
            "unit":  "", "conf": 1.0,
            "tip":   info.get("type","text"),
            "modified": False,
        })
        idx += 1
    return entries


def _draw_indexed_table(entries: list, serving: float | None) -> None:
    """Indeksli birlesik tabloyu yazdir."""
    CN, CI, C1, CT = 20, 3, 11, 7
    W = CI + CN + C1 + CT + 4
    SEP = "─"*W

    # Baslik
    hdr = f"{'#':>{CI}} {'BESIN / PARAMETRE':<{CN}}{'100g':>{C1}}   {'TIP/GVN':^{CT}}"
    print(f"\n  {SEP}\n  {hdr}\n  {SEP}")

    ocr_shown, extra_shown = False, False
    for e in entries:
        if e["type"] == "ocr" and not ocr_shown:
            print(f"  {'─'*CI} OCR SONUCLARI {'─'*(W-CI-16)}")
            ocr_shown = True
        if e["type"] == "extra" and not extra_shown:
            print(f"  {'─'*CI} EK PARAMETRELER {'─'*(W-CI-18)}")
            extra_shown = True

        flag  = "*" if e["modified"] else " "
        v100s = f"{_fmt(e['v100'])} {e['unit']}".strip()
        tip   = f"{e['conf']*100:.0f}%" if e["type"]=="ocr" else e["tip"][:7]

        row = f"{e['idx']:>{CI}}{flag} {e['label']:<{CN}}{v100s:>{C1}}   {tip:^{CT}}"
        print(f"  {row}")

    print(f"  {SEP}")
    if any(e["modified"] for e in entries):
        print("  (* degistirildi)")


def _show_help() -> None:
    print("""
  KOMUT KILAVUZU
  ─────────────────────────────────────────────────────────
  Seker:43:9       Seker degerini 100g=43, porsiyon=9 yap
  Seker:43         Sadece 100g degerini guncelle
  Koku:UYGUN:UYGUN Yeni parametre ekle (herhangi isim)
  sil 2            2 numarali satiri sil
  sil Seker        Seker satirini sil
  tamam            Verileri onayla ve kaydet
  ?                Bu yardim ekranini goster
  ─────────────────────────────────────────────────────────""")


def _ask_portion() -> float | None:
    """OCR porsiyon okuyamadiysa kullaniciya sor."""
    print("\n  Dikkat: OCR porsiyon miktarini okuyamadi.")
    try:
        raw = input("  Bu paket kac gram/ml? (bilmiyorum icin Enter): ").strip()
    except (EOFError, KeyboardInterrupt):
        return None
    if not raw:
        return None
    val, tip = _detect_type(raw)
    if tip == "numeric" and val > 0:
        print(f"  Porsiyon: {val} g/ml olarak kaydedildi.")
        return float(val)
    print("  Gecersiz giris, porsiyon bos kalacak.")
    return None


def _interactive_session(result, output_path, schema_path):
    status  = result.get("status")
    qr      = result.get("quality_report", {})
    norm    = result.get("normalized_data", {})
    image   = result.get("image", "?")
    serving = result.get("serving_g")

    # Baslik
    print(f"\n  VitaCheck v4.0  |  {image}")

    # Hata durumları (Artık işlemi kesmiyor, kullanıcı manuel girebilsin diye tabloyu açıyor)
    if status == "quality_failed":
        reason = qr.get("failure_reason","")
        print(f"\n  [UYARI]: {_FAIL_MSGS.get(reason,'Görsel kalitesi düşük.')} (Manuel giriş yapabilirsiniz)")
    elif status == "ocr_failed":
        print(f"\n  [UYARI] OCR: {result.get('ocr_error','')} (Manuel giriş yapabilirsiniz)")
    elif status == "no_nutrients":
        print("\n  [UYARI]: Besin tablosu algılanamadı. (Manuel giriş yapabilirsiniz)")
    
    if not norm:
        print("\n  [BİLGİ]: OCR hiçbir değer bulamadı. Boş tablo açılıyor, değerleri kendiniz girebilirsiniz.")

    # Porsiyon degeri basta gosterilmeyecek, 'tamam' asamasinda sorulacak.
    # serving = result.get("serving_g") kodu yukarida kalabilir.

    ocr_overrides: dict = {}
    extra_data:    dict = {}

    HINT = (
        "\n  Listede olmayan bir parametre icin: [Isim:Deger:Porsiyon]"
        "\n  Silmek icin: sil 2  veya  sil Seker     Yardim: ?"
        "\n  Onaylamak icin: tamam"
        "\n\n  > "
    )

    while True:
        entries = _build_index(norm, ocr_overrides, extra_data)
        _draw_indexed_table(entries, serving)

        # Eksik alanlar
        es = result.get("edit_schema", {})
        missing = [f["label"] for f in es.get("fields", {}).values()
                   if f.get("needs_input")]
        if missing:
            print(f"\n  Eksik: {', '.join(missing)}")

        try:
            inp = input(HINT).strip()
        except (EOFError, KeyboardInterrupt):
            inp = "tamam"

        if not inp:
            print("  Onaylamak icin 'tamam' yazin.")
            continue

        # ── Komut: yardim ───────────────────────────────────────────────
        if inp in ("?", "yardim", "help"):
            _show_help()
            continue

        # ── Komut: tamam ────────────────────────────────────────────────
        if inp.lower() in ("tamam", "onayla", "ok", "kaydet", "done"):
            print("\n" + "-"*30)
            porsiyon_input = input("  Analiz edilecek miktar (gram)? [Varsayılan: 100g]: ").strip()
            try:
                porsiyon_gram = float(porsiyon_input) if porsiyon_input else 100.0
            except ValueError:
                porsiyon_gram = 100.0
            serving = porsiyon_gram
            carpan = porsiyon_gram / 100.0
            break

        # ── Komut: sil ──────────────────────────────────────────────────
        if inp.lower().startswith("sil "):
            arg = inp[4:].strip()
            deleted = False
            # Indeks ile sil
            if arg.isdigit():
                target_idx = int(arg)
                for e in entries:
                    if e["idx"] == target_idx:
                        if e["type"] == "ocr":
                            ocr_overrides.pop(e["key"], None)
                            print(f"  Silindi: #{target_idx} {e['label']} (duzeltme iptal)")
                        else:
                            extra_data.pop(e["key"], None)
                            print(f"  Silindi: #{target_idx} {e['label']}")
                        deleted = True
                        break
            else:
                # Isim ile sil
                arg_norm = _normalize_key(arg)
                std_key  = _resolve_label(arg)
                for e in entries:
                    if (_normalize_key(e["label"]) == arg_norm or
                            e["key"] == arg or e["key"] == std_key):
                        if e["type"] == "ocr":
                            ocr_overrides.pop(e["key"], None)
                            print(f"  Silindi: {e['label']} (duzeltme iptal)")
                        else:
                            extra_data.pop(e["key"], None)
                            print(f"  Silindi: {e['label']}")
                        deleted = True
                        break
            if not deleted:
                print(f"  Bulunamadi: '{arg}'. Numarayi veya tam adi yazin.")
            continue

        # ── Ekleme / Duzeltme / Porsiyon: Ad:v100:vp ───────────────────
        parts    = [p.strip() for p in inp.split(":")]
        name_raw = parts[0]
        val100_s = parts[1] if len(parts) > 1 else ""
        vpor_s   = parts[2] if len(parts) > 2 else ""
        name_norm = _normalize_key(name_raw)

        # ── Porsiyon komutu: porsiyon:21 -> global_portion guncelle ─────
        if name_norm in ("porsiyon", "portion", "serving", "servis", "paket", "net_agirlik"):
            try:
                new_serving = float(val100_s) if val100_s else None
            except ValueError:
                print("  Sayi hatali. Ornek: porsiyon:21"); continue
            if new_serving and new_serving > 0:
                serving = new_serving
                result["serving_g"] = serving
                print(f"  >> Porsiyon guncellendi: {serving:.0f} g/ml")
            else:
                print("  Gecersiz porsiyon degeri.")
            continue

        std_key = _resolve_label(name_raw)

        if std_key:
            # Bilinen besin (norm'da olsun ya da olmasin): ekle/guncelle
            try:
                v100 = float(val100_s) if val100_s else None
                vpor = float(vpor_s)   if vpor_s  else None
            except ValueError:
                print("  Sayi hatali. Ornek: Seker:43:9"); continue
            if v100 is not None:
                log_correction(image, f"{std_key}.per_100g",
                               norm.get(std_key, {}).get("per_100g"), v100)
            if vpor is not None:
                log_correction(image, f"{std_key}.per_portion",
                               norm.get(std_key, {}).get("per_portion"), vpor)
            # norm'da yoksa ekle (eksik besin girisi)
            if std_key not in norm:
                unit = "mg" if std_key.endswith("_mg") else "g"
                norm[std_key] = {"per_100g": v100, "unit": unit,
                                 "confidence": 1.0, "source": "user"}
            ocr_overrides.setdefault(std_key, {})
            if v100 is not None: ocr_overrides[std_key]["per_100g"]   = v100
            if vpor is not None: ocr_overrides[std_key]["per_portion"] = vpor
            label = _LABELS.get(std_key, std_key)
            print(f"  >> {label}: 100g={v100}  porsiyon={vpor}")
        else:
            # Tamamen bilinmeyen -> extra_data (dinamik cevirim yok)
            v100_val, v100_type = _detect_type(val100_s) if val100_s else ("—", "text")
            vpor_val, _         = _detect_type(vpor_s)   if vpor_s   else (v100_val, "text")
            final_type = "numeric" if v100_type == "numeric" else "text"
            extra_data[name_raw] = {
                "per_100g": v100_val, "per_portion": vpor_val,
                "type": final_type, "source": "user",
            }
            print(f"  >> '{name_raw}' eklendi [{final_type}]: 100g={v100_val}  por={vpor_val}")

    # ── FINAL ONAY TABLOSU & PORSİYON HESABI ──────────────────────────────────
    for k, vals in ocr_overrides.items():
        if k in norm: norm[k].update(vals)

    # Düzeltmeler eklendikten SONRA porsiyon hesaplamasını yapıyoruz
    porsiyon_bazli_veriler = {}
    for k, v in norm.items():
        if isinstance(v, dict) and "per_100g" in v and v["per_100g"] is not None:
            # Kullanıcının eklediği 100g değerini çarpıyoruz
            scaled = round(float(v["per_100g"]) * carpan, 2)
            porsiyon_bazli_veriler[k] = scaled
            v["per_100g"] = scaled

    # Sadece ornek göstermek icin mevcut bir anahtari alalim
    print(f"\n  ✅ Başarılı: {porsiyon_gram}g için değerler hesaplandı.")
    if norm:
        ornek_key = list(norm.keys())[0]
        eski_deger = round(porsiyon_bazli_veriler[ornek_key] / carpan, 2) if carpan else 0
        print(f"  👉 Örn: {ornek_key} (100g): {eski_deger}g -> Toplam ({porsiyon_gram}g): {porsiyon_bazli_veriler[ornek_key]}g")

    final_entries = _build_index(norm, {}, extra_data)
    print("\n" + "="*62)
    print("  FINAL ONAY TABLOSU")
    print("="*62)
    _draw_indexed_table(final_entries, serving)

    ov_n = len(ocr_overrides)
    ex_n = len(extra_data)
    print(f"\n  OCR: {len(norm)}  |  Duzeltme: {ov_n}  |  Ek parametre: {ex_n}")
    if ov_n:
        print(f"  Log -> {_LOG_PATH}")

    # ── RISK ANALIZI (tamam'dan hemen sonra, JSON'dan once) ──────────────────
    risk_scores = _run_risk_inference(norm)
    if risk_scores:
        _print_risk_report(risk_scores, norm, serving)
    elif not (_MODEL_PATH.exists()):
        print("\n  [Risk modeli bulunamadi. 'python train_model.py' ile egitebilirsiniz.]")

    # ── KAYIT ─────────────────────────────────────────────────────────────────
    save_path = output_path or "final_result.json"
    final = {
        "image":           image,
        "status":          result["status"],
        "quality_report":  qr,
        "serving_g":       serving,
        "normalized_data": norm,
        "extra_data":      extra_data,
        "meta": {
            "ocr_nutrient_count":    len(norm),
            "user_added_count":      ex_n,
            "manual_override_count": ov_n,
            "schema_version":        "3.0",
            "risk_analysis":         risk_scores or {},
        },
    }
    import os
    with open(save_path, "w", encoding="utf-8") as _f:
        json.dump(final, _f, indent=4, ensure_ascii=False)
        _f.flush()
        os.fsync(_f.fileno())
    print(f"\n  Kaydedildi -> {save_path}\n")

    if schema_path:
        sc = build_edit_schema(norm, serving_g=serving, image_name=image)
        Path(schema_path).write_text(
            json.dumps(sc, ensure_ascii=False, indent=2), encoding="utf-8"
        )
        print(f"  Sema -> {schema_path}")

    # --- DOKTOR ANALİZİ BAŞLATMA ---
    print("\n" + "-"*50)
    print("  🩺 KLİNİK DOKTOR TAVSİYESİ")
    try:
        # 1. Kullanıcıdan hızlıca ürün türünü ve profil bilgilerini alıyoruz
        urun_turu = input("  Bu ürünün kategorisi nedir? (Örn: Alkol, Enerji İçeceği, Sos, Tatlı, Süt Ürünü): ").strip().lower() or "bilinmiyor"
        yas = input("  Yaş (Örn: 20): ") or "20"
        boy = input("  Boy cm (Örn: 180): ") or "180"
        kilo = input("  Kilo kg (Örn: 80): ") or "80"
        profil_str = f"{yas} Yaş, {boy}cm, {kilo}kg"

        # 2. Servisi senin anahtarınla başlatıyoruz
        doctor = DoctorService(GEMINI_API_KEY)
        
        # DİKKAT: 'ocr_verileri' ve 'ml_sonuclari' senin ana kodundaki 
        # değişkenlerin isimleri neyse (örn: final_json_data) ona göre güncelle!
        porsiyon_bazli_veriler_str = json.dumps(porsiyon_bazli_veriler if 'porsiyon_bazli_veriler' in locals() else norm, ensure_ascii=False)
        ml_sonuclari = json.dumps(risk_scores or {}, ensure_ascii=False)
        reçete = doctor.tavsiye_uret(
            porsiyon_gram=porsiyon_gram if 'porsiyon_gram' in locals() else 100.0, 
            porsiyon_bazli_veriler=porsiyon_bazli_veriler_str, 
            ml_scores=ml_sonuclari, 
            user_profile=profil_str,
            urun_turu=urun_turu
        )

        print("\n" + "="*60)
        print("  🩺 VİTA-CHECK ANALİZ RAPORU")
        for line in reçete.split('\n'):
            print(f"  {line}")
        print("="*60)
        print()

    except Exception as e:
        print(f"  Doktor katmanında bir hata oluştu: {e}")



# ==============================================================================
# CLI
# ==============================================================================

def main():
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(
        description="VitaCheck Core Engine v4.0 — Smart Input Manager")
    parser.add_argument("image")
    parser.add_argument("-o","--output", metavar="DOSYA", default=None)
    parser.add_argument("--schema",      metavar="DOSYA", default=None)
    args = parser.parse_args()
    result = run(args.image)
    _interactive_session(result, args.output, args.schema)


if __name__ == "__main__":
    main()
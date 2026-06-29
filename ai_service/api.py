"""
VitaCheck — FastAPI Servisi  v1.0
==================================
POST /analyze  →  OCR + ML Risk + Doktor Tavsiyesi

Çalıştırmak için (ai_service/ dizininden):
    uvicorn api:app --host 0.0.0.0 --port 8001 --reload
"""

from __future__ import annotations

import json
import os
import tempfile
from pathlib import Path
from typing import Any

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# ── Proje kök dizini & credentials ───────────────────────────────────────────
_ROOT = Path(__file__).resolve().parent
_CREDENTIALS = _ROOT / "credentials.json"
if _CREDENTIALS.exists():
    os.environ.setdefault("GOOGLE_APPLICATION_CREDENTIALS", str(_CREDENTIALS))

# ── Paket importları (ai_service paketi) ─────────────────────────────────────
from ai_service.vision_ocr import analyze_image          # noqa: E402
from ai_service.doctor_service import DoctorService      # noqa: E402

# ── Gemini API Key ────────────────────────────────────────────────────────────
GEMINI_API_KEY = "AIzaSyANae8yOC5y1Y3d4djk0iUPsFIOSv9x6fU"

# ── ML Modeli — Lazy Load ─────────────────────────────────────────────────────
_RISK_MODEL  = None
_RISK_SCALER = None
_MODEL_PATH  = _ROOT / "models" / "health_risk_model.joblib"
_SCALER_PATH = _ROOT / "models" / "scaler.joblib"


def _load_risk_model() -> bool:
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


_load_risk_model()

# ── Normalizasyon sabitleri (main.py'den birebir alındı) ──────────────────────
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

# ML model feature haritası
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

_MODEL_FEATURES = [
    "energy_kcal_100g", "fat_100g", "saturated_fat_100g", "trans_fat_100g",
    "cholesterol_100g", "carbohydrates_100g", "sugars_100g", "fiber_100g",
    "proteins_100g", "salt_100g", "sodium_100g", "potassium_100g",
    "calcium_100g", "iron_100g", "magnesium_100g", "zinc_100g",
    "phosphorus_100g", "vitamin_a_100g", "vitamin_c_100g", "vitamin_d_100g",
    "vitamin_b12_100g", "vitamin_b6_100g", "alcohol_100g",
]

_DISEASE_LABELS = [
    "Diyabet", "Hipertansiyon", "Obezite", "KVH", "Hiperlipidemi",
    "Bobrek", "Metabolik_Sendrom", "NAFLD", "Malnutrisyon", "Mineral_Dengesi",
]

_DISEASE_MAPPING = {
    "Diyabet": "Diyabet",
    "Obezite": "Obezite",
    "Hipertansiyon": "Hipertansiyon",
    "Hiperlipidemi": "Hiperlipidemi",
    "Kardiyovasküler Hastalık Riski": "KVH",
    "Böbrek Hastalığı Riski": "Bobrek",
    "Metabolik Sendrom Riski": "Metabolik_Sendrom",
    "Karaciğer Yağlanması Riski": "NAFLD",
    "Protein/Enerji Yetersizliği Riski": "Malnutrisyon",
    "Mineral Dengesizliği Riski": "Mineral_Dengesi",
}


# ── Yardımcı fonksiyonlar ─────────────────────────────────────────────────────

def _normalize(ocr_data: dict[str, Any], serving_g: float | None) -> dict[str, Any]:
    """OCR çıktısını 100g + porsiyon bazında normalize eder."""
    out: dict[str, Any] = {}
    for key, info in ocr_data.items():
        if key == "Serving_g":
            continue
        v100 = info.get("per_100g") or info.get("value")
        if v100 is None:
            continue
        unit = info.get("unit", "") or _STANDARD_UNITS.get(key, "")
        conf = info.get("confidence", 0.0)

        if key in _VALID_RANGES:
            lo, hi = _VALID_RANGES[key]
            if not (lo <= v100 <= hi):
                continue

        entry: dict[str, Any] = {
            "per_100g":   v100,
            "unit":       unit,
            "confidence": round(conf, 4),
        }

        # per_portion: önce OCR'dan, yoksa serving_g ile hesapla
        vpor = info.get("per_portion")
        if isinstance(vpor, (int, float)):
            entry["per_portion"] = vpor
        elif serving_g is not None:
            entry["per_portion"] = round(v100 * serving_g / 100, 2)

        out[key] = entry
        
    # Eğer sadece kJ bulunduysa kcal'ye çevir ve ekle
    if "Energy_kJ" in out and "Energy_kcal" not in out:
        kj_info = out["Energy_kJ"]
        kj_100 = kj_info.get("per_100g")
        kj_por = kj_info.get("per_portion")
        
        kcal_entry = {
            "per_100g": round(kj_100 / 4.184, 1) if kj_100 else 0,
            "unit": "kcal",
            "confidence": kj_info.get("confidence", 0.0),
        }
        if kj_por is not None:
            kcal_entry["per_portion"] = round(kj_por / 4.184, 1)
        out["Energy_kcal"] = kcal_entry

    return out


def _scale_to_portion(norm: dict[str, Any], portion_gram: float) -> dict[str, Any]:
    """
    Normalize edilmiş verileri (100g bazlı) istenen porsiyona ölçekler.
    Her besin için porsiyon başına değeri hesaplar ve döndürür.
    """
    carpan = portion_gram / 100.0
    scaled: dict[str, Any] = {}
    for key, info in norm.items():
        v100 = info.get("per_100g")
        if v100 is None:
            continue
        scaled[key] = {
            "per_100g":    v100,
            "per_portion": round(float(v100) * carpan, 2),
            "unit":        info.get("unit", ""),
            "confidence":  info.get("confidence", 0.0),
        }
    return scaled


def _norm_to_features(norm: dict) -> dict:
    feat: dict = {}
    for nkey, fname in _NORM_TO_FEAT.items():
        info = norm.get(nkey, {})
        val  = info.get("per_100g") if isinstance(info, dict) else None
        feat[fname] = float(val) if val is not None else 0.0
    return feat


def _run_risk_inference(norm: dict) -> list[dict] | None:
    """ML modelini kullanarak 10 hastalık risk skorunu hesaplar."""
    if _RISK_MODEL is None or _RISK_SCALER is None:
        return None
    try:
        import numpy as np
        feat = _norm_to_features(norm)
        row  = [feat.get(f, 0.0) for f in _MODEL_FEATURES]
        X    = np.array(row, dtype="float32").reshape(1, -1)
        X_s  = _RISK_SCALER.transform(X)
        preds = _RISK_MODEL.predict(X_s)[0]
        results = {d: round(float(p), 1) for d, p in zip(_DISEASE_LABELS, preds)}

        # Hard-logic override (WHO kırmızı çizgileri)
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

        # C#'a gönderilmek üzere liste formatına çevir
        return [
            {"disease": disease, "risk_score": score, "level": _risk_level(score)}
            for disease, score in results.items()
        ]
    except Exception as e:
        print(f"[Risk model hatası: {e}]")
        return None


def _risk_level(score: float) -> str:
    if score < 30:
        return "düşük"
    elif score < 60:
        return "orta"
    return "yüksek"


# ── FastAPI Uygulaması ────────────────────────────────────────────────────────

app = FastAPI(
    title="VitaCheck AI Service",
    description="Gıda etiketi OCR + ML risk analizi + Gemini doktor tavsiyesi",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health_check():
    """Servisin ayakta olduğunu doğrular."""
    return {
        "status": "ok",
        "model_loaded": _RISK_MODEL is not None,
    }


@app.post("/extract-ocr")
async def extract_ocr(file: UploadFile = File(...)):
    """
    Sadece görseldeki OCR değerlerini 100g bazında çeker ve döndürür.
    Kullanıcı arayüzünde düzenlemeye olanak tanımak içindir.
    """
    suffix = Path(file.filename or "upload.jpg").suffix or ".jpg"
    tmp_file = None
    try:
        with tempfile.NamedTemporaryFile(
            delete=False, suffix=suffix, dir=str(_ROOT / "test_images")
        ) as tmp:
            tmp.write(await file.read())
            tmp_file = tmp.name
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Dosya kaydedilemedi: {e}")

    try:
        ocr_result = analyze_image(tmp_file)

        if ocr_result.get("status") not in ("ok", "low_quality"):
            raise HTTPException(
                status_code=422,
                detail=f"OCR başarısız: {ocr_result.get('message', 'Bilinmeyen hata')}",
            )

        serving_g_ocr: float | None = ocr_result.get("serving_g")
        raw_ocr_data: dict = ocr_result.get("data", {})

        # Normalize (100g baz)
        norm = _normalize(raw_ocr_data, serving_g_ocr)

        return {"ocr_results": norm}

    finally:
        if tmp_file and os.path.exists(tmp_file):
            os.remove(tmp_file)


class ReportRequest(BaseModel):
    ocr_data_100g: dict
    portion_gram: float
    category: str
    age: int
    height: int
    weight: int
    diseases: list[str] = []

@app.post("/generate-report")
def generate_report(req: ReportRequest):
    """
    Düzenlenmiş OCR değerleri ve porsiyon bilgisiyle ML ve Gemini raporu oluşturur.
    """
    # 1. Porsiyon ölçekleme
    scaled = _scale_to_portion(req.ocr_data_100g, req.portion_gram)

    print("[API] 1. Porsiyon ölçekleme tamam.")
    # 2. ML Risk Analizi
    print("[API] 2. ML Risk Analizi başlıyor...")
    ml_risks = _run_risk_inference(req.ocr_data_100g)
    print(f"[API] 2. ML Risk Analizi tamamlandı: {ml_risks}")
    if ml_risks is None:
        ml_risks = []  # Model yoksa boş liste döndür

    user_ml_labels = []
    for d in req.diseases:
        d_low = d.lower()
        if "diyabet" in d_low:
            ml_label = "Diyabet"
        elif "obezite" in d_low:
            ml_label = "Obezite"
        elif "hipertansiyon" in d_low or "tansiyon" in d_low:
            ml_label = "Hipertansiyon"
        elif "hiperlipidemi" in d_low or "kolesterol" in d_low or "lipid" in d_low:
            ml_label = "Hiperlipidemi"
        elif "kvh" in d_low or "kardiyo" in d_low or "kalp" in d_low:
            ml_label = "KVH"
        elif "böbrek" in d_low or "bobrek" in d_low:
            ml_label = "Bobrek"
        elif "metabolik" in d_low or "sendrom" in d_low:
            ml_label = "Metabolik_Sendrom"
        elif "karaciğer" in d_low or "karaciger" in d_low or "nafld" in d_low or "yağlanma" in d_low:
            ml_label = "NAFLD"
        elif "protein" in d_low or "enerji" in d_low or "malnütrisyon" in d_low or "malnutrisyon" in d_low or "yetersiz" in d_low:
            ml_label = "Malnutrisyon"
        elif "mineral" in d_low or "denge" in d_low:
            ml_label = "Mineral_Dengesi"
        else:
            ml_label = None

        if ml_label and ml_label not in user_ml_labels:
            user_ml_labels.append(ml_label)

    filtered_risks = [r for r in ml_risks if r["disease"] in user_ml_labels]

    if filtered_risks:
        top_risk_score = max(r["risk_score"] for r in filtered_risks)
    else:
        top_risk_score = 0.0

    if top_risk_score <= 33:
        overall_risk_level = "düşük"
    elif top_risk_score <= 66:
        overall_risk_level = "orta"
    else:
        overall_risk_level = "yüksek"

    # 3. Doktor Tavsiyesi (Gemini)
    doctor = DoctorService(GEMINI_API_KEY)
    user_profile = f"{req.age} Yaş, {req.height}cm, {req.weight}kg"
    user_diseases_str = ", ".join(req.diseases) if req.diseases else "Bilinen bir kronik rahatsızlık yok"

    # Porsiyona göre ölçeklenmiş verileri JSON string olarak ilet
    porsiyon_bazli_str = json.dumps(
        {k: v.get("per_portion") for k, v in scaled.items()},
        ensure_ascii=False,
    )
    ml_scores_str = json.dumps(
        {item["disease"]: item["risk_score"] for item in filtered_risks},
        ensure_ascii=False,
    )

    print(f"[API] 3. Gemini Doktor Servisi çağrılıyor... current_key={doctor.current_key_index}")
    try:
        doctor_advice, is_failover = doctor.tavsiye_uret(
            porsiyon_gram=req.portion_gram,
            porsiyon_bazli_veriler=porsiyon_bazli_str,
            ml_scores=ml_scores_str,
            user_profile=user_profile,
            user_diseases=user_diseases_str,
            urun_turu=req.category,
        )
        print("[API] Gemini başarıyla yanıt verdi.")
    except Exception as e:
        print(f"[Gemini Hatası]: {e}")
        doctor_advice = "Risk skorunuz ve besin değerleriniz başarıyla hesaplandı. Ancak doktor asistanımız şu an yoğun (API Kotası). Lütfen 1 dakika sonra tekrar deneyin."
        is_failover = False

    # 4. Yanıt
    return {
        "ocr_results": scaled,
        "ml_risks":    filtered_risks,
        "top_risk_score": top_risk_score,
        "overall_risk_level": overall_risk_level,
        "doctor_advice": doctor_advice,
        "is_failover": is_failover,
    }

"""
VitaCheck — Saglik Riski Model Egitimi  v1.0
=============================================
cleaned_nutrition_data.csv  ->  models/health_risk_model.joblib
                                models/scaler.joblib

10 Hastalik icin 0-100 surekli risk skoru (RandomForestRegressor).

Kullanim:
    python train_model.py
    python train_model.py --csv temiz.csv --n_estimators 200 --sample 500000
"""

import argparse
import sys
import time
import warnings
from pathlib import Path

import numpy as np
import pandas as pd
import joblib
from sklearn.ensemble import RandomForestRegressor
from sklearn.multioutput import MultiOutputRegressor
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split, GridSearchCV, KFold, cross_val_score
from sklearn.metrics import mean_absolute_error, make_scorer

warnings.filterwarnings("ignore")

# ── Yollar ───────────────────────────────────────────────────────────────────
MODEL_DIR  = Path("models")
MODEL_PATH = MODEL_DIR / "health_risk_model.joblib"
SCALER_PATH= MODEL_DIR / "scaler.joblib"
CSV_PATH   = Path("cleaned_nutrition_data.csv")

# ── Feature sutunlari ─────────────────────────────────────────────────────────
FEATURES = [
    "energy_kcal_100g",
    "fat_100g",
    "saturated_fat_100g",
    "trans_fat_100g",
    "cholesterol_100g",
    "carbohydrates_100g",
    "sugars_100g",
    "fiber_100g",
    "proteins_100g",
    "salt_100g",
    "sodium_100g",
    "potassium_100g",
    "calcium_100g",
    "iron_100g",
    "magnesium_100g",
    "zinc_100g",
    "phosphorus_100g",
    "vitamin_a_100g",
    "vitamin_c_100g",
    "vitamin_d_100g",
    "vitamin_b12_100g",
    "vitamin_b6_100g",
    "alcohol_100g",
]

# ── Hastalik etiketleri ───────────────────────────────────────────────────────
DISEASES = [
    "Diyabet",
    "Hipertansiyon",
    "Obezite",
    "KVH",           # Kardiyovaskuler Hastalik
    "Hiperlipidemi",
    "Bobrek",
    "Metabolik_Sendrom",
    "NAFLD",         # Karaciger Yaglenmasi
    "Malnutrisyon",
    "Mineral_Dengesi",
]

# ── Yardimci: sigmoid benzeri olcekleme ───────────────────────────────────────

def _score(value: float, low: float, medium: float, high: float,
           inverse: bool = False, weight: float = 1.0) -> float:
    """
    Deger -> 0-100 risk puani.
    inverse=True: yuksek deger iyi (lif, protein, vitamin).
    """
    if inverse:
        if   value >= high:   s = 0.0
        elif value >= medium: s = 20.0
        elif value >= low:    s = 50.0
        else:                 s = 90.0
    else:
        if   value <= low:    s = 5.0
        elif value <= medium: s = 35.0
        elif value <= high:   s = 70.0
        else:                 s = 95.0
    return s * weight


# ── WHO/TUBER 2022 + ADA/ESC etikelteme formulleri ────────────────────────────

def label_diyabet(row: pd.Series) -> float:
    """ADA 2023 + TUBER 2022 — Seker ve karbonhidrat agirlikli."""
    s  = _score(row.get("sugars_100g", 0),       5,  10, 22.5, weight=0.35)
    s += _score(row.get("carbohydrates_100g", 0), 20, 40, 60,  weight=0.20)
    s += _score(row.get("energy_kcal_100g", 0),  100,250,450,  weight=0.15)
    s += _score(row.get("fiber_100g", 0),         3,  6, 10,   weight=0.15, inverse=True)
    s += _score(row.get("fat_100g", 0),            3, 10, 17.5, weight=0.10)
    s += _score(row.get("salt_100g", 0),           0.3,0.75,1.5,weight=0.05)
    return min(100.0, s)


def label_hipertansiyon(row: pd.Series) -> float:
    """ESC 2018 + WHO Sodium Guidelines — Tuz ve sodyum/potasyum orani."""
    s  = _score(row.get("salt_100g", 0),          0.3, 0.6, 1.5,  weight=0.40)
    s += _score(row.get("sodium_100g", 0),         120, 240, 600,  weight=0.20)
    s += _score(row.get("saturated_fat_100g", 0),  1.5, 3.0, 5.0,  weight=0.15)
    s += _score(row.get("fat_100g", 0),             3,  10, 17.5,  weight=0.10)
    # Sodyum/Potasyum orani — logaritmik ceza
    na = row.get("sodium_100g", 0)
    k  = row.get("potassium_100g", 1) or 1
    ratio = na / k
    ratio_score = min(100, 20 * np.log1p(max(0, ratio - 1))) if ratio > 1 else 0
    s += ratio_score * 0.15
    return min(100.0, s)


def label_obezite(row: pd.Series) -> float:
    """WHO Obesity + NICE 2014 — Enerji ve yag agirlikli."""
    s  = _score(row.get("energy_kcal_100g", 0),   100, 250, 450,  weight=0.35)
    s += _score(row.get("fat_100g", 0),              3,  10,  20,  weight=0.25)
    s += _score(row.get("sugars_100g", 0),           5,  10, 22.5, weight=0.20)
    s += _score(row.get("saturated_fat_100g", 0),   1.5, 3,   5,   weight=0.10)
    s += _score(row.get("fiber_100g", 0),            3,  6,  10,   weight=0.10, inverse=True)
    return min(100.0, s)


def label_kvh(row: pd.Series) -> float:
    """ACC/AHA 2019 + ESC 2021 — Doymus yag ve tuz."""
    s  = _score(row.get("saturated_fat_100g", 0),  1.5, 3.0,  5.0, weight=0.35)
    s += _score(row.get("salt_100g", 0),            0.3, 0.75, 1.5, weight=0.25)
    s += _score(row.get("cholesterol_100g", 0),      50, 100,  200, weight=0.15)
    s += _score(row.get("trans_fat_100g", 0),         0, 0.5,  2.0, weight=0.15)
    s += _score(row.get("fiber_100g", 0),             3,   6,   10, weight=0.10, inverse=True)
    return min(100.0, s)


def label_hiperlipidemi(row: pd.Series) -> float:
    """ESC/EAS 2019 Dyslipidemia Guidelines."""
    s  = _score(row.get("saturated_fat_100g", 0),  1.5, 2.5,  5.0, weight=0.40)
    s += _score(row.get("trans_fat_100g", 0),         0, 0.5,  2.0, weight=0.25)
    s += _score(row.get("cholesterol_100g", 0),      50, 100,  200, weight=0.20)
    s += _score(row.get("sugars_100g", 0),            5,  10, 22.5, weight=0.10)
    s += _score(row.get("fiber_100g", 0),             3,   6,   10, weight=0.05, inverse=True)
    return min(100.0, s)


def label_bobrek(row: pd.Series) -> float:
    """KDIGO 2012 + NKF Guidelines — Protein ve tuz."""
    s  = _score(row.get("proteins_100g", 0),        5,  10,  20,  weight=0.30)
    s += _score(row.get("salt_100g", 0),            0.3, 0.6, 1.5, weight=0.30)
    s += _score(row.get("sodium_100g", 0),          120, 240, 600, weight=0.15)
    s += _score(row.get("phosphorus_100g", 0),       50, 150, 300, weight=0.15)
    s += _score(row.get("potassium_100g", 0),        100, 300, 600, weight=0.10)
    return min(100.0, s)


def label_metabolik(row: pd.Series) -> float:
    """IDF 2006 + ATP III — Coklu faktor."""
    s  = _score(row.get("sugars_100g", 0),          5,  10, 22.5, weight=0.25)
    s += _score(row.get("energy_kcal_100g", 0),    100, 200,  400, weight=0.20)
    s += _score(row.get("fat_100g", 0),              3,  10,   20, weight=0.20)
    s += _score(row.get("salt_100g", 0),            0.3,0.75,  1.5, weight=0.15)
    s += _score(row.get("saturated_fat_100g", 0),  1.5,  3.0,  5.0, weight=0.10)
    s += _score(row.get("fiber_100g", 0),            3,   6,   10, weight=0.10, inverse=True)
    return min(100.0, s)


def label_nafld(row: pd.Series) -> float:
    """EASL 2016 NAFLD Guidelines — Yag ve seker."""
    s  = _score(row.get("fat_100g", 0),             3,  10,   20, weight=0.30)
    s += _score(row.get("sugars_100g", 0),          5,  10, 22.5, weight=0.30)
    s += _score(row.get("energy_kcal_100g", 0),   100, 250,  400, weight=0.20)
    s += _score(row.get("saturated_fat_100g", 0), 1.5,  3.0,  5.0, weight=0.10)
    s += _score(row.get("alcohol_100g", 0),          0,  2.5,   5, weight=0.10)
    return min(100.0, s)


def label_malnutrisyon(row: pd.Series) -> float:
    """WHO Global Nutrition — Eksik besin tespiti (inverse scoring)."""
    s  = _score(row.get("proteins_100g", 0),        5,  10,  20, weight=0.30, inverse=True)
    s += _score(row.get("energy_kcal_100g", 0),   100, 200, 400, weight=0.25, inverse=True)
    s += _score(row.get("iron_100g", 0),          0.5, 1.5,  3,  weight=0.15, inverse=True)
    s += _score(row.get("calcium_100g", 0),        50, 100, 200, weight=0.15, inverse=True)
    s += _score(row.get("vitamin_c_100g", 0),       5,  15,  30, weight=0.15, inverse=True)
    return min(100.0, s)


def label_mineral_dengesi(row: pd.Series) -> float:
    """Mineral dengesizligi riski — Ca/P, Na/K oranlari."""
    # Kalsiyum/Fosfor orani idealin disina cikinca risk artar
    ca = row.get("calcium_100g", 0)
    p  = row.get("phosphorus_100g", 1) or 1
    ca_p_ratio = ca / p
    # Ideal 1.0-1.5, altinda veya ustunde risk
    ca_p_score = min(100, 40 * abs(ca_p_ratio - 1.2))

    # Na/K orani
    na = row.get("sodium_100g", 0)
    k  = row.get("potassium_100g", 1) or 1
    na_k_score = min(100, 25 * np.log1p(max(0, (na / k) - 1)))

    s  = ca_p_score * 0.40
    s += na_k_score * 0.30
    s += _score(row.get("magnesium_100g", 0),    10,  30,  60, weight=0.15, inverse=True)
    s += _score(row.get("zinc_100g", 0),         0.5, 1.5, 3.0, weight=0.15, inverse=True)
    return min(100.0, s)


# Fonksiyon haritasi
LABEL_FNS = [
    label_diyabet, label_hipertansiyon, label_obezite, label_kvh,
    label_hiperlipidemi, label_bobrek, label_metabolik, label_nafld,
    label_malnutrisyon, label_mineral_dengesi,
]


# ── Etikelleme ────────────────────────────────────────────────────────────────

def compute_labels(df: pd.DataFrame) -> pd.DataFrame:
    """DataFrame'in her satiri icin 10 hastalik skoru hesaplar."""
    print(f"  Etiketleniyor: {len(df):,} satir x {len(DISEASES)} hastalik...", end=" ", flush=True)
    t = time.perf_counter()
    labels = {}
    for disease, fn in zip(DISEASES, LABEL_FNS):
        labels[disease] = df.apply(fn, axis=1).astype("float32")
    print(f"  {time.perf_counter()-t:.1f}sn")
    return pd.DataFrame(labels)


# ── Inference fonksiyonu (model yuklenince kullanilir) ────────────────────────

_loaded_model  = None
_loaded_scaler = None


def _load_artifacts():
    global _loaded_model, _loaded_scaler
    if _loaded_model is None:
        _loaded_model  = joblib.load(MODEL_PATH)
        _loaded_scaler = joblib.load(SCALER_PATH)


def predict_risk(data: dict) -> dict[str, float]:
    """
    OCR/kullanici verisinden 10 hastalik riski dondurur.

    Parametreler
    ────────────
    data : dict  — normalised_data veya duz sayisal sozluk
        Ornek: {"sugars_100g": 43, "fat_100g": 26, ...}
        Gelmese sozlukten 0 atanir.

    Donus
    ─────
    {"Diyabet": 72.3, "Hipertansiyon": 48.1, ...}
    """
    _load_artifacts()
    row = [float(data.get(f, 0) or 0) for f in FEATURES]
    X   = np.array(row, dtype="float32").reshape(1, -1)
    X_s = _loaded_scaler.transform(X)
    preds = _loaded_model.predict(X_s)[0]
    return {d: round(float(p), 1) for d, p in zip(DISEASES, preds)}


# ── Egitim akisi ──────────────────────────────────────────────────────────────

def train(csv_path: str, n_estimators: int, sample: int | None, tune: bool = False) -> None:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore

    # ── 1. Veri yukle ─────────────────────────────────────────────────────
    print(f"\n{'='*60}")
    print("  ADIM 1 -- Veri Yukleme")
    print(f"{'='*60}")
    t0 = time.perf_counter()

    # CSV basliklarini oku -> sadece FEATURES'tan mevcut olanlari sec
    header_df  = pd.read_csv(csv_path, nrows=0, encoding="utf-8-sig")
    avail_feats = [f for f in FEATURES if f in header_df.columns]
    missing_feats = [f for f in FEATURES if f not in header_df.columns]
    if missing_feats:
        print(f"  Uyari: {len(missing_feats)} feature CSV'de yok, 0 atanacak: {missing_feats[:5]}...")

    # Sadece sayisal besin sutunlarini yukle (metin sutunlari tamamen disarda)
    dtype_map = {f: "float32" for f in avail_feats}
    df = pd.read_csv(
        csv_path,
        usecols=avail_feats,       # sadece feature sutunlari
        dtype=dtype_map,           # hepsi float32 (metin yok)
        on_bad_lines="skip",
        low_memory=False,
        encoding="utf-8-sig",
    )

    n_total = len(df)
    if sample and sample < n_total:
        df = df.sample(n=sample, random_state=42)
        print(f"  Ornekleme: {sample:,} / {n_total:,} satir")

    # Eksik feature sutunlarini 0 ile ekle
    for f in FEATURES:
        if f not in df.columns:
            df[f] = 0.0

    # Son guvence: hala NaN varsa 0 yap
    df = df[FEATURES].fillna(0.0).astype("float32")
    print(f"  Yuklendi: {len(df):,} satir  |  {len(FEATURES)} feature")
    print(f"  Sure: {time.perf_counter()-t0:.1f}sn")


    # ── 2. Etiketleme ─────────────────────────────────────────────────────
    print(f"\n{'='*60}")
    print("  ADIM 2 -- Tibbi Etiketleme (WHO/TUBER 2022)")
    print(f"{'='*60}")
    Y = compute_labels(df)
    print(f"  Skor aralik ozeti (ilk hastalik ornegi):")
    print(f"  {DISEASES[0]:20}  min={Y[DISEASES[0]].min():.1f}  "
          f"max={Y[DISEASES[0]].max():.1f}  "
          f"ort={Y[DISEASES[0]].mean():.1f}")

    # ── 3. Olcekleme ──────────────────────────────────────────────────────
    print(f"\n{'='*60}")
    print("  ADIM 3 -- StandardScaler")
    print(f"{'='*60}")
    X = df.values.astype("float32")
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)

    # ── 4. Train/Test ayir ────────────────────────────────────────────────
    X_tr, X_te, Y_tr, Y_te = train_test_split(
        X_scaled, Y.values, test_size=0.15, random_state=42
    )
    print(f"  Egitim: {len(X_tr):,}  |  Test: {len(X_te):,}")

    # ── AR-GE: Hyperparameter Tuning (GridSearchCV) ───────────────────────
    best_params = {
        "estimator__n_estimators": n_estimators,
        "estimator__max_depth": 10,
        "estimator__min_samples_split": 40,
        "estimator__min_samples_leaf": 20,
    }

    if tune:
        print(f"\n{'='*60}")
        print("  ADIM 4.1 -- GridSearchCV ile Parametre Optimizasyonu")
        print(f"{'='*60}")
        param_grid = {
            "estimator__n_estimators": [50, 100, 150],
            "estimator__max_depth": [10, 15],
            "estimator__min_samples_split": [20, 40],
        }
        
        # Hizli tuning icin verinin kucuk bir kismini kullan (maksimium 50k satir)
        tune_size = min(len(X_tr), 50000)
        idx = np.random.choice(len(X_tr), tune_size, replace=False)
        X_tune, Y_tune = X_tr[idx], Y_tr[idx]
        
        base_tune = RandomForestRegressor(max_features="sqrt", random_state=42)
        grid = GridSearchCV(
            MultiOutputRegressor(base_tune),
            param_grid,
            cv=3,
            scoring="neg_mean_absolute_error",
            n_jobs=-1,
            verbose=1
        )
        t_tune = time.perf_counter()
        grid.fit(X_tune, Y_tune)
        best_params = grid.best_params_
        print(f"  Tuning suresi: {time.perf_counter()-t_tune:.1f}sn")
        print(f"  En iyi parametreler: {best_params}")

    # ── 5. Nihai Model Egitimi ────────────────────────────────────────────
    print(f"\n{'='*60}")
    print(f"  ADIM 4.2 -- Nihai Model Egitimi (Tüm Veri)")
    print(f"{'='*60}")
    t_fit = time.perf_counter()
    base  = RandomForestRegressor(
        n_estimators=best_params.get("estimator__n_estimators", n_estimators),
        max_depth=best_params.get("estimator__max_depth", 10),
        min_samples_split=best_params.get("estimator__min_samples_split", 40),
        min_samples_leaf=best_params.get("estimator__min_samples_leaf", 20),
        max_features="sqrt",
        random_state=42,
        n_jobs=-1,
    )
    model = MultiOutputRegressor(base, n_jobs=-1)
    model.fit(X_tr, Y_tr)
    print(f"  Egitim suresi: {time.perf_counter()-t_fit:.1f}sn")

    # ── 6. 5-Fold Cross Validation ────────────────────────────────────────
    print(f"\n{'='*60}")
    print("  ADIM 5 -- 5-Fold Cross Validation Dogrulamasi")
    print(f"{'='*60}")
    kf = KFold(n_splits=5, shuffle=True, random_state=42)
    
    # Hizli CV icin egitim verisinin 100k'lik kismiyla test et (2.6M CV cok uzun surer)
    cv_size = min(len(X_tr), 100000)
    idx_cv = np.random.choice(len(X_tr), cv_size, replace=False)
    
    mae_scorer = make_scorer(mean_absolute_error, greater_is_better=False)
    cv_scores = cross_val_score(model, X_tr[idx_cv], Y_tr[idx_cv], cv=kf, scoring=mae_scorer, n_jobs=-1)
    cv_mae_scores = -cv_scores
    
    for i, score in enumerate(cv_mae_scores):
        print(f"  Fold {i+1} MAE : {score:.3f}")
    mean_cv_mae = cv_mae_scores.mean()
    print(f"  Ortalama CV MAE : {mean_cv_mae:.3f} (+/- {cv_mae_scores.std():.3f})")

    # ── 7. Test Performansi (Geri kalan %15 uzerinden) ────────────────────
    print(f"\n{'='*60}")
    print("  ADIM 6 -- Held-Out Test Performansi (MAE)")
    print(f"{'='*60}")
    Y_pred = model.predict(X_te)
    test_maes = {}
    for i, d in enumerate(DISEASES):
        mae = mean_absolute_error(Y_te[:, i], Y_pred[:, i])
        test_maes[d] = mae
        print(f"  {d:22}  MAE = {mae:5.2f}")

    # ── 8. Feature Importance ─────────────────────────────────────────────
    print(f"\n{'='*60}")
    print("  ADIM 7 -- Feature Importance (Her Hastalik icin Top 3)")
    print(f"{'='*60}")
    for i, d in enumerate(DISEASES):
        fi   = model.estimators_[i].feature_importances_
        top3 = np.argsort(fi)[::-1][:3]
        parts = [f"{FEATURES[j].replace('_100g','')}({fi[j]*100:.0f}%)" for j in top3]
        print(f"  {d:22}  {' | '.join(parts)}")

    # ── 9. Rapor ve Kayit ─────────────────────────────────────────────────
    print(f"\n{'='*60}")
    print("  ADIM 8 -- Raporlama ve Kayit")
    print(f"{'='*60}")
    MODEL_DIR.mkdir(exist_ok=True)
    joblib.dump(model,  MODEL_PATH,  compress=3)
    joblib.dump(scaler, SCALER_PATH, compress=3)
    
    # Rapor txt
    report_path = Path("final_model_performance.txt")
    with open(report_path, "w", encoding="utf-8") as f:
        f.write("VitaCheck Model Egitim ve Dogrulama Raporu\n")
        f.write("==========================================\n\n")
        f.write(f"Egitim Satir Sayisi : {len(X_tr):,}\n")
        f.write(f"Test Satir Sayisi   : {len(X_te):,}\n\n")
        f.write("En Iyi Hiperparametreler (GridSearchCV):\n")
        for k, v in best_params.items():
            f.write(f"  {k}: {v}\n")
        f.write("\n5-Fold Cross Validation Sonuclari (MAE):\n")
        for i, score in enumerate(cv_mae_scores):
            f.write(f"  Fold {i+1}: {score:.3f}\n")
        f.write(f"  Ortalama MAE: {mean_cv_mae:.3f} (+/- {cv_mae_scores.std():.3f})\n\n")
        f.write("Hastalik Bazli Test MAE Sonuclari:\n")
        for d, mae in test_maes.items():
            f.write(f"  {d:22}: {mae:.3f}\n")
            
    print(f"  Rapor  -> {report_path}")
    print(f"  Model  -> {MODEL_PATH}  ({MODEL_PATH.stat().st_size/1e6:.1f} MB)")
    print(f"  Scaler -> {SCALER_PATH}")

    total = time.perf_counter() - t0
    print(f"\n  TOPLAM SURE: {total:.1f}sn")
    print(f"  Toplam satir egitildi: {len(X_tr):,}\n")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="VitaCheck Risk Model Egitimi v1.0"
    )
    parser.add_argument("--csv",          default=str(CSV_PATH))
    parser.add_argument("--n_estimators", type=int, default=150,
                        help="RF agac sayisi (varsayilan: 150)")
    parser.add_argument("--sample",       type=int, default=None,
                        help="Ornekleme satir sayisi (tum veri icin bos birakin)")
    parser.add_argument("--tune",         action="store_true",
                        help="GridSearchCV ile hiperparametre optimizasyonu yap")
    args = parser.parse_args()
    train(args.csv, args.n_estimators, args.sample, args.tune)


if __name__ == "__main__":
    main()

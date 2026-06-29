"""
VitaCheck — Model Degerlendirme  v1.0
======================================
Egitilen modelin makale duzeyinde performans analizi.

Ciktilar:
  - R^2 Skoru (her hastalik icin)
  - Korelasyon Matrisi (Pearson)
  - Hata Dagilim Grafigi (Residual Plot)  -> evaluation/residual_plots.png
  - Top-10 Urun Karsilastirma Tablosu     -> evaluation/top10_comparison.csv

Kullanim:
    python evaluate_model.py
    python evaluate_model.py --sample 100000 --seed 99
"""

import argparse
import sys
import time
import warnings
from pathlib import Path

import numpy as np
import pandas as pd
import joblib
from sklearn.metrics import r2_score, mean_absolute_error
from scipy.stats import pearsonr

warnings.filterwarnings("ignore")

# ── Yollar ────────────────────────────────────────────────────────────────────
ROOT        = Path(__file__).resolve().parent
MODEL_PATH  = ROOT / "models" / "health_risk_model.joblib"
SCALER_PATH = ROOT / "models" / "scaler.joblib"
CSV_PATH    = ROOT / "cleaned_nutrition_data.csv"
EVAL_DIR    = ROOT / "evaluation"

DISEASES = [
    "Diyabet", "Hipertansiyon", "Obezite", "KVH", "Hiperlipidemi",
    "Bobrek", "Metabolik_Sendrom", "NAFLD", "Malnutrisyon", "Mineral_Dengesi",
]

FEATURES = [
    "energy_kcal_100g", "fat_100g", "saturated_fat_100g", "trans_fat_100g",
    "cholesterol_100g", "carbohydrates_100g", "sugars_100g", "fiber_100g",
    "proteins_100g", "salt_100g", "sodium_100g", "potassium_100g",
    "calcium_100g", "iron_100g", "magnesium_100g", "zinc_100g",
    "phosphorus_100g", "vitamin_a_100g", "vitamin_c_100g", "vitamin_d_100g",
    "vitamin_b12_100g", "vitamin_b6_100g", "alcohol_100g",
]


# ── Etiketleme (train_model.py ile ayni formul) ───────────────────────────────
def _score(v, lo, med, hi, inv=False, w=1.0):
    if inv:
        s = 0.0 if v >= hi else (20.0 if v >= med else (50.0 if v >= lo else 90.0))
    else:
        s = 5.0 if v <= lo else (35.0 if v <= med else (70.0 if v <= hi else 95.0))
    return s * w


def _who_labels(df: pd.DataFrame) -> pd.DataFrame:
    """WHO formulleriyle referans skorlari uretir (altin standart)."""
    def diyabet(r):
        return min(100, _score(r.sugars_100g,5,10,22.5,w=.35) +
                        _score(r.carbohydrates_100g,20,40,60,w=.20) +
                        _score(r.energy_kcal_100g,100,250,450,w=.15) +
                        _score(r.fiber_100g,3,6,10,inv=True,w=.15) +
                        _score(r.fat_100g,3,10,17.5,w=.10) +
                        _score(r.salt_100g,0.3,0.75,1.5,w=.05))

    def hipertansiyon(r):
        ratio = r.sodium_100g / max(r.potassium_100g, 1)
        ratio_s = min(100, 20 * np.log1p(max(0, ratio - 1))) if ratio > 1 else 0
        return min(100, _score(r.salt_100g,0.3,0.6,1.5,w=.40) +
                        _score(r.sodium_100g,120,240,600,w=.20) +
                        _score(r.saturated_fat_100g,1.5,3,5,w=.15) +
                        _score(r.fat_100g,3,10,17.5,w=.10) + ratio_s * .15)

    def obezite(r):
        return min(100, _score(r.energy_kcal_100g,100,250,450,w=.35) +
                        _score(r.fat_100g,3,10,20,w=.25) +
                        _score(r.sugars_100g,5,10,22.5,w=.20) +
                        _score(r.saturated_fat_100g,1.5,3,5,w=.10) +
                        _score(r.fiber_100g,3,6,10,inv=True,w=.10))

    def kvh(r):
        return min(100, _score(r.saturated_fat_100g,1.5,3,5,w=.35) +
                        _score(r.salt_100g,0.3,0.75,1.5,w=.25) +
                        _score(r.cholesterol_100g,50,100,200,w=.15) +
                        _score(r.trans_fat_100g,0,0.5,2,w=.15) +
                        _score(r.fiber_100g,3,6,10,inv=True,w=.10))

    def hiperlipidemi(r):
        return min(100, _score(r.saturated_fat_100g,1.5,2.5,5,w=.40) +
                        _score(r.trans_fat_100g,0,0.5,2,w=.25) +
                        _score(r.cholesterol_100g,50,100,200,w=.20) +
                        _score(r.sugars_100g,5,10,22.5,w=.10) +
                        _score(r.fiber_100g,3,6,10,inv=True,w=.05))

    def bobrek(r):
        return min(100, _score(r.proteins_100g,5,10,20,w=.30) +
                        _score(r.salt_100g,0.3,0.6,1.5,w=.30) +
                        _score(r.sodium_100g,120,240,600,w=.15) +
                        _score(r.phosphorus_100g,50,150,300,w=.15) +
                        _score(r.potassium_100g,100,300,600,w=.10))

    def metabolik(r):
        return min(100, _score(r.sugars_100g,5,10,22.5,w=.25) +
                        _score(r.energy_kcal_100g,100,200,400,w=.20) +
                        _score(r.fat_100g,3,10,20,w=.20) +
                        _score(r.salt_100g,0.3,0.75,1.5,w=.15) +
                        _score(r.saturated_fat_100g,1.5,3,5,w=.10) +
                        _score(r.fiber_100g,3,6,10,inv=True,w=.10))

    def nafld(r):
        return min(100, _score(r.fat_100g,3,10,20,w=.30) +
                        _score(r.sugars_100g,5,10,22.5,w=.30) +
                        _score(r.energy_kcal_100g,100,250,400,w=.20) +
                        _score(r.saturated_fat_100g,1.5,3,5,w=.10) +
                        _score(r.alcohol_100g,0,2.5,5,w=.10))

    def malnutrisyon(r):
        return min(100, _score(r.proteins_100g,5,10,20,inv=True,w=.30) +
                        _score(r.energy_kcal_100g,100,200,400,inv=True,w=.25) +
                        _score(r.iron_100g,0.5,1.5,3,inv=True,w=.15) +
                        _score(r.calcium_100g,50,100,200,inv=True,w=.15) +
                        _score(r.vitamin_c_100g,5,15,30,inv=True,w=.15))

    def mineral(r):
        ca_p = (r.calcium_100g / max(r.phosphorus_100g, 1))
        na_k = r.sodium_100g / max(r.potassium_100g, 1)
        return min(100,
                   min(100, 40 * abs(ca_p - 1.2)) * .40 +
                   min(100, 25 * np.log1p(max(0, na_k - 1))) * .30 +
                   _score(r.magnesium_100g,10,30,60,inv=True,w=.15) +
                   _score(r.zinc_100g,0.5,1.5,3,inv=True,w=.15))

    fns = [diyabet, hipertansiyon, obezite, kvh, hiperlipidemi,
           bobrek, metabolik, nafld, malnutrisyon, mineral]

    print("  WHO referans skorlari hesaplaniyor...", end=" ", flush=True)
    t = time.perf_counter()
    result = {d: df.apply(fn, axis=1).values.astype("float32")
              for d, fn in zip(DISEASES, fns)}
    print(f"{time.perf_counter()-t:.1f}sn")
    return pd.DataFrame(result, index=df.index)


# ── Metrikler ─────────────────────────────────────────────────────────────────

def _banner(txt): print(f"\n{'='*62}\n  {txt}\n{'='*62}")


def evaluate(csv_path: str, sample: int, seed: int) -> None:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore
    EVAL_DIR.mkdir(exist_ok=True)

    # ── 1. Model yukle ────────────────────────────────────────────────────
    _banner("ADIM 1 -- Model Yukleme")
    if not MODEL_PATH.exists():
        print("  HATA: models/health_risk_model.joblib bulunamadi.")
        print("  Once 'python train_model.py' calistirin.")
        sys.exit(1)
    model  = joblib.load(MODEL_PATH)
    scaler = joblib.load(SCALER_PATH)
    print(f"  Model  : {MODEL_PATH} ({MODEL_PATH.stat().st_size/1e6:.1f} MB)")
    print(f"  Scaler : {SCALER_PATH}")

    # ── 2. Veri yukle ─────────────────────────────────────────────────────
    _banner("ADIM 2 -- Veri Yukleme")
    avail = pd.read_csv(csv_path, nrows=0, encoding="utf-8-sig").columns.tolist()
    use   = [f for f in FEATURES if f in avail]
    meta_cols = [c for c in ["product_name", "categories"] if c in avail]

    df_feat = pd.read_csv(csv_path, usecols=use,
                          dtype={f: "float32" for f in use},
                          low_memory=False, encoding="utf-8-sig").fillna(0.0)

    df_meta = pd.read_csv(csv_path, usecols=meta_cols or [use[0]],
                          low_memory=False, encoding="utf-8-sig") if meta_cols else pd.DataFrame()

    if sample and sample < len(df_feat):
        idx = df_feat.sample(n=sample, random_state=seed).index
        df_feat = df_feat.loc[idx].reset_index(drop=True)
        if not df_meta.empty:
            df_meta = df_meta.loc[idx].reset_index(drop=True)
        print(f"  Ornekleme: {sample:,} satir")
    else:
        df_feat = df_feat.reset_index(drop=True)
        df_meta = df_meta.reset_index(drop=True) if not df_meta.empty else df_meta
    print(f"  Yuklu: {len(df_feat):,} satir")

    # ── 3. WHO altin standart ─────────────────────────────────────────────
    _banner("ADIM 3 -- WHO Referans Etiketleme")
    Y_true = _who_labels(df_feat)

    # ── 4. Model tahmini ──────────────────────────────────────────────────
    _banner("ADIM 4 -- Model Tahmini")
    X_scaled = scaler.transform(df_feat[FEATURES].values.astype("float32"))
    t0 = time.perf_counter()
    Y_pred_arr = model.predict(X_scaled)
    print(f"  Inference suresi: {time.perf_counter()-t0:.2f}sn  "
          f"({len(df_feat)/(time.perf_counter()-t0):.0f} satir/sn)")
    Y_pred = pd.DataFrame(Y_pred_arr, columns=DISEASES)

    # ── 5. R^2 + MAE + Pearson ────────────────────────────────────────────
    _banner("ADIM 5 -- Performans Metrikleri (Makale Seviyesi)")
    print(f"\n  {'HASTALIK':<22} {'R^2':>6} {'MAE':>6} {'Pearson-r':>10} {'p-value':>10}")
    print(f"  {'-'*58}")
    metrics = []
    for d in DISEASES:
        yt = Y_true[d].values
        yp = Y_pred[d].values
        r2  = r2_score(yt, yp)
        mae = mean_absolute_error(yt, yp)
        r, p = pearsonr(yt, yp)
        sig = "***" if p < 0.001 else ("**" if p < 0.01 else ("*" if p < 0.05 else "ns"))
        print(f"  {d:<22} {r2:>6.3f} {mae:>6.2f} {r:>10.4f} {p:>10.2e} {sig}")
        metrics.append({"Hastalik": d, "R2": r2, "MAE": mae, "Pearson_r": r, "p_value": p})
    df_metrics = pd.DataFrame(metrics)
    df_metrics.to_csv(EVAL_DIR / "metrics.csv", index=False, encoding="utf-8-sig")
    print(f"\n  Ortalama R^2 : {df_metrics['R2'].mean():.3f}")
    print(f"  Ortalama MAE : {df_metrics['MAE'].mean():.2f}")

    # ── 6. Korelasyon Matrisi ─────────────────────────────────────────────
    _banner("ADIM 6 -- Hastalik Ici Korelasyon Matrisi (Tahmin vs WHO)")
    corr_rows = {}
    for d in DISEASES:
        row = {}
        for d2 in DISEASES:
            r, _ = pearsonr(Y_pred[d].values, Y_true[d2].values)
            row[d2] = round(r, 3)
        corr_rows[d] = row
    corr_df = pd.DataFrame(corr_rows).T
    print(corr_df.to_string())
    corr_df.to_csv(EVAL_DIR / "correlation_matrix.csv", encoding="utf-8-sig")
    print(f"\n  Kaydedildi -> evaluation/correlation_matrix.csv")

    # ── 7. Residual Plot ──────────────────────────────────────────────────
    _banner("ADIM 7 -- Hata Dagilim Grafigi (Residual Plot)")
    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt

        fig, axes = plt.subplots(2, 5, figsize=(20, 8))
        fig.suptitle("VitaCheck — Residual Analysis (Predicted vs WHO Formula)",
                     fontsize=14, fontweight="bold")
        axes = axes.flatten()

        for i, d in enumerate(DISEASES):
            yt  = Y_true[d].values
            yp  = Y_pred[d].values
            res = yp - yt
            r2  = r2_score(yt, yp)
            ax  = axes[i]
            ax.scatter(yp, res, alpha=0.15, s=2, color="#2196F3")
            ax.axhline(0, color="red", linewidth=1.2, linestyle="--")
            ax.set_title(f"{d}\nR²={r2:.3f}", fontsize=9, fontweight="bold")
            ax.set_xlabel("Tahmin (0-100)", fontsize=7)
            ax.set_ylabel("Hata (Pred - True)", fontsize=7)
            ax.tick_params(labelsize=7)
            # Hata yogunluk bandi
            ax.axhspan(-5, 5, alpha=0.08, color="green", label="±5 bant")

        plt.tight_layout()
        out = EVAL_DIR / "residual_plots.png"
        plt.savefig(out, dpi=150, bbox_inches="tight")
        plt.close()
        print(f"  Kaydedildi -> {out}")
    except ImportError:
        print("  matplotlib bulunamadi. Grafik atlanadi.")
        print("  Kurmak icin: pip install matplotlib")

    # ── 8. Top-10 Urun Karsilastirma ──────────────────────────────────────
    _banner("ADIM 8 -- Top-10 Gercek Urun: Manuel vs Model Karsilastirma")
    sample10 = df_feat.sample(n=10, random_state=seed + 1)
    X10      = scaler.transform(sample10[FEATURES].values.astype("float32"))
    pred10   = model.predict(X10)
    true10   = _who_labels(sample10).values

    rows = []
    # Urun adi (varsa)
    names = []
    if not df_meta.empty and "product_name" in df_meta.columns:
        names = df_meta.loc[sample10.index, "product_name"].fillna("?").tolist()
    else:
        names = [f"Urun #{i+1}" for i in range(10)]

    print(f"\n  {'URUN':<28} {'HASTALIK':<20} {'WHO':>6} {'MODEL':>7} {'FARK':>6}")
    print(f"  {'-'*70}")
    for i, name in enumerate(names):
        short = (name[:26] + "..") if len(str(name)) > 28 else str(name)
        for j, d in enumerate(DISEASES):
            who_v   = round(float(true10[i, j]), 1)
            model_v = round(float(pred10[i, j]), 1)
            diff    = round(model_v - who_v, 1)
            flag    = " <-- SAPMA" if abs(diff) > 10 else ""
            n_col   = short if j == 0 else " " * 28
            print(f"  {n_col:<28} {d:<20} {who_v:>6.1f} {model_v:>7.1f} {diff:>+6.1f}{flag}")
        rows.append({
            "product": name,
            **{f"WHO_{d}": round(float(true10[i, j]), 1) for j, d in enumerate(DISEASES)},
            **{f"Model_{d}": round(float(pred10[i, j]), 1) for j, d in enumerate(DISEASES)},
        })
        print(f"  {'-'*70}")

    df_top10 = pd.DataFrame(rows)
    df_top10.to_csv(EVAL_DIR / "top10_comparison.csv", index=False, encoding="utf-8-sig")
    print(f"\n  Kaydedildi -> evaluation/top10_comparison.csv")

    # ── Final Ozet ────────────────────────────────────────────────────────
    _banner("DEGERLENDIRME OZETI")
    print(f"  Test ornegi          : {len(df_feat):,} urun")
    print(f"  Ortalama R^2         : {df_metrics['R2'].mean():.4f}")
    print(f"  Ortalama Pearson r   : {df_metrics['Pearson_r'].mean():.4f}")
    print(f"  Ortalama MAE         : {df_metrics['MAE'].mean():.2f} puan")
    print(f"  Cikti dizini         : {EVAL_DIR}/")
    print(f"    metrics.csv")
    print(f"    correlation_matrix.csv")
    print(f"    residual_plots.png")
    print(f"    top10_comparison.csv\n")


def main():
    parser = argparse.ArgumentParser(
        description="VitaCheck Model Degerlendirme v1.0"
    )
    parser.add_argument("--csv",    default=str(CSV_PATH))
    parser.add_argument("--sample", type=int, default=200000,
                        help="Test ornekleme sayisi (varsayilan: 200000)")
    parser.add_argument("--seed",   type=int, default=42)
    args = parser.parse_args()
    evaluate(args.csv, args.sample, args.seed)


if __name__ == "__main__":
    main()

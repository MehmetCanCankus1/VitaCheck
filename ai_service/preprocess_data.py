"""
VitaCheck — Veri On Isleme  v2.0
==================================
food.parquet (Open Food Facts, nested nutriments struct)
    -> cleaned_nutrition_data.csv

Parquet yapisi:
  nutriments: list<struct<name, value, 100g, serving, unit, ...>>
  Her urun icin besin adi+deger cifti listesi -> pivot ile flat hale getirilir.

Kullanim:
    python preprocess_data.py
    python preprocess_data.py --input baska.parquet --output temiz.csv
    python preprocess_data.py --sample 50000   (hizli test icin)
"""

import argparse
import sys
import time
from pathlib import Path

import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq

# ── Hedef besin adlari (nutriments[].name alanindaki degerler) ────────────────

NUTRIENT_TARGETS = {
    # Istenilen ad              CSV sutun adi
    "energy-kcal":              "energy_kcal_100g",
    "fat":                      "fat_100g",
    "saturated-fat":            "saturated_fat_100g",
    "trans-fat":                "trans_fat_100g",
    "cholesterol":              "cholesterol_100g",
    "carbohydrates":            "carbohydrates_100g",
    "sugars":                   "sugars_100g",
    "fiber":                    "fiber_100g",
    "proteins":                 "proteins_100g",
    "salt":                     "salt_100g",
    "sodium":                   "sodium_100g",
    "potassium":                "potassium_100g",
    "calcium":                  "calcium_100g",
    "iron":                     "iron_100g",
    "magnesium":                "magnesium_100g",
    "zinc":                     "zinc_100g",
    "phosphorus":               "phosphorus_100g",
    "vitamin-a":                "vitamin_a_100g",
    "vitamin-c":                "vitamin_c_100g",
    "vitamin-d":                "vitamin_d_100g",
    "vitamin-b12":              "vitamin_b12_100g",
    "vitamin-b6":               "vitamin_b6_100g",
    "alcohol":                  "alcohol_100g",
}

# Zorunlu: bunlar bos ise satir sil
REQUIRED_CSV_COLS = [
    "energy_kcal_100g",
    "sugars_100g",
    "salt_100g",
    "fat_100g",
    "proteins_100g",
]

# Impute (NaN -> 0): vitamin + mineral + alkol
IMPUTE_ZERO_CSV_COLS = [
    "potassium_100g","calcium_100g","iron_100g","magnesium_100g",
    "zinc_100g","phosphorus_100g","sodium_100g",
    "vitamin_a_100g","vitamin_c_100g","vitamin_d_100g",
    "vitamin_b12_100g","vitamin_b6_100g","alcohol_100g",
]

# Fiziksel sinirlar (min, max)
PHYSICAL_LIMITS = {
    "energy_kcal_100g":   (0, 900),
    "fat_100g":           (0, 100),
    "saturated_fat_100g": (0, 100),
    "trans_fat_100g":     (0, 100),
    "carbohydrates_100g": (0, 100),
    "sugars_100g":        (0, 100),
    "fiber_100g":         (0, 100),
    "proteins_100g":      (0, 100),
    "salt_100g":          (0, 100),
    "alcohol_100g":       (0, 100),
}

META_COLS_PARQUET = ["product_name", "categories", "additives_n",
                     "nutriscore_score", "nutriscore_grade", "nova_group"]


def _banner(text: str) -> None:
    print(f"\n{'='*62}\n  {text}\n{'='*62}")


def _pivot_nutriments(df_raw: pd.DataFrame) -> pd.DataFrame:
    """
    nutriments list<struct> sutununu pivot ederek flat DataFrame olusturur.
    Her satirda: product_idx (orjinal satir) + her besin icin 100g degeri
    """
    target_names = set(NUTRIENT_TARGETS.keys())
    records = []

    for idx, row_nutrients in enumerate(df_raw["nutriments"]):
        record: dict = {"_idx": idx}
        if row_nutrients is None:
            records.append(record)
            continue
        # row_nutrients: list of dicts {name, value, 100g, ...}
        for item in row_nutrients:
            if item is None:
                continue
            name = item.get("name") or ""
            val_100g = item.get("100g")  # float ya da None
            if name in target_names and val_100g is not None:
                csv_col = NUTRIENT_TARGETS[name]
                record[csv_col] = val_100g
        records.append(record)

    pivot = pd.DataFrame(records).set_index("_idx")
    return pivot


def run(input_path: str, output_path: str, sample: int | None = None) -> None:
    t0  = time.perf_counter()
    src = Path(input_path)
    dst = Path(output_path)

    if not src.exists():
        print(f"\n  HATA: Dosya bulunamadi -> {src}\n")
        sys.exit(1)

    # ── ADIM 1: Hangi meta sutunlar mevcut? ────────────────────────────────
    _banner("ADIM 1 -- Sema Tarama")
    schema     = pq.read_schema(src)
    all_schema = set(schema.names)
    print(f"  Kaynak  : {src}  ({src.stat().st_size/1e9:.2f} GB)")
    print(f"  Toplam sutun : {len(all_schema)}")

    meta_to_read = [c for c in META_COLS_PARQUET if c in all_schema]
    read_cols    = meta_to_read + ["nutriments"]
    print(f"  Okunacak sutun: {read_cols}")

    # ── ADIM 2: Parquet okuma ──────────────────────────────────────────────
    _banner("ADIM 2 -- Parquet Okuma")
    t_read = time.perf_counter()
    pf     = pq.ParquetFile(src)

    if sample:
        # Sadece ilk N satiri oku (hizli test)
        batch = next(pf.iter_batches(batch_size=sample, columns=read_cols))
        table = pa.Table.from_batches([batch])
    else:
        table = pq.read_table(src, columns=read_cols)

    df_raw = table.to_pandas()
    n_raw  = len(df_raw)
    print(f"  Ham satir     : {n_raw:,}")
    print(f"  Okuma suresi  : {time.perf_counter()-t_read:.1f} sn")
    print(f"  Bellekte      : {df_raw.memory_usage(deep=True).sum()/1e6:.0f} MB")

    # ── ADIM 3: nutriments pivot ───────────────────────────────────────────
    _banner("ADIM 3 -- Nutriments Pivot (list<struct> -> flat)")
    t_piv = time.perf_counter()
    pivot = _pivot_nutriments(df_raw)
    print(f"  Pivot suresi       : {time.perf_counter()-t_piv:.1f} sn")
    print(f"  Uretilen sutunlar  : {list(pivot.columns)}")

    # Meta + pivot birlestir
    df = df_raw.drop(columns=["nutriments"]).join(pivot)
    del df_raw, pivot
    print(f"  Birlesmis sekil    : {df.shape}")

    # ── ADIM 4: Zorunlu makro NaN filtresi ────────────────────────────────
    _banner("ADIM 4 -- Zorunlu Makro NaN Filtresi")
    req = [c for c in REQUIRED_CSV_COLS if c in df.columns]
    before = len(df)
    df     = df.dropna(subset=req)
    print(f"  Silinen (NaN makro) : {before-len(df):,}   Kalan: {len(df):,}")

    # ── ADIM 5: Meta bos satirlari sil ────────────────────────────────────
    _banner("ADIM 5 -- Meta Veri Temizligi")
    before = len(df)
    meta_drop = [c for c in ["product_name"] if c in df.columns]
    if meta_drop:
        df = df.dropna(subset=meta_drop)
    df = df[df["product_name"].str.strip().ne("") if "product_name" in df.columns else df.index.notna()]
    print(f"  Silinen (bos urun adi) : {before-len(df):,}   Kalan: {len(df):,}")

    # ── ADIM 6: Fiziksel sinir kontrolu ───────────────────────────────────
    _banner("ADIM 6 -- Aykiri Deger Filtresi")
    before = len(df)
    mask   = pd.Series(True, index=df.index)
    for col, (lo, hi) in PHYSICAL_LIMITS.items():
        if col not in df.columns:
            continue
        valid    = df[col].between(lo, hi) | df[col].isna()
        removed  = (~valid).sum()
        if removed > 0:
            print(f"  {col:<30} aykiri: {removed:>6,}")
        mask &= valid
    df = df[mask]
    print(f"\n  Toplam aykiri silinen : {before-len(df):,}   Kalan: {len(df):,}")

    # ── ADIM 7: Akilli doldurma (NaN -> 0) ────────────────────────────────
    _banner("ADIM 7 -- Akilli Doldurma (NaN -> 0)")
    impute = [c for c in IMPUTE_ZERO_CSV_COLS if c in df.columns]
    nan_n  = df[impute].isna().sum().sum()
    df[impute] = df[impute].fillna(0.0)
    print(f"  {nan_n:,} NaN degeri 0.0 ile dolduruldu ({len(impute)} sutun)")

    # ── ADIM 8: Kayit ─────────────────────────────────────────────────────
    _banner("ADIM 8 -- CSV Kayit")
    df = df.reset_index(drop=True)
    df.to_csv(dst, index=False, encoding="utf-8-sig")

    t_total = time.perf_counter() - t0
    mb_out  = dst.stat().st_size / 1e6

    # ── Final Rapor ────────────────────────────────────────────────────────
    _banner("FINAL RAPOR")
    ret = len(df) / n_raw * 100 if n_raw else 0
    print(f"  Ham satir          : {n_raw:>10,}")
    print(f"  Temiz satir        : {len(df):>10,}  ({ret:.1f}% tutuldu)")
    print(f"  Sutun sayisi       : {len(df.columns):>10,}")
    print(f"  Cikti boyutu       : {mb_out:>9.1f} MB")
    print(f"  Toplam sure        : {t_total:>9.1f} sn")
    print(f"\n  Cikti -> {dst}")

    print("\n  Basariyla cekilen besin sutunlari:")
    nutrient_cols = [c for c in NUTRIENT_TARGETS.values() if c in df.columns]
    for c in nutrient_cols:
        not_null = df[c].notna().sum()
        pct      = not_null / len(df) * 100
        print(f"    {c:<30} dolu: {not_null:>8,} ({pct:>5.1f}%)")
    print()


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore
    parser = argparse.ArgumentParser(
        description="VitaCheck Veri On Isleme v2.0 -- food.parquet -> cleaned_nutrition_data.csv"
    )
    parser.add_argument("--input",  default="food.parquet")
    parser.add_argument("--output", default="cleaned_nutrition_data.csv")
    parser.add_argument("--sample", type=int, default=None,
                        help="Sadece ilk N satiri isle (hizli test)")
    args = parser.parse_args()
    run(args.input, args.output, args.sample)


if __name__ == "__main__":
    main()

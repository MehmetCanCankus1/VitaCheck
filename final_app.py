import os
import sys
import pandas as pd
import joblib
from vision_ocr import analyze_image

# Dosya Yolları
MODEL_PATH = "nutri_model.pkl"
ENCODER_PATH = "label_encoder.pkl"

def load_assets():
    """Model ve Label Encoder'ı yükler."""
    try:
        model = joblib.load(MODEL_PATH)
        le = joblib.load(ENCODER_PATH)
        return model, le
    except Exception as e:
        print(f"Hata: Varlıklar yüklenemedi. {e}")
        sys.exit(1)

def get_risk_message(grade):
    """Nutri-Score harfine göre risk mesajını döner."""
    grade = grade.upper()
    if grade in ['A', 'B']:
        return "RİSKLİ DEĞİL (SAĞLIKLI)"
    elif grade == 'C':
        return "ORTA RİSKLİ"
    elif grade in ['D', 'E']:
        return "RİSKLİ (DİKKAT!)"
    else:
        return "BİLİNMİYOR"

def main():
    if len(sys.argv) < 2:
        print("Kullanım: python final_app.py <görsel_yolu>")
        return

    image_path = sys.argv[1]
    
    # 1. OCR Aşaması
    print(f"\n{'='*50}")
    print(f"🔍 ANALİZ BAŞLATILDI: {os.path.basename(image_path)}")
    print(f"{'='*50}")
    
    print("OCR Taraması ve Veri Ayıklama yapılıyor...")
    ocr_result = analyze_image(image_path)
    
    if ocr_result["status"] != "ok":
        print(f"❌ Hata: OCR işlemi başarısız. {ocr_result.get('message', '')}")
        return

    ocr_data = ocr_result["data"]

    # 2. Tespit Edilen Tüm Değerleri Göster
    print("\n📦 TESPİT EDİLEN TÜM BESİN DEĞERLERİ:")
    print("-" * 40)
    for key, info in ocr_data.items():
        print(f"{key:20}: {info['value']:>8} {info['unit']}")
    print("-" * 40)

    # 3. Model Tahmini İçin Veri Hazırlama
    # Modelin beklediği özellikler: energy_100g, fat_100g, sugars_100g, salt_100g
    
    energy = 0
    if "Energy_kJ" in ocr_data:
        energy = ocr_data["Energy_kJ"]["value"]
    elif "Energy_kcal" in ocr_data:
        # Model OpenFoodFacts verisiyle eğitildiyse energy_100g genelde kJ'dir.
        energy = ocr_data["Energy_kcal"]["value"] * 4.184
    
    features = {
        "energy_100g": energy,
        "fat_100g": ocr_data.get("Fat_g", {}).get("value", 0),
        "sugars_100g": ocr_data.get("Sugar_g", {}).get("value", 0),
        "salt_100g": ocr_data.get("Salt_g", {}).get("value", 0)
    }

    df_predict = pd.DataFrame([features])

    # 4. Tahmin Aşaması
    model, le = load_assets()
    prediction_idx = model.predict(df_predict)[0]
    nutri_score = le.inverse_transform([prediction_idx])[0].upper()

    # 5. Risk Analizi ve Çıktı
    risk_msg = get_risk_message(nutri_score)
    
    print("\n" + "═"*50)
    print(f"📊 NUTRI-SCORE TAHMİNİ : {nutri_score}")
    print(f"⚠️  RİSK DURUMU         : {risk_msg}")
    print("═"*50 + "\n")

if __name__ == "__main__":
    # UTF-8 ayarı (Türkçe karakterler için)
    if sys.platform == "win32":
        import io
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    
    main()

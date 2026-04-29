import pandas as pd

# CSV dosyasının yolu
file_path = "cleaned_openfoodfacts.csv"

try:
    # Veriyi yormamak için sadece ilk 10 satırı okuyoruz
    # Veride tab ayracı kullanılıyor gibi görünüyor
    df = pd.read_csv(file_path, sep='\t', nrows=10)
    
    # Tüm sütun isimlerini listele
    all_columns = df.columns.tolist()
    print("--- Tüm Sütun İsimleri ---")
    print(all_columns)
    print("\n" + "="*30 + "\n")

    # İstenen değerlerle eşleşen anahtar kelimeler
    targets = {
        "Şeker": ["sugar", "sugars"],
        "Tuz": ["salt", "sodium"],
        "Yağ": ["fat"],
        "Enerji/Kalori": ["energy", "calories", "kcal"],
        "Nutri-Score": ["grade", "score", "nutriscore"]
    }

    print("--- Eşleşen Kritik Sütunlar ---")
    for category, keywords in targets.items():
        # Sütun isimlerinde bu anahtar kelimeleri içerenleri bul
        matches = [col for col in all_columns if any(k in col.lower() for k in keywords)]
        print(f"{category}: {matches if matches else 'Bulunamadı'}")

except FileNotFoundError:
    print(f"Hata: {file_path} dosyası bulunamadı.")
except Exception as e:
    print(f"Bir hata oluştu: {e}")

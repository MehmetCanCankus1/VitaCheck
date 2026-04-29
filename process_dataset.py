import pandas as pd

# Dosya yolları
input_file = "cleaned_openfoodfacts.csv"
output_file = "final_training_data.csv"

# Sadece ihtiyacımız olan sütunlar
required_columns = [
    'product_name', 
    'energy_100g', 
    'fat_100g', 
    'sugars_100g', 
    'salt_100g', 
    'nutriscore_grade'
]

try:
    print(f"Veri okunuyor: {input_file}...")
    # Veri setini sekmelerle ayırarak ve sadece gerekli sütunları alarak oku
    df = pd.read_csv(input_file, sep='\t', usecols=required_columns)
    
    initial_count = len(df)
    print(f"Başlangıçtaki satır sayısı: {initial_count}")

    # 1. Boş (NaN) verisi olan satırları sil
    df = df.dropna()
    print(f"Boş satırlar silindikten sonra: {len(df)}")

    # 2. nutriscore_grade sütununda sadece 'a','b','c','d','e' olanları tut
    valid_grades = ['a', 'b', 'c', 'd', 'e']
    # Küçük harfe çevirip filtreleyerek hatalı verileri eliyoruz
    df['nutriscore_grade'] = df['nutriscore_grade'].str.lower()
    df = df[df['nutriscore_grade'].isin(valid_grades)]
    
    final_count = len(df)
    print(f"Hatalı Nutri-Score değerleri elendikten sonra: {final_count}")

    # 3. Sonucu virgül ayracıyla kaydet
    df.to_csv(output_file, index=False, sep=',')
    print(f"\nİşlem başarıyla tamamlandı!")
    print(f"Dosya kaydedildi: {output_file}")
    print(f"Toplam temiz veri satır sayısı: {final_count}")

except FileNotFoundError:
    print(f"Hata: {input_file} bulunamadı.")
except Exception as e:
    print(f"Hata oluştu: {e}")

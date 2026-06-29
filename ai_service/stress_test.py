import time
import requests

# Port 8001 ve doğru endpoint ayarlandı!
URL = "http://localhost:8001/generate-report" 

# api.py içindeki ReportRequest yapısına birebir uygun gerçek payload
payload = {
    "ocr_data_100g": {
        "Energy_kcal": {"per_100g": 480.0, "unit": "kcal", "confidence": 0.98},
        "Sugar_g": {"per_100g": 28.5, "unit": "g", "confidence": 0.95},
        "Salt_g": {"per_100g": 1.8, "unit": "g", "confidence": 0.92}
    },
    "portion_gram": 100.0,
    "category": "Atıştırmalık",
    "age": 52,
    "height": 172,
    "weight": 96,
    "diseases": ["Diyabet", "Hipertansiyon", "Obezite"]
}

print("=== GERÇEK VERİ İÇİN STRES TESTİ BAŞLIYOR ===")
print("İstekler sıralı olarak fırlatılıyor, kotalar zorlanıyor...\n")

for i in range(1, 35):
    baslangic = time.time()
    try:
        response = requests.post(URL, json=payload, timeout=20)
        sure = time.time() - baslangic
        
        if response.status_code == 200:
            res_data = response.json()
            # api.py'den gelen is_failover durumunu canlı okuyoruz!
            failover_durumu = res_data.get("is_failover", False)
            
            if failover_durumu:
                print(f"[İstek {i}] DURUM: 200 OK | SÜRE: {sure:.2f} sn | ⚠️ DİKKAT: Failover Tetiklendi! (Key Değişti)")
            else:
                print(f"[İstek {i}] DURUM: 200 OK | SÜRE: {sure:.2f} sn | ✅ Stabil Çalışma (Mevcut Key)")
        else:
            print(f"[İstek {i}] HATA Durum Kodu: {response.status_code} | Süre: {sure:.2f} sn")
            
    except Exception as e:
        print(f"[İstek {i}] Bağlantı Hatası: {e}")
        
    time.sleep(0.1)

print("\n=== TEST BİTTİ ===")
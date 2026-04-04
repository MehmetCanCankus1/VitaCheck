# Besin Değeri OCR Sistemi

## Proje Amacı
Bu proje, gıda ürünlerinin üzerindeki besin değerlerini (şeker, tuz, protein, yağ, kalori vb.) görsellerden otomatik olarak okumak için geliştirilmiştir.

## Kullanılan Teknolojiler
- Python
- EasyOCR
- OpenCV
- Numpy

## Çalışma Mantığı
- Görselden metin OCR ile alınır
- Satır ve sütun yapısı analiz edilir
- En doğru değerler heuristik algoritma ile seçilir
- OCR hataları (örneğin 95 → 9.5) düzeltilir

## Kurulum
pip install -r requirements.txt

## Kullanım
python main.py testgorsel.jpg

## Örnek Çıktı
{
  "sugar_g": 9.5,
  "salt_g": 0.06,
  "protein_g": 0.0,
  "fat_g": 0.0,
  "calories_kcal": 38.0
}

## Notlar
- Sistem gerçek hayat görselleri için optimize edilmiştir
- OCR hatalarına karşı düzeltme mekanizması içerir
- Geliştirmeye açıktır
📦 Veri Kaynakları

1. Gıda Veri Seti (OpenFoodFacts)

Kaynak: Kaggle - World Food Facts / Official Data

Veri Dosyası: en.openfoodfacts.org.products.tsv

Açıklama: Dünya genelindeki gıda ürünlerinin içerik ve besin değerlerini kapsayan açık kaynaklı bir veritabanıdır. OCR ile etiketlerden okunan verilerin doğrulanması ve ürün eşleştirmesi için kullanılmıştır.

2. Sağlık ve Beslenme Referansları

Dünya Sağlık Örgütü (WHO)

Sağlıklı Beslenme Rehberi (Genel): https://www.who.int/news-room/fact-sheets/detail/healthy-diet

Bulaşıcı Olmayan Hastalıkların Önlenmesi: https://www.who.int/teams/noncommunicable-diseases/diet-physical-activity-and-health

Açıklama: Sadece şeker ve tuz değil; yağ, doymuş yağ ve trans yağ gibi tüm temel besin ögeleri için küresel tüketim limitlerini ve risk kriterlerini belirlemek amacıyla referans alınmıştır.

T.C. Sağlık Bakanlığı

Sağlıklı Beslenme ve Hareketli Hayat Dairesi Başkanlığı: https://hsgm.saglik.gov.tr/tr/saglikli-beslenme-db.html

Beslenme Rehberi:beslenme.saglik

Açıklama: Türkiye'ye özgü beslenme standartları, yerel gıda tüketim rehberleri ve sağlıklı beslenme protokolleri bu resmi kaynaklardan referans alınmıştır.

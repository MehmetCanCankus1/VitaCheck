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

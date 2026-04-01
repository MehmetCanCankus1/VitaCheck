# VitaCheck - S1: Yazılım Gereksinim Analizi Belgesi

## 1. Proje Özeti
**VitaCheck**, kullanıcıların tükettikleri gıdaların içeriklerini yapay zeka desteğiyle analiz ederek, kişisel sağlık profillerine (alerji, diyet vb.) uygunluğunu denetleyen bir mobil karardır. Proje, hem bir son kullanıcı uygulaması hem de akademik bir araştırma niteliği taşımaktadır.

---

## 2. Proje Ekibi ve Rol Dağılımı
* **Yusuf (Scrum Master / AI):** Gıda etiketi OCR (Görüntü İşleme) ve NLP (Doğal Dil İşleme) modellerinin geliştirilmesi.
* **Mehmetcan (Backend):** Veritabanı yönetimi, API servisleri ve kullanıcı verilerinin güvenli depolanması.
* **Hicran (Mobile):** Kullanıcı arayüzü (UI/UX) tasarımı ve mobil uygulama geliştirme (Flutter/React Native).
* **İrem (Algoritma Analisti / Dokümantasyon):** Sağlık risk puanlama algoritmalarının tasarımı, veri standardizasyonu ve akademik raporlama .

---

## 3. Teknik Gereksinimler ve Kapsam

### 3.1. Yapay Zeka Özellikleri (AI)
* **Gıda Etiketi OCR:** Ürün paketlerindeki içerik listesinin fotoğraftan dijital metne dönüştürülmesi.
* **NLP Analizi:** Metne dönüştürülen içeriklerin analiz edilip alerjen maddelerin tespiti.

### 3.2. Karar Destek Sistemi ve Analiz 
* **Risk Puanlama:** İçerikteki şeker, tuz ve katkı maddesi oranlarına göre 1-10 arası sağlık puanı hesaplanması.
* **Profil Eşleştirme:** Kullanıcının sağlık verileri (Diyabet, Tansiyon vb.) ile ürün içeriğinin matematiksel karşılaştırılması.
* **Sağlıklı Alternatifler:** Riskli bulunan ürünler yerine yapay zeka tarafından daha sağlıklı ürün önerilmesi.

---

## 4. Kullanıcı Hikayeleri (User Stories)
### 🚀 Belirlenen User Stories (Kullanıcı Hikayeleri)

1. **Gıda Etiketi Tarama:** Bir kullanıcı olarak, marketteki ürünün içeriğini hızlıca analiz etmek için etiketin fotoğrafını çekebilmek istiyorum (Sorumlu: Yusuf).
2. **Kişisel Alerji Profili:** Bir alerjik birey olarak, profilime alerjen bilgilerimi kaydedebilmek istiyorum (Sorumlu: Hicran).
3. **Risk Puanlaması:** Bir sağlıklı yaşam takipçisi olarak, tarattığım ürünün 1-10 arası sağlık puanını görmek istiyorum (Sorumlu: İrem).
4. **Sağlıklı Alternatif Önerisi:** Bir tüketici olarak, riskli ürünler yerine sistemin bana sağlıklı alternatifler önermesini istiyorum (Sorumlu: İrem/Yusuf).
5. **Geçmiş Taramalar:** Bir kullanıcı olarak, daha önce tarattığım ürünleri geçmiş listemde görebilmek istiyorum (Sorumlu: Mehmetcan).
6. **Akademik Bilgi Doğruluğu:** Bir akademik inceleyici olarak, uygulamadaki tavsiyelerin bilimsel kaynaklarını (Harvard System) görebilmek istiyorum (Sorumlu: İrem).

---

## 5. Akademik Hedefler ve Standartlar
* **Yazım Kuralları:** Tüm dökümantasyon ve final raporu akademik makale formatında hazırlanacaktır.
* **Atıf Sistemi:** Kaynakça gösteriminde **Harvard Referans Sistemi** kullanılacaktır.
* **Sektörel Standart:** Gereksinim analizi IEEE 830 (SRS) standartlarına uygun olarak belgelenecektir.

---

## 6. Proje Takvimi (Yönetim)
Proje, GitHub Issues üzerinden takip edilen haftalık sprintler ile yönetilecektir. Görev dağılımları "To Do", "In Progress" ve "Done" şeklinde panolardan izlenecektir.

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
1. **Bir kullanıcı olarak**, marketteki bir ürünün fotoğrafını çektiğimde içeriğinin dijital olarak okunmasını istiyorum.
2. **Bir kullanıcı olarak**, fıstık alerjim olduğunu profilime kaydedip, fıstık içeren ürünlerde "Kritik Uyarı" almak istiyorum.
3. **Bir kullanıcı olarak**, sistemin bana ürünün neden riskli olduğunu bilimsel verilerle açıklamasını istiyorum.
4. **Bir kullanıcı olarak**, daha önce tarattığım ürünleri geçmiş listemde görebilmek istiyorum.

---

## 5. Akademik Hedefler ve Standartlar
* **Yazım Kuralları:** Tüm dökümantasyon ve final raporu akademik makale formatında hazırlanacaktır.
* **Atıf Sistemi:** Kaynakça gösteriminde **Harvard Referans Sistemi** kullanılacaktır.
* **Sektörel Standart:** Gereksinim analizi IEEE 830 (SRS) standartlarına uygun olarak belgelenecektir.

---

## 6. Proje Takvimi (Yönetim)
Proje, GitHub Issues üzerinden takip edilen haftalık sprintler ile yönetilecektir. Görev dağılımları "To Do", "In Progress" ve "Done" şeklinde panolardan izlenecektir.

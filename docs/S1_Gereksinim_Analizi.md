# VitaCheck - S1: Yazılım Gereksinim Analizi Belgesi 

## 1. Proje Özeti
**VitaCheck**, kullanıcıların tükettikleri gıdaların içeriklerini yapay zeka desteğiyle analiz ederek; diyabet, çölyak ve hipertansiyon gibi kronik rahatsızlıkları olan bireylerin sağlık profillerine uygunluğunu denetleyen bir mobil uygulamadır.

---

## 2. Proje Ekibi ve Rol Dağılımı
* **Mehmetcan (Scrum Master & Backend Architect):** Proje yönetimi, GitHub Projects (Kanban) yönetimi, C# .NET API geliştirme ve veritabanı mimarisi.
* **İrem (Analiz & Dökümantasyon):** Gereksinim analizi, User Story yazımı, tıbbi gıda veri setlerinin düzenlenmesi ve akademik raporlama.
* **Hicran (Frontend / Mobil Geliştirici):** Flutter arayüz tasarımı, kullanıcı deneyimi (UX) ve kamera entegrasyonu.
* **Yusuf (AI & OCR Specialist):** Python ile OCR modelinin eğitimi, metin işleme ve API entegrasyonu.

---

## 3. Kullanıcı Hikayeleri (User Stories)

1. **Diyabet Yönetimi:** Bir diyabet hastası olarak, gıda etiketindeki şeker oranını telefonumla taramak istiyorum, böylece kan şekerimi güvenli seviyede tutabilirim.
2. **Glüten Kontrolü:** Bir çölyak hastası olarak, ürünlerin glüten içerip içermediğini anında öğrenmek istiyorum, böylece sağlığımı tehlikeye atmadan alışveriş yapabilirim.
3. **Tansiyon Takibi:** Bir hipertansiyon hastası olarak, ürünlerdeki tuz (sodyum) miktarını takip etmek istiyorum, böylece tansiyonumu kontrol altında tutabilirim.
4. **Egzersiz Önerisi:** Bir kullanıcı olarak, riskli bir gıda tükettiğimde sistemden egzersiz önerisi almak istiyorum, böylece aldığım fazla kaloriyi nasıl yakacağımı bilirim.
5. **Ebeveyn Denetimi:** Bir ebeveyn olarak, paketli gıdalardaki zararlı katkı maddeleri için uyarı almak istiyorum, böylece çocuklarım için en sağlıklı ürünleri seçebilirim.
6. **Kişiselleştirilmiş Profil:** Bir kullanıcı olarak; boy, kilo ve hastalık bilgilerimi içeren bir profil oluşturmak istiyorum, böylece tüm analizlerin bana özel yapılmasını sağlarım.

---

## 4. Kabul Kriterleri (Acceptance Criteria - AC)
* **Analiz Hızı:** Sistem, net çekilmiş bir gıda etiketi fotoğrafındaki metni en geç **5 saniye** içinde analiz edip sonucu göstermelidir.
* **Okuma Doğruluğu:** OCR (Optik Karakter Tanıma) modülü, standart ışık altında metinleri en az **%85 doğrulukla** okumalıdır.
* **Görsel Uyarı:** Üründe kullanıcının hastalığına (örn. Diyabet) aykırı bir madde bulunursa, ekran belirgin bir **kırmızı renkle** uyarı vermelidir.
* **Anlık Güncelleme:** Kullanıcı boy, kilo veya hastalık bilgilerini güncellediğinde, yeni analizler anında bu verilere göre güncellenmelidir.

---

## 5. Fonksiyonel Olmayan Gereksinimler (NFR)
1. **Güvenlik:** Kullanıcıların tüm sağlık verileri ve kişisel bilgileri veritabanında **Hash (şifrelenmiş)** yöntemiyle saklanacaktır.
2. **Performans:** Uygulama, internet bağlantısı olan bir cihazda **3 saniyenin altında** açılmalı ve ana ekrana ulaşmalıdır.
3. **Kullanılabilirlik:** Arayüz, görme zorluğu çekebilecek kullanıcılar için yüksek kontrastlı renkler ve en az **14pt** font boyutu ile tasarlanacaktır.

---

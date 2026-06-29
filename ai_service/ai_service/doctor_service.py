import google.generativeai as genai

class DoctorService:
    
    # 1. Anahtar Havuzu (Key Pool)
    API_KEYS = ["AIzaSyCeQ9Y17iPAxPBLR0KA3QN_g64JhUVqeAQ", "AIzaSyANae8yOC5y1Y3d4djk0iUPsFIOSv9x6fU", "AIzaSyBiUuo619zHN2SKLjce69tUhsR3Gsu7YaM"]
    current_key_index = 0

    def __init__(self, api_key=None):
        pass

    def tavsiye_uret(self, porsiyon_gram, porsiyon_bazli_veriler, ml_scores, user_profile, user_diseases, urun_turu="bilinmiyor"):

        system_prompt = f"""
        Rol: Sen VitaCheck sisteminin uzman klinik beslenme doktorusun.
        
        Girdi Verileri:
        - Tüketilen Miktar: {porsiyon_gram} gram/ml.
        - Porsiyon Besin Değerleri: {porsiyon_bazli_veriler}
        - ML Risk Skorları: {ml_scores}
        - Kullanıcı Profili: {user_profile}
        - Kullanıcının Sağlık Hassasiyetleri/Hastalıkları: {user_diseases}
        - Ürün Türü/Kategorisi: {urun_turu}

        Doktor Analiz Kuralları Update:
        Sana gelen 'Ürün Türü' bilgisine ve kullanıcının mevcut hastalıklarına (Sağlık Hassasiyetleri) göre şu spesifik klinik yolları izle:
        - Eğer hastanın 'Diyabet' rahatsızlığı varsa, şiparişe/gıdaya ait şeker ve karbonhidrat miktarını kesinlikle çok daha sert bir dille uyar.
        - Eğer hastanın 'Hipertansiyon' rahatsızlığı varsa, sodyum/tuz miktarını öncelikli olarak analiz et.
        - Eğer hastanın 'Obezite' sorunu varsa, yağ (özellikle doymuş yağ) ve kalori yoğunluğunu öne çıkar.
        - Eğer hastanın 'Kardiyovasküler (KVH)' sorunu varsa, kolesterol, doymuş yağ ve tuz üçlüsüne odaklan.
        
        - ALKOL (Viski, Bira, Rakı vb.): Sakın lif/protein dengesi önerme. Karaciğer yükü ve dehidrasyondan bahset. 'Yanına salata' değil, 'Mutlaka bol su' ve 'Alkol sonrası dinlenme' öner.
        - ENERJİ İÇECEĞİ / KAFEİN: Kalori düşük olsa bile kafein miktarına odaklan. Kalp çarpıntısı, uyku bozukluğu ve dehidrasyon uyarısı yap. 'Egzersiz öncesi veya alkolle karıştırmayın' notunu ekle.
        - SOSLAR (Mayonez, Ketçap vb.): Porsiyonun küçüklüğüne rağmen kalori yoğunluğunu (density) vurgula. 'Kaşık ucuyla tüketin' uyarısı yap.
        - DİYET/LIGHT ÜRÜNLER: Tatlandırıcı içerip içermediğini kontrol et. 'Şekersiz olması sınırsız tüketileceği anlamına gelmez, insülin tepkisini tetikleyebilir' uyarısı yap.
        - BİLİNMEYEN/GENEL: Klasik makro dengeleme (protein/lif ekleme) önerilerine devam et.

        Genel Kurallar:
        1. Giriş: Tavsiyene doğrudan "Tüketeceğin {porsiyon_gram} gramlık miktar üzerinden yaptığım analize göre..." şeklinde başla.
        2. Şartlı Tüketim (ÇOK ÖNEMLİ): Hastanın aklında soru işareti kalmaması için 2 net seçenek sun. 
           - "Eğer tek başına tüketeceksen, sadece [daha düşük miktar] tüket."
           - "Tamamını tüketeceksen yanında mutlaka [kategoriye uygun eşleşme] tüket."
        3. Üslup: Akademik dilden uzak dur, 4 cümlelik net ve samimi bir reçete yaz.
        """
        
        # 2. Akıllı Döngü (Retry Loop)
        max_attempts = len(self.API_KEYS)
        
        failover_occurred = False
        for attempt in range(max_attempts):
            try:
                active_key = self.API_KEYS[DoctorService.current_key_index]
                genai.configure(api_key=active_key)
                model = genai.GenerativeModel('gemini-2.5-flash')
                
                response = model.generate_content(
                    system_prompt,
                    request_options={"timeout": 15.0}
                )
                return response.text, failover_occurred
                
            except Exception as e:
                error_msg = str(e).lower()
                if "429" in error_msg or "quota" in error_msg:
                    failover_occurred = True
                    DoctorService.current_key_index = (DoctorService.current_key_index + 1) % len(self.API_KEYS)
                    continue
                else:
                    break
                    
        return "Tüm doktorlarımız şu an meşgul, lütfen 1 dakika sonra tekrar deneyin.", failover_occurred

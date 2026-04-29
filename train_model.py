import pandas as pd
import joblib
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report
from sklearn.preprocessing import LabelEncoder

# Dosya yolları
data_path = "final_training_data.csv"
model_path = "nutri_model.pkl"

def train_nutriscore_model():
    try:
        print(f"Veri yükleniyor: {data_path}...")
        df = pd.read_csv(data_path)
        
        # Özellikler (X) ve Hedef (y) belirleme
        X = df[['energy_100g', 'fat_100g', 'sugars_100g', 'salt_100g']]
        y = df['nutriscore_grade']

        # LabelEncoder ile harfleri (a, b, c, d, e) sayılara çevir
        le = LabelEncoder()
        y_encoded = le.fit_transform(y)
        
        # Veriyi %80 Eğitim, %20 Test olarak ayır
        X_train, X_test, y_train, y_test = train_test_split(
            X, y_encoded, test_size=0.20, random_state=42
        )

        print(f"Model eğitiliyor (Random Forest)...")
        # Hız ve verim için n_estimators ve n_jobs ayarları
        model = RandomForestClassifier(n_estimators=100, n_jobs=-1, random_state=42)
        model.fit(X_train, y_train)

        # Tahmin ve Değerlendirme
        y_pred = model.predict(X_test)
        accuracy = accuracy_score(y_test, y_pred)
        
        print("\n" + "="*30)
        print(f"MODEL BAŞARIMI (Accuracy): %{accuracy*100:.2f}")
        print("="*30)
        
        # Sınıflandırma Raporu (Harf etiketleriyle geri çevirerek)
        print("\nSınıflandırma Raporu:")
        print(classification_report(y_test, y_pred, target_names=le.classes_))

        # Modeli ve LabelEncoder'ı kaydet (Tahmin anında harf karşılığı için ikisi de lazım olabilir)
        # Ama kullanıcı sadece pkl istediği için modeli kaydediyoruz
        joblib.dump(model, model_path)
        # LabelEncoder'ı da saklamak profesyonel yaklaşımdır
        joblib.dump(le, "label_encoder.pkl")
        
        print(f"\nModel başarıyla kaydedildi: {model_path}")
        print(f"Label Encoder kaydedildi: label_encoder.pkl")

    except FileNotFoundError:
        print(f"Hata: {data_path} dosyası bulunamadı. Lütfen önce veri temizleme adımını çalıştırın.")
    except Exception as e:
        print(f"Hata oluştu: {e}")

if __name__ == "__main__":
    train_nutriscore_model()

# Dishrate — Mobil Uygulama

Restoranları değil, **tek tek yemekleri** puanlayan bir mobil uygulama.
"Bu restoran 4 yıldız" yerine "X'teki cheeseburger 4.5" — yemek için Letterboxd mantığı.

Bu depo Flutter istemcisidir. API: [dishrate-backend](https://github.com/emirergorun/dishrate-backend)

---

## Teknolojiler

| Katman | Teknoloji |
|---|---|
| Framework | Flutter (Dart) |
| State yönetimi | Riverpod |
| HTTP | Dio (JWT interceptor + otomatik token yenileme) |
| Harita | flutter_map + OpenStreetMap |
| Güvenli depolama | flutter_secure_storage |
| Görsel | image_picker, cached_network_image |

---

## Ekranlar

- **Keşfet** — puan/kategoriye göre türetilmiş 6 raf, kategori filtreleri
- **Ara** — yemek, restoran ve kategori araması (Türkçe karakter duyarsız) + harita; işarete dokununca önizleme kartı
- **Restoran** — menü, menü içi arama, puana veya değerlendirme sayısına göre sıralama
- **Puan ver** — 3 adımlı akış: restoran → menü öğesi → puan, yorum ve isteğe bağlı fotoğraf
- **Günlüğüm** — tüm değerlendirmelerin; sıralama, kategori filtresi, kaydırarak silme, düzenleme (fotoğraf dahil)
- **Profil** — favoriler (en yüksek 5), istek listesi, profil fotoğrafı, ayarlar
- **Yorumlar** — bir ürünün tüm değerlendirmeleri; isimler gizlilik için maskeli (`E*** E***`)

Restoran sahipliği, menü yönetimi ve admin işleri uygulamada yok; web paneline taşınacak.

Karanlık ve aydınlık tema desteklenir (cihaz ayarına uyar).

---

## Kurulum

### Gereksinimler
- Flutter SDK 3.x
- Çalışan [dishrate-backend](https://github.com/emirergorun/dishrate-backend)

```bash
flutter pub get
flutter run
```

### API adresini ayarlama

Varsayılan `http://localhost:8080/api/v1` (web ve iOS simülatörü için doğru).
Farklı bir hedefte çalıştırmak için derleme sırasında verin:

```bash
# Android emülatör
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1

# Fiziksel cihaz (bilgisayarınızın LAN IP'si)
flutter run --dart-define=API_BASE_URL=http://192.168.1.42:8080/api/v1
```

IP yerine bilgisayarın Bonjour adını (`http://ADINIZ.local:8080/api/v1`) verirseniz
modem yeni bir IP dağıttığında derlemeyi tekrarlamanız gerekmez.

### iOS cihazına yükleme

Fiziksel iPhone'a yüklemek için Apple Geliştirici Takım Kimliğiniz gerekir.
Kişisel bilgi olduğu için depoda tutulmaz — örnek dosyayı kopyalayıp doldurun:

```bash
cp ios/Flutter/Signing.xcconfig.example ios/Flutter/Signing.xcconfig
```

Takım kimliğinizi Xcode > Settings > Accounts altında Apple ID'nizin yanında
bulabilirsiniz. Kopyaladığınız dosya `.gitignore`'dadır.

Simülatör ve web derlemeleri imzalama gerektirmez, bu adım olmadan da çalışır.

> Debug derlemesi fiziksel iOS cihazında ana ekrandan açılmaz — Dart JIT'i
> hata ayıklayıcı bağlıyken çalışabildiği için iOS uygulamayı sonlandırır.
> Cihazda bağımsız test için `--release` (veya `--profile`) kullanın.

---

## Mimari

Özellik bazlı klasörleme; altyapı ve ekranlar ayrı:

```
lib/
├── core/                 Altyapı (ekran içermez)
│   ├── auth/               Oturum state'i (Riverpod) + token saklama
│   ├── network/            Repository katmanı — tüm API çağrıları burada
│   ├── constants/          Endpoint adresleri, yapılandırma
│   └── theme/              Renkler, tipografi, tema
├── features/             Her özellik kendi klasöründe (ekran + widget)
│   ├── discover/  search/  diary/  profile/  rating/
│   └── reviews/  restaurant/  auth/  settings/
└── shared/
    ├── models/             API yanıtlarını karşılayan modeller
    └── widgets/            Ortak bileşenler (ana iskelet, alt menü)
```

**Veri akışı:** Ekran → Repository → Dio (JWT otomatik eklenir) → API

Token süresi dolduğunda Dio interceptor'ı refresh token ile sessizce yeniler ve isteği tekrarlar; kullanıcı bir şey fark etmez.

---

## Durum

Aktif geliştirme aşamasında. Tamamlananlar: kimlik doğrulama, keşfet/arama/harita, puanlama akışı, günlük, profil, değerlendirme fotoğrafları, görsel yükleme.

Sırada: hesap silme, şifre sıfırlama ve e-posta doğrulama, mağaza yayını.

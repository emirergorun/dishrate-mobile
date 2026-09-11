# Frontend devir notu

Bu dosya, arayüz yeniden tasarımına başlayan oturum içindir. Amacı iki şey:
neyin serbest olduğunu, neye dokunulmayacağını söylemek.

Son güncelleme: 10 Eylül 2026

---

## Uygulama nedir

**Dishrate** — restoranları değil, **tek tek yemekleri** puanlayan bir uygulama.
Letterboxd'un film yerine yemekle çalışan hâli. MVP İstanbul odaklı, henüz
yayında değil, kullanıcısı yok.

Çekirdek döngü şu ve uygulamanın tamamı sayılır:

```
Keşfet → yemeğe dokun → Değerlendir (3 adım) → puan + yorum
```

Geri kalan her şey (profil, günlük, harita, admin, restoran sahipliği) bu
döngünün destekçisidir. Tasarım bütçesi buna göre dağıtılmalı.

## Yığın

- **Flutter** (Material 3), durum yönetimi **Riverpod** (`StateNotifierProvider`)
- Backend: Spring Boot + PostgreSQL, ayrı repo (`dishrate-backend`)
- Bu oturumda backend kaynağı **yok** ve gerekmiyor — API sözleşmesi Dart
  tarafında zaten yazılı: `lib/shared/models/` ve `lib/core/network/`

22 ekran var. En büyükleri: `profile_screen.dart` (2510 satır),
`diary_screen.dart` (1180), `search_screen.dart` (987),
`discover_screen.dart` (879).

---

## Mevcut tasarım sistemi

Dört dosya, hepsi `lib/core/theme/` altında. **Renk ve font hiçbir ekranda elle
yazılmaz**, buradan okunur:

| Dosya | Ne tutar |
|---|---|
| `app_colors.dart` | Palet + `context.bgColor` gibi temaya duyarlı erişimciler |
| `app_text_styles.dart` | Tipografi ölçeği (stillerin çoğu renksiz, rengi ekran verir) |
| `app_fonts.dart` | Font ailesi **ve** ağırlık adları — tek anahtar noktası |
| `app_metrics.dart` | Köşe yuvarlaklığı (`AppRadius`), boşluk (`AppSpace`), hareket süresi (`AppMotion`) |

Marka turuncusu `#FF6B35`, yıldız sarısı `#FFC107`. Logo bu ikisini kullanıyor,
palet logodan türetildi. Kurallar:

- Turuncu yalnızca ana eylemde (Değerlendir, +, seçili sekme). Turuncu dolgu
  üstündeki yazı **koyu** (`AppColors.onPrimary`) — beyaz yazı 2.8:1 kalıyordu.
- Puan **rakamları** metin renginde; sarı yalnızca yıldız glifinde.
- Ekranda `AppColors.surface` gibi sabit değil `context.surfaceColor` gibi
  erişimci kullan. Açık temada küçük turuncu yazı için `context.accentTextColor`,
  yıldız için `context.starColor`, panel zemini için `context.sheetColor`.
  Eski ekranlarda sabitler hâlâ duruyor; taşındıkça kalkacak.

`AppFonts` kasıtlı olarak ağırlıkları da adlandırıyor (`display`, `heading`,
`title`, `body`). Sebebi: Poppins ve Urbanist aynı sayısal ağırlıkta farklı
kalınlıkta çiziyor. Ekranlarda `FontWeight.w600` yazmak yerine
`AppFonts.title` yazılıyor ki font değişince skala tek yerden kaysın.

Ortak bileşenler `lib/shared/widgets/` altında: `DishPhoto` (önbellekli
fotoğraf), `DishSheet` (yemek paneli), `ReviewTile`, `StarGlyph`/`StarRow`/
`RatingInline`, `StateMessage` (boş/hata), `SkeletonPulse`/`SkeletonRows`,
`Pressable` (basılma geri bildirimi). İkonlar **Tabler**
(`flutter_tabler_icons`). Phosphor denendi ama paketi Flutter 3.44 ile
derlenmiyor (`IconData` artık `final`).

### Açık/koyu tema

İkisi de destekleniyor. **Bir renk yalnızca tek temada tanımlıysa hatadır.**
Fotoğraf üzerine yazılan metinler için ayrı stiller var (`AppTextStyles.onImage*`)
— bunların rengi bilerek sabittir, çünkü altlarındaki degrade her iki temada da
koyu. Buraya tema rengi miras alan bir stil koyulursa açık modda yazı siyaha
döner ve okunmaz olur. Bu hata bir kez yaşandı ve düzeltildi.

---

## DOKUNULMAYACAKLAR

Aşağıdakiler görsel değil **davranış**. Hepsi gerçek cihazda tespit edilmiş
hatalardan doğdu; her birinin kodda *neden* öyle yazıldığını anlatan yorumu var.
Yeniden tasarım bunları koruyarak yapılmalı.

| Konu | Nerede | Neden |
|---|---|---|
| Klavye açılınca panelin küçülmesi | `shared/widgets/rating_sheet.dart` | Sabit yükseklikte yorum alanı klavyenin altında kalıyordu. Üç ekran bu paneli paylaşıyor |
| Kaydırınca klavyenin kapanması | `rating/screens/step3_rate_item.dart` | `keyboardDismissBehavior: onDrag` — yoksa klavyeden kurtulmanın yolu yok |
| Görsel üstü metin renkleri | `core/theme/app_text_styles.dart` | Açık modda kontrast hatası |
| Boş yıldızın çerçeveli olması | `rating/screens/step3_rate_item.dart`, çizimi `shared/widgets/rating_stars.dart` (`StarGlyph`) | Soluk dolgu koyu temada zeminle kayboluyordu |
| Türkçe alfabe sıralaması | `core/utils/turkce.dart` | `List.sort()` Ç/Ğ/İ/Ö/Ş/Ü'yü Z'den sonraya atıyor |
| Türkçe büyük harf | aynı dosya (`Turkce.buyuk`) | `toUpperCase()` "Diğer"i DIĞER yapıyor |
| GPS izninin **açılışta sorulmaması** | `discover/screens/discover_screen.dart` | iOS izin penceresi ömür boyu bir kez açılıyor. Kullanıcı faydasını görmeden reddederse şans kalıcı olarak gidiyor. İzin, konuma dokunulduğunda isteniyor |
| Konum izni yokken haritanın engellenmemesi | `search/screens/map_full_screen.dart` | Restoran koordinatları sunucudan geliyor; harita kullanıcının yerini bilmeden de çalışır |
| Elle il/ilçe seçiminin GPS tarafından ezilmemesi | `discover/providers/location_provider.dart` | Kullanıcı seçtiyse `source = manual`, sessiz GPS tazelemesi devreye girmez |
| Profil fotoğrafında önceki çerçeveleme | `shared/widgets/image_crop_dialog.dart` | Kütüphane ölçeği dışarı açmıyor; ölçüp düzelten iki aşamalı bir çözüm var. Kırılgan, dikkatli ol |

Bu listedeki bir davranışı bilerek değiştirmen gerekiyorsa önce sor.

---

## Bekleyen kararlar

**Font.** Arayüz **Urbanist**; logo yazısı "dishrate" Poppins SemiBold olarak
kaldı (`AppFonts.wordmark`, arayüz fontundan bağımsız). Urbanist'te Türkçe
harflerin tamamı var ve fi/fl bitişik harfi yok. "Fazla kalın" şikâyeti için
skaladan 900 ve 700 çıkarıldı, en ağır seviye 600. Geist denendi, karşılaştırma
için `assets/fonts/` altında duruyor. Kodu değiştirmeden karşılaştırmak için:

```bash
flutter run --dart-define=APP_FONT=Geist          # Geist
flutter run --dart-define=APP_FONT=Poppins        # Poppins (skala ona göre inceliyor)
```

Kalıcı hâle getirmek ya da geri almak `app_fonts.dart` içinde tek satır.
Eski `LIGHT_WEIGHTS` bayrağı kaldırıldı; incelik artık varsayılan.

**Logo.** Bilinçli olarak ertelendi. Mevcut logo (tabak + yıldız, turuncu)
yerinde kalacak. `assets/branding/` altındaki 6 PNG ile ikon/açılış ekranı
üretiliyor. Logoyu değiştirme, palet de logodan geliyor.

**Restoran sahipliği.** Az önce claim modeline geçirildi: katalogdaki restoran
sahipsiz doğar, kullanıcı sahiplik talep eder, admin onaylar. İlgili ekranlar
`features/owner/`. Bu mekanik hâlâ tartışmaya açık — büyük UI yatırımı yapma.

---

## Çalışma kuralları

- **Serbest:** tema, renk tonları, boşluk/ritim, tipografi ölçeği, bileşen
  biçimleri, ikonografi, animasyon, ekran düzeni, bilgi hiyerarşisi
- **Serbest değil:** yukarıdaki davranış listesi, API çağrıları, model alanları
- **Kapsam dışı:** yeni alan veya yeni endpoint gerektiren her şey. O backend
  işidir, ayrı oturuma gider

Değişiklikten sonra `flutter analyze` temiz olmalı (şu an 0 hata, 0 uyarı).

Kod yorumları Türkçe ve "ne" değil "neden" anlatıyor. Aynı üslubu sürdür.

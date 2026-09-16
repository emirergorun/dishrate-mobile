# Dishrate yol haritası

16 Eylül 2026 tarihli duruma göre yazıldı. Yayına kadar olan bütün işler burada; ertelenen konular da dahil.

Süreler tek geliştiricinin yarım gün çalışmasına göre kabaca verildi. "gün" = çalışma günü.

---

## Bugünkü durum

### Çalışanlar
- **Backend:** Spring Boot 3.3 / Java 17 / PostgreSQL (Docker). JWT ile oturum (erişim 1 saat, yenileme 60 gün). Kayıt, giriş, kullanıcı, restoran, menü, kategori, puan, istek listesi, bildirim, dosya yükleme, sahiplik talebi ve admin uç noktaları. Keşfet akışı sunucuda (konuma ve kategoriye göre bölümler, sayfalı "Tümünü gör"). Arama sunucuda (yemek + restoran + kategori, Türkçe karakter duyarsız). Restoranın türü menüsündeki çoğunluk kategoriden hesaplanıyor.
- **Sahte veri:** 200 restoran, ~1450 yemek, 150 kullanıcı, ~12.500 puan; yemek adına göre seçilmiş gerçek fotoğraflar. `app.seed.mock` ile tek satırda açılıp kapanıyor, `app.seed.mock.wipe` ile siliniyor.
- **Mobil:** Flutter + Riverpod. Giriş/kayıt, keşfet, arama, harita, günlük, profil, restoran sayfası, yemek paneli, üç adımlı değerlendirme akışı (fotoğraflı), istek listesi, bildirimler, ayarlar, açık/koyu tema.
- **Test:** Cihazda elle test edilen alanlar `TEST_DURUMU.md` dosyasında.

### Eksikler (bu haritanın konusu)
Şifre sıfırlama ve e-posta doğrulama yok · hesap silme yok · web sitesi yok · sunucu yayında değil, yalnızca yerel ağda ve şifresiz HTTP · yüklenen görseller sunucunun diskinde · harita altlığı anahtarsız OSM · otomatik test ve CI yok · hata izleme yok · logo kesinleşmedi · mağaza hazırlığı hiç başlamadı.

---

## Faz 0 — Toparlama (1–2 gün)

| # | İş | Neden | Bitti sayılır |
|---|---|---|---|
| 0.1 | Bekleyen değişiklikleri commit'leyip push'la (mobil ~30, backend ~24 dosya) | İki gündür biriken iş tek yerde durmasın | İki repoda da temiz çalışma alanı |
| 0.2 | Sahiplik, owner paneli ve admin panelini uygulamadan kaldır | Karar verildi: bu işler web'e taşınıyor. Uygulama sadeleşir, iki kitleye birden hizmet etmeyi bırakır | İlgili ekranlar ve profil girişleri silindi; backend uç noktaları duruyor |
| 0.3 | Ölü kodu temizle (`getAllMenuItems`, kullanılmayan mock katmanı, artık çağrılmayan yardımcılar) | Her tasarım değişikliğinde bakılan dosya sayısı azalsın | `flutter analyze` temiz, kullanılmayan tanım yok |
| 0.4 | `CLAUDE.md` / README güncelle: kurulum, sahte veri anahtarları, çalıştırma komutları | Yeni bir sohbete ya da makineye geçince zaman kaybı olmasın | Sıfırdan kurulum yazıyı takip ederek yapılabiliyor |

## Faz 1 — Ürünü MVP olarak tamamlama (5–8 gün)

| # | İş | Neden | Bitti sayılır |
|---|---|---|---|
| 1.1 | **Hesap silme** (uygulama içinden, kalıcı) | Apple, hesap açtıran uygulamalarda uygulama içi hesap silmeyi zorunlu tutuyor. Olmadan yayın reddedilir | Profil → hesabı sil; sunucuda kullanıcı ve kişisel veriler siliniyor, puanlar anonimleşiyor ya da siliniyor |
| 1.2 | Kalan ekranların yeni tasarım diline tam geçişi (profil, günlük, bildirimler) | Şu an yalnızca renk katmanı taşındı; iskelet, boş durum ve hata bileşenleri eski | Üç ekran da ortak bileşenleri kullanıyor |
| 1.3 | Hata ve boş durumların gözden geçirilmesi (her ekran, bağlantı yokken) | Sunucuya ulaşılamadığında bazı ekranlar boş kalıyor | Her listede: yükleniyor, boş, hata + tekrar dene |
| 1.4 | Erişilebilirlik turu: dokunma alanları, etiketler, kontrast, yazı ölçeği | Mağaza incelemesi ve gerçek kullanım | 44 pt altı dokunma hedefi yok; büyük yazı ölçeğinde kırılma yok |
| 1.5 | Metin turu: Türkçe tutarlılık, büyük/küçük harf, kısaltmalar | Ürünün "derli toplu" hissi | Tek elden geçmiş metinler |
| 1.6 | Bildirimlerin gerçek içerikle çalışması (okundu durumu, boş durum) | Şu an yarım | Bildirim gelince rozet, okununca temizleniyor |

## Faz 2 — Altyapı: alan adı, sunucu, e-posta, depolama (6–10 gün)

Sıra önemli: alan adı olmadan e-posta ve web olmaz.

| # | İş | Neden | Bitti sayılır |
|---|---|---|---|
| 2.1 | Alan adı al (dishrate.com vb.) + DNS | Her şeyin önkoşulu | Alan adı bizde, DNS yönetiliyor |
| 2.2 | Sunucu ortamı: yönetilen platform (Railway, Render, Fly.io) ya da VPS (Hetzner) + Docker | Şu an backend yalnızca senin bilgisayarında | Uygulama internetten erişilebilir |
| 2.3 | HTTPS (Let's Encrypt / platformun kendi sertifikası) | Şu an şifresiz HTTP; token'lar açıkta gidiyor | Tüm trafik TLS üzerinden |
| 2.4 | Yönetilen PostgreSQL + otomatik yedek + **geri yükleme provası** | Yedek, geri yüklenmeden yedek sayılmaz | Yedekten dönüş bir kez denendi |
| 2.5 | Görsel depolama: S3 uyumlu depolama (Cloudflare R2, S3) + CDN | Yüklenen fotoğraflar şu an sunucu diskinde; sunucu değişirse gider | Yeni yüklemeler bulutta, eski dosyalar taşındı |
| 2.6 | E-posta sağlayıcısı + SPF/DKIM/DMARC | Şifre sıfırlama ve doğrulama için | Test maili spam'e düşmeden ulaşıyor |
| 2.7 | **Şifremi unuttum** akışı (sunucu + web sayfası) | Şu an şifresini unutan kullanıcı hesabını kaybediyor | Tek kullanımlık, süreli bağlantı; şifre değişince oturumlar düşüyor |
| 2.8 | E-posta doğrulama | Sahte hesapları azaltır | Kayıt sonrası mail gidiyor, `email_verified` işaretleniyor |
| 2.9 | Hız sınırı (giriş, kayıt, mail, puan) | Kötüye kullanım ve mail bombardımanı | Sınır aşılınca 429, log'da görünüyor |
| 2.10 | Web sitesi: tanıtım, gizlilik politikası, kullanım şartları, şifre sıfırlama sayfası | Mağaza bu sayfaları istiyor; şifre sıfırlama zaten web'de olacak | Sayfalar yayında |
| 2.11 | İşletme paneli (web): sahiplik başvurusu, menü yönetimi, admin onayları | Uygulamadan kaldırılan işler buraya taşınıyor | Bir restoran baştan sona web'den yönetilebiliyor |
| 2.12 | Harita sağlayıcısı: anahtarlı servise geçiş (MapTiler vb.), anahtar ortam değişkeninde | OSM yayında yoğun kullanıma izin vermiyor | Açık/koyu temada kareler geliyor, anahtar repoda değil |
| 2.13 | Sır yönetimi: tüm anahtarlar ortam değişkeni, repoda sır yok | Güvenlik | Repoda arama ile sır bulunmuyor |

## Faz 3 — Kalite güvencesi (4–6 gün)

| # | İş | Neden | Bitti sayılır |
|---|---|---|---|
| 3.1 | Backend testleri: servis katmanı + uç nokta testleri (Testcontainers ile gerçek Postgres) | Elle test her seferinde aynı şeyleri tekrarlatıyor | Kritik akışlar (kayıt, giriş, puan, arama, akış) testli |
| 3.2 | Flutter testleri: model ve mantık birim testleri + kritik ekranlarda widget testi | Aynı sebep | Değerlendirme akışı ve keşfet testli |
| 3.3 | CI: GitHub Actions (analyze + test + derleme) | Push'ta bozulan şeyi hemen görmek | Her push'ta yeşil/kırmızı |
| 3.4 | Güvenlik gözden geçirmesi: yetki matrisi, girdi doğrulama, bağımlılık taraması | Yayın öncesi zorunlu | Bilinen açık yok, bağımlılıklar güncel |
| 3.5 | Performans: sorgu indeksleri, N+1 kontrolü, görsel boyutları, açılış süresi | 1450 yemekte sorun yok ama gerçek veride büyür | Ana sorgular indeksli; açılış 2 sn altında |
| 3.6 | Hata izleme: Sentry (mobil + sunucu) ve uptime kontrolü | Kullanıcı hatayı bildirmez, terk eder | Çökme ve 500'ler panele düşüyor |

## Faz 4 — Mağaza hazırlığı (4–6 gün)

| # | İş | Neden | Bitti sayılır |
|---|---|---|---|
| 4.1 | **Logo kararı** ve marka varlıklarının son hali | Ertelendi; mağaza görselleri buna bağlı | İkon, açılış, yazılı logo tek kaynaktan üretildi |
| 4.2 | Uygulama ikonu, açılış ekranı, mağaza ekran görüntüleri, tanıtım metni, anahtar kelimeler | App Store girişi | Tüm görseller doğru ölçülerde hazır |
| 4.3 | Gizlilik politikası + kullanım şartları + App Privacy beyanı (hangi veriyi topluyoruz) | Zorunlu | Sayfalar yayında, beyan formu dolduruldu |
| 4.4 | Apple Developer hesabı, sertifikalar, App Store Connect kaydı | Yayın için şart | Uygulama kaydı açık |
| 4.5 | TestFlight ile kapalı test (5–10 kişi) | Gerçek kullanıcıda ilk temas | Geri bildirimler toplandı, kritikler düzeltildi |
| 4.6 | Android kararı: aynı anda mı, sonra mı? Play Console, imzalama, cihaz testi | Flutter zaten iki platformu derliyor ama test edilmedi | Karar verildi; seçilen platform test edildi |
| 4.7 | Yayın öncesi test turu: `GELECEK_TESTLER.md` (S, Y, L, P maddeleri) | Ertelenen her şey burada toplandı | Liste tamamlandı |

## Faz 5 — Yayın (2–3 gün + bekleme)

| # | İş | Neden | Bitti sayılır |
|---|---|---|---|
| 5.1 | Sahte veriyi kapat, gerçek içerik stratejisi | Boş uygulamaya kullanıcı gelmez. Karar: ilk restoranları kim, nasıl girecek? | İlk şehir için yeterli gerçek içerik var |
| 5.2 | Üretim yapılandırması: `app.seed.*=false`, loglar, admin hesabı, yedekler | Yayın hijyeni | Üretimde sahte veri yok |
| 5.3 | Mağaza incelemesine gönder, red gelirse düzelt | — | Uygulama yayında |
| 5.4 | İlk hafta izleme: çökme, hata, kullanım | Sorunu kullanıcıdan önce görmek | Panel takip ediliyor |

## Faz 6 — Yayın sonrası (sıralama kullanıcıdan gelene göre)

| # | İş | Not |
|---|---|---|
| 6.1 | Aynı yemeği tekrar puanlama (ziyaret geçmişi) | Ertelendi. Ortalama hesabı kullanıcı başına ağırlıklandırılmalı |
| 6.2 | Sosyal katman: takip, arkadaş akışı, profil paylaşımı | Letterboxd'un asıl bağlayıcı kısmı |
| 6.3 | İşletmenin yoruma cevabı | Web panelinden |
| 6.4 | Push bildirim | Şu an yalnızca uygulama içi bildirim var |
| 6.5 | Öneri ve kişiselleştirme | Yeterli veri biriktikten sonra |
| 6.6 | Yeni şehirler, çoklu dil | İstanbul dışına çıkarken |

---

## Ertelenenlerin izi

| Konu | Nerede kayıtlı | Hangi faz |
|---|---|---|
| Sahiplik ve admin akışlarının testi | `GELECEK_TESTLER.md` · S | 2.11 (web) |
| Admin/owner ekranlarının teması | `GELECEK_TESTLER.md` · Y | 0.2 ile kalkıyor |
| Logo kontrolleri | `GELECEK_TESTLER.md` · L | 4.1 |
| Harita sağlayıcısı, sahte verinin kapatılması, e-posta akışları | `GELECEK_TESTLER.md` · P | 2.12, 5.2, 2.7–2.9 |
| Çoklu değerlendirme | Bu dosya | 6.1 |
| Alt menüde dolu simge tutarlılığı | `TEST_DURUMU.md` | 1.2 |

## Riskler

- **İçerik soğuk başlangıcı:** Gerçek restoran ve puan olmadan uygulama boş. En büyük risk bu; 5.1 sadece teknik iş değil.
- **Tek geliştirici:** Faz 2 ve 3 sıkıcı ama atlanınca yayın sonrası pahalıya patlar.
- **Mağaza reddi:** En sık sebepler hesap silme (1.1), gizlilik beyanı (4.3) ve boş/yarım içerik.
- **Maliyet:** Alan adı, sunucu, depolama, harita ve e-posta aylık gider yaratır. Faz 2'de toplam aylık gideri hesapla.
- **E-posta itibarı:** DNS kayıtları eksikse mailler spam'e düşer, şifre sıfırlama işe yaramaz.

## Karar bekleyenler

1. Logo (Faz 4.1'den önce)
2. Android aynı anda mı çıkacak (Faz 4.6)
3. Sunucu sağlayıcısı ve aylık bütçe (Faz 2.2)
4. İlk içerik nasıl girilecek (Faz 5.1)
5. Uygulama adı ve alan adı (Faz 2.1)

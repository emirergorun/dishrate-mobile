# Gelecek testler

Şu anki test turundan çıkarılan maddeler. İlgili iş sırası gelince test edilecek.

## S · Restoran sahipliği (arayüzde hiç denenmedi)

Admin ve sahiplik işleri sonraya bırakıldı.

| # | Kontrol | Beklenen |
|---|---|---|
| S1 | Profil → "Restoranımı Sahiplen" | Arama ekranı açılıyor |
| S2 | Restoran ara → "Benim" → onayla | Talep gönderiliyor |
| S3 | "Sahiplik Taleplerim" | Talep "İnceleniyor" olarak görünüyor |
| S4 | Aynı restoranı tekrar talep et | Anlaşılır hata mesajı |
| S5 | Admin hesabıyla → Talepler | Talep listede, detay açılıyor |
| S6 | Talebi onayla | Kullanıcı owner oluyor, "Restoranım" erişilebilir |
| S7 | Başka bir talebi reddet (not yazarak) | Kullanıcı tarafında red sebebi görünüyor |

## Y · Admin ve owner ekranlarında tema

| # | Kontrol | Beklenen |
|---|---|---|
| Y1 | Açık temada admin paneli | Metinler okunur, soluk ya da koyu leke yok |
| Y2 | Açık temada owner paneli ve restoran yönetimi | Metinler okunur, soluk ya da koyu leke yok |
| Y3 | Açık temada sahiplik talebi durum ekranı | Durum renkleri ve metinler okunur |

## P · Yayın öncesi

| # | Kontrol | Beklenen |
|---|---|---|
| P1 | Harita: geliştirmede anahtarsız OpenStreetMap kullanılıyor, yayında yoğun trafiğe izin yok. Anahtarlı sağlayıcı (MapTiler, Stadia vb.) seçildi, API anahtarı koda değil ortam ayarına kondu (`shared/widgets/map_tiles.dart`) | Açık ve koyu temada kareler yükleniyor, atıf satırı doğru, anahtar repoda yok |
| P2 | Sahte veri kapalı (`app.seed.mock=false`) | Wikimedia fotoğrafları ve mock kullanıcılar yayında yok |
| P3 | Şifremi unuttum: e-posta iste → gelen bağlantıyla yeni şifre | Bağlantı tek kullanımlık, süresi dolunca çalışmıyor; kayıtlı olmayan adreste de aynı mesaj çıkıyor |
| P4 | Kayıt sonrası doğrulama e-postası | Posta kutusuna düşüyor (spam değil), bağlantı hesabı doğrulanmış işaretliyor |
| P5 | Aynı adrese arka arkaya istek | Sınırlamaya takılıyor, mail bombardımanı olmuyor |

## L · Logo (son logo seçilince)

Logo kararı yayın öncesine bırakıldı. Şu anki turda yalnızca logonun bozuk olmadığına bakılıyor.

| # | Kontrol | Beklenen |
|---|---|---|
| L1 | Ana ekranda uygulama ikonu | Yeni logo, küçük boyutta da seçilebiliyor |
| L2 | Açık ve koyu temada yazılı logo | İki temada da okunur, doğru renk sürümü kullanılıyor |
| L3 | Açılış ekranı (iOS ve Android 12+) | Logo ortalı, zemin rengiyle uyumlu |
| L4 | Mağaza görselleri ve bildirim ikonu | Yeni logoyla güncel |

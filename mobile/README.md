# Easy Pomodoro / Easy Productivity (Flutter)

Çevrimdışı, hesapsız Pomodoro + alışkanlık mobil uygulaması.
Neo-terracotta soft UI (Tasarımcı).

## Çalıştırma

```bash
cd mobile
flutter pub get
flutter run            # bağlı cihaz / emülatör
```

Windows örneği:

```powershell
cd C:\Users\AFU\Desktop\DEV\easy-pomodoro\mobile
C:\flutter\bin\flutter.bat pub get
C:\flutter\bin\flutter.bat run -d emulator-5554
```

Emülatör kapalıysa:

```powershell
C:\AndroidSDK\emulator\emulator.exe -avd IndieValley_Pixel_8
```

Geliştirme bayrakları (`--dart-define`):

| Bayrak | Ne yapar |
|--------|----------|
| `SEED_DEMO=true` | Boş depoya örnek görev / alışkanlık / oturum ekler |
| `SURFACE_STYLE=neo\|skeuo\|glass` | Açılışta yüzey stilini zorlar |
| `INITIAL_ROUTE=/settings` | Açılış sekmesi |

## Testler

```bash
flutter analyze
flutter test
```

## Sekmeler

- **Timer** — odak / kısa mola / uzun mola
- **Alışkanlıklar** — CRUD, günlük toggle, streak, haftalık hedef
- **Geçmiş** — bugün + son 7 gün odak oturumları
- **Görevler** — CRUD, tahmini pomodoro, alışkanlık bağlama (alt menüdeki **+** yeni görev açar)
- **Ayarlar** — yüzey stili, renk paleti, süreler, otomatik başlat, ses, bildirim, tema, wakelock

## Yüzey stilleri (neo / skeuo / glass)

`lib/core/theme/app_surface_style.dart` tek kaynaktır.

- `AppSurfaceStyle` bir **karışımdır** (neo, skeuo, glass ağırlıkları). Tema
  animasyonu sırasında `lerp` ara karışımlar üretir; tüm dekorasyonlar
  `BoxDecoration.lerp` ile harmanlanır → stil değişimi yarıda “atlamaz”, akıcı
  biçimde dönüşür.
- Dolgu her zaman `LinearGradient` (düz renk = iki duraklı gradyan), kenarlık her
  zaman `Border.all` — böylece ara karelerde opaklık düşmez, köşeler bozulmaz.
- Sayfa arka planı uygulama kökünde **tek** yerde çizilir (`AppBackdrop`: palet
  zemini + cam “wash” katmanı). Scaffold’lar şeffaftır; stil değişince
  `bg → transparent` renk geçişinden kaynaklanan gri parlama oluşmaz.
- Bulanıklık `SurfaceBlur` ile yapılır; widget ağacı her stilde aynıdır
  (`BackdropFilter.enabled`), bu yüzden geçişte ekranlar yeniden kurulmaz.
- Yüksek kontrast açıkken cam yüzeyler opak yedek dolguya geçer.

## Fontlar

DM Sans ve Fraunces `assets/google_fonts/` altında paketlenmiştir (SIL OFL 1.1,
lisans dosyaları aynı klasörde). `GoogleFonts.config.allowRuntimeFetching = false`
olduğu için ilk açılış internet gerektirmez.

## Not

Monorepodaki Expo `apps/mobile`, web ve desktop uygulamalarına dokunulmaz.
Android label: **Easy Pomodoro**. MaterialApp title: **Easy Productivity**.

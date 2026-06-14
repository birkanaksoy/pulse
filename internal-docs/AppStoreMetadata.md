# Pulse — App Store Connect Metadata

Fields to paste into App Store Connect → App Information / Localizations.
Keep promo text under 170 chars, subtitle under 30 chars, keywords under 100 chars (comma-separated, no spaces after commas).

## English (en-US) — primary

- **Name:** Pulse — Phone Cleaner & Health
- **Subtitle:** Real cleaning. Honest data.
- **Promotional text:** Know your phone's health in seconds. Real iOS signals only — no fake battery cycles, no guessed metrics.
- **Keywords:** phone health,battery health,storage cleaner,system monitor,performance scanner,phone diagnostic,device care,pulse,iphone health
- **Description:**

> Pulse is a phone health scanner that shows only what iOS actually publishes — no guessed battery cycles, no invented metrics. Storage, thermal state, charge level, charging state, Low Power Mode: real iOS signals, weighted into a single Pulse Score from 0–100.
>
> What you get
> • Pulse Score on Home — storage and thermal state, exactly what iOS measures
> • Storage detail aligned with iPhone Storage in Settings
> • Battery: current charge, charging state, Low Power Mode, with a one-tap link to iOS's own Battery Health page
> • Temperature: thermal state plus a 7-day breakdown
> • Clean tab: real counts and real GB for photos, videos and screenshots, computed locally
> • Health tab: Pulse Score trend, weekly stats, personality summary, shareable card
>
> Pulse Pro
> • Weekly health reports
> • Battery diagnostics deep dive
> • Full scan history (free shows the last 14 days)
> • Home Screen and Lock Screen widgets
> • Support a tiny, honest app
>
> Honest by design
> • Nothing leaves your device. No analytics SDK. No tracking.
> • iOS does not expose true battery health to apps. Pulse says so and links to Apple's official page.
> • Pulse never deletes files. Every cleanup opens the relevant Apple app.

---

## Turkish (tr)

- **Name:** Pulse — Telefon Sağlık Tarayıcısı
- **Subtitle:** Dürüst cihaz teşhisi
- **Promotional text:** Telefonunun sağlığını saniyeler içinde öğren. Sadece gerçek iOS sinyalleri — uydurma metrik yok.
- **Keywords:** telefon sağlığı,pil sağlığı,depolama temizleyici,sistem monitör,performans tarayıcı,cihaz bakımı,pulse,iphone teşhis
- **Description:**

> Pulse, sadece iOS'un gerçekten yayınladığı verileri gösteren bir telefon sağlığı tarayıcısıdır. Uydurma pil döngüleri yok, tahmini metrikler yok. Depolama, termal durum, şarj seviyesi, şarj durumu ve Güç Tasarrufu — gerçek iOS sinyalleri 0–100 arası tek bir Pulse Skoru'na dönüşür.
>
> Ne sunar
> • Ana ekranda Pulse Skoru — depolama ve termal durum, iOS'un ölçtüğü kadarıyla
> • Ayarlar'daki iPhone Depolama ile uyumlu depolama detayı
> • Pil: anlık şarj, şarj durumu, Güç Tasarrufu + iOS'un Pil Sağlığı sayfasına tek dokunuş bağlantı
> • Sıcaklık: termal durum ve 7 günlük dağılım
> • Temizlik: fotoğraflar, videolar ve ekran görüntüleri için gerçek adet ve gerçek GB, cihazda hesaplanır
> • Sağlık: Pulse Skoru trendi, haftalık istatistik, telefon karakteri, paylaşılabilir kart
>
> Pulse Pro
> • Haftalık sağlık raporları
> • Pil teşhisi derin bakış
> • Tüm tarama geçmişi (ücretsiz sürüm son 14 günü gösterir)
> • Ana Ekran ve Kilit Ekranı widget'ları
> • Küçük, dürüst bir uygulamayı destekleyin
>
> Tasarım gereği dürüst
> • Hiçbir veri cihazdan çıkmaz. Analitik SDK yok. Takip yok.
> • iOS gerçek pil sağlığını uygulamalara açmaz. Pulse bunu söyler ve Apple'ın resmi sayfasına yönlendirir.
> • Pulse hiçbir dosya silmez. Her temizlik adımı ilgili Apple uygulamasını açar.

---

## Stub localizations (es, pt-BR, fr, de, it, ru, ja, ko, zh-Hans, ar, hi)

For each language, paste the English description as a starting point in App Store Connect, then have it reviewed by a native speaker before launch. The in-app UI strings are already translated to Turkish; remaining 11 languages fall back to English at runtime until further translation passes.

## Age rating

Suggested: 4+. No objectionable content; no user-generated content; no third-party advertising.

## Category

- **Primary:** Utilities
- **Secondary:** Health & Fitness

## URLs (GitHub Pages — `/docs` folder of this repo)

Until a custom domain is wired up:

- **Privacy Policy URL** (required): `https://<github-username>.github.io/<repo-name>/privacy.html`
- **Support URL** (required):        `https://<github-username>.github.io/<repo-name>/support.html`
- **Marketing URL** (optional):      `https://<github-username>.github.io/<repo-name>/`

With custom domain `pulseapp.app` (add `docs/CNAME`):

- `https://pulseapp.app/privacy.html`
- `https://pulseapp.app/support.html`
- `https://pulseapp.app/`

## App Store Review notes
> Pulse runs entirely on-device. There is no backend, no account system, no analytics. The Pulse Pro subscription is handled by Apple's StoreKit; the app receives only a yes/no entitlement flag.
>
> For review:
> 1. The app does NOT claim to read true battery health. We say so and link to Settings.
> 2. The Clean tab never deletes files. It opens the Photos app or Settings.
> 3. Storage % matches Settings → iPhone Storage (we use `volumeAvailableCapacityKey`).
> 4. Notifications: local only, weekly check-in if user opts in.

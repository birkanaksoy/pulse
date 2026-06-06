#!/usr/bin/env python3
"""Add Turkish translations to Pulse's Localizable.xcstrings.

Reads the catalog, walks the dictionary below, and for each English key
ensures a `tr` localization with state=translated. Idempotent — running
twice gives the same result.
"""
import json, sys, pathlib

CATALOG = pathlib.Path("/Users/birkanaksoy/Desktop/pulseapp/Pulse/Resources/Localizable.xcstrings")

TR = {
    # Greetings & generic
    "Good morning": "Günaydın",
    "Good afternoon": "İyi öğleden sonralar",
    "Good evening": "İyi akşamlar",
    "Last scan · %@": "Son tarama · %@",
    "home.lastScan": "Son tarama · %@",
    "No scan yet": "Henüz tarama yok",

    # Status / generic
    "Active": "Etkin",
    "Free": "Ücretsiz",
    "Always": "Her zaman",
    "Never": "Asla",
    "Version": "Sürüm",
    "Support": "Destek",
    "Pulse Pro": "Pulse Pro",

    # Insights (formatted)
    "insight.storage.clear": "Depolama %%%lld — yer açın",
    "insight.storage.tight": "Depolama %%%lld — sıkışıyor",
    "insight.storage.comfortable": "Depolama %%%lld — rahat",
    "insight.storage.healthy": "Depolama sağlıklı: %%%lld",
    "Storage at %lld%% — clear space soon": "Depolama %%%lld — yer açın",
    "Storage at %lld%% — getting tight": "Depolama %%%lld — sıkışıyor",
    "Storage at %lld%% — comfortable": "Depolama %%%lld — rahat",
    "Storage healthy at %lld%%": "Depolama sağlıklı: %%%lld",
    "Thermal state warm — iOS may throttle performance": "Termal durum: sıcak — iOS performansı kısabilir",
    "Thermal state hot — consider a cooler environment": "Termal durum: çok sıcak — daha serin bir ortam tercih edin",
    "Low Power Mode is on": "Güç Tasarrufu açık",
    "insight.battery.low": "Pil %%%lld — şarja takmayı düşünün",
    "Battery at %lld%% — consider charging": "Pil %%%lld — şarja takmayı düşünün",
    "insight.trend.up": "Skor son 3 taramada %lld puan arttı",
    "insight.trend.down": "Skor son 3 taramada %lld puan düştü",
    "Score rose %lld over your last 3 scans": "Skor son 3 taramada %lld puan arttı",
    "Score fell %lld over your last 3 scans": "Skor son 3 taramada %lld puan düştü",
    "Today's insights": "Bugünün önerileri",

    # Personality
    "Unknown": "Bilinmiyor",
    "Run a scan to find out.": "Öğrenmek için bir tarama başlatın.",
    "Stable & Healthy": "Sakin & Sağlıklı",
    "Cool, roomy, and calm.": "Serin, geniş ve sakin.",
    "Hoarder": "Biriktirici",
    "Storage is your bottleneck.": "Depolama dar boğazın.",
    "Marathon Runner": "Maratoncu",
    "Working hot. Give it a rest.": "Sıcak çalışıyor. Biraz dinlendir.",
    "Power Sipper": "Güç Tasarrufçusu",
    "Mostly in Low Power Mode.": "Çoğunlukla Güç Tasarrufunda.",
    "Overworked Office Worker": "Aşırı Yüklü Çalışan",
    "High load, low rest.": "Yoğun yük, az dinlenme.",
    "Burnt Out": "Tükenmiş",
    "Needs attention.": "İlgi bekliyor.",
    "Steady Performer": "Sağlam Performansçı",
    "Performance trending warm.": "Performans biraz sıcak gidiyor.",
    "Performance holding steady.": "Performans dengede.",

    # Home cards
    "Used": "Kullanılan",
    "System thermal": "Sistem termal",
    "iOS power saver": "iOS güç tasarrufu",

    # Clean
    "Pulse suggests. You decide.": "Pulse önerir. Karar senin.",
    "Scanning your library…": "Kitaplığın taranıyor…",
    "Photo access required": "Fotoğraf erişimi gerekli",
    "Allow & Scan": "İzin ver ve Tara",
    "None found": "Bulunamadı",
    "Pulse never deletes anything. Each category opens the relevant Apple app or Settings so you stay in control.": "Pulse hiçbir şey silmez. Her kategori ilgili Apple uygulamasını veya Ayarlar'ı açar; kontrol sende kalır.",

    # Health
    "Pulse Score · 7 days": "Pulse Skoru · 7 gün",
    "Run scans to build your trend": "Trend oluşturmak için taramalar yap",
    "Total scans": "Toplam tarama",
    "Days tracked": "Takip edilen gün",
    "Best day": "En iyi gün",
    "7-day average": "7 günlük ortalama",
    "Phone Personality": "Telefon Karakteri",
    "Share": "Paylaş",
    "See your full history": "Tüm geçmişini gör",

    # Weekly Report
    "Weekly Report": "Haftalık Rapor",
    "Weekly insight": "Haftalık özet",
    "A digest of how your phone fared this week.": "Telefonunuzun bu hafta nasıl olduğunun özeti.",
    "Avg score": "Ortalama skor",
    "Watch out": "Dikkat",
    "Storage running tight": "Depolama daralıyor",
    "Thermal events this week": "Bu hafta termal olay var",
    "Nothing notable. Keep it up.": "Dikkat çeken bir şey yok. Devam et!",

    # Battery Detail
    "Pulse shows only what iOS exposes publicly — current state, not fabricated metrics.": "Pulse yalnızca iOS'un herkese açtığı verileri gösterir; uydurma metrik yok.",
    "Charge": "Şarj",
    "State": "Durum",
    "Low Power Mode": "Güç Tasarrufu",
    "Battery level unavailable (running on Simulator)": "Pil seviyesi okunamıyor (Simulator)",
    "See Battery Health": "Pil Sağlığını Göster",
    "iOS keeps the real maximum capacity in Settings.": "Gerçek maksimum kapasiteyi iOS Ayarlar'da tutar.",
    "Charge over recent scans": "Son taramalarda şarj seviyesi",
    "Run more scans to build a trend.": "Trend için daha fazla tarama yap.",
    "iOS does not expose true battery health to apps. Anything claiming a precise health % from a third-party app is guessing.": "iOS pil sağlığını uygulamalara açmaz. Üçüncü taraf bir uygulama kesin bir sağlık % iddia ediyorsa tahmin yürütüyordur.",

    # Storage Detail
    "Reported directly by iOS — these numbers are real.": "Doğrudan iOS'tan; sayılar gerçek.",
    "Total": "Toplam",
    "In use": "Kullanımda",
    "Status": "Durum",
    "Plenty of room": "Bolca yer var",
    "Comfortable": "Rahat",
    "Getting tight": "Sıkışıyor",
    "Nearly full": "Neredeyse dolu",
    "iOS performs best below 80% used.": "iOS %80'in altında daha iyi çalışır.",
    "Still healthy. Watch the trend.": "Hâlâ sağlıklı. Trendi izle.",
    "Consider clearing photos or unused apps.": "Fotoğrafları veya kullanılmayan uygulamaları temizlemeyi düşün.",
    "Updates and Camera may fail above 90%.": "%90 üzerinde güncellemeler ve Kamera başarısız olabilir.",
    "Used % over recent scans": "Son taramalarda kullanım %'si",
    "Open iPhone Storage": "iPhone Depolamayı Aç",
    "See per-app breakdown in Settings.": "Uygulama bazında dağılımı Ayarlar'da gör.",
    "Apps cannot read per-app storage usage on iOS. For an app-level breakdown, use iPhone Storage in Settings.": "iOS'ta uygulamalar uygulama bazında depolama kullanımını okuyamaz. Uygulama bazında dağılım için Ayarlar > iPhone Depolama'yı kullan.",

    # Temperature Detail
    "Thermal state is reported directly by iOS.": "Termal durum doğrudan iOS tarafından bildirilir.",
    "Running cool.": "Serin çalışıyor.",
    "Slightly elevated, normal.": "Hafif yüksek, normal.",
    "iOS may throttle performance.": "iOS performansı kısabilir.",
    "Move to a cooler spot if possible.": "Mümkünse daha serin bir yere taşı.",
    "Past 7 days": "Son 7 gün",
    "Scans logged": "Kayıtlı tarama",
    "Normal": "Normal",
    "Warm": "Sıcak",
    "Hot": "Aşırı sıcak",
    "Common causes": "Sık karşılaşılan nedenler",
    "Direct sunlight or hot environment": "Doğrudan güneş ışığı veya sıcak ortam",
    "Long camera, AR or video sessions": "Uzun kamera, AR veya video kullanımı",
    "Charging while gaming or streaming": "Oyun veya yayın sırasında şarj",
    "Poor cellular signal forcing the radio": "Zayıf hücresel sinyal anteni zorluyor",
    "iOS does not expose precise °C/°F. Pulse shows the same coarse thermal state iOS uses to throttle performance.": "iOS kesin °C/°F vermez. Pulse, iOS'un performans kısarken kullandığı kaba termal durumu gösterir.",

    # Settings
    "Settings": "Ayarlar",
    "Reminders": "Hatırlatıcılar",
    "Weekly check-in": "Haftalık kontrol",
    "Every Sunday at 10:00 — a nudge to run a fresh scan.": "Her Pazar 10:00'da — yeni bir tarama için hatırlatma.",
    "Account": "Hesap",
    "Privacy": "Gizlilik",
    "About": "Hakkında",
    "Restore Purchases": "Satın Almaları Geri Yükle",
    "Toggle Pro (dev)": "Pro'yu Aç/Kapa (dev)",
    "On-device analysis": "Cihazda analiz",
    "Diagnostics shared": "Tanılama paylaşımı",

    # Onboarding
    "Honest signals. No guesswork.": "Dürüst sinyaller. Tahmin yok.",
    "Diagnose": "Teşhis",
    "One score from real iOS signals.": "Gerçek iOS sinyallerinden tek skor.",
    "Suggest": "Öneri",
    "We recommend. You decide.": "Biz öneririz. Karar senin.",
    "Track": "Takip Et",
    "Watch your phone over time.": "Telefonunu zaman içinde izle.",
    "Ready when you are": "Sen hazır olduğunda başlayalım",
    "Your first real scan starts on the next screen. Everything is computed on-device.": "İlk gerçek taraman sonraki ekranda başlar. Her şey cihazda hesaplanır.",
    "Run my first scan": "İlk taramamı yap",
    "Continue": "Devam",

    # Paywall
    "Unlock Pulse Pro": "Pulse Pro'yu Aç",
    "Deeper diagnostics. Honest data.": "Daha derin teşhis. Dürüst veri.",
    "Weekly health reports": "Haftalık sağlık raporları",
    "Battery diagnostics": "Pil teşhisi",
    "Full scan history": "Tüm tarama geçmişi",
    "Home & Lock Screen widgets": "Ana Ekran ve Kilit Ekranı widget'ları",
    "Support a tiny, honest app": "Küçük, dürüst bir uygulamayı destekle",
    "Annual": "Yıllık",
    "Monthly": "Aylık",
    "Save 58%": "%58 tasarruf",
    "Start Free Trial": "Ücretsiz Denemeyi Başlat",
    "7 days free, then %@. Cancel anytime.": "7 gün ücretsiz, sonrası %@. İstediğin zaman iptal et.",
    "Restore": "Geri Yükle",
    "Terms": "Şartlar",

    # Notifications
    "Pulse check-in": "Pulse kontrolü",
    "It's been a week. Run a scan to see how your phone's doing.": "Bir hafta oldu. Telefonunun nasıl olduğunu görmek için bir tarama yap.",

    # ProLock
    "Unlock with Pro": "Pro ile aç",
    "Pulse widget": "Pulse widget'ı",
    "Battery diagnostics": "Pil teşhisi",
    "Estimated cycles, charging habits, and tailored advice.": "Tahmini döngüler, şarj alışkanlıkları ve öneriler.",

    # Health hint
    "Free shows the last %lld days. Pro unlocks all of it.": "Ücretsiz son %lld günü gösterir. Pro tüm geçmişi açar.",

    # Misc
    "Edit": "Düzenle",
    "Done": "Tamam",
    "items": "öğe",

    # Clean v2 (real bytes + progress)
    "%lld items": "%lld öğe",
    "calculating…": "hesaplanıyor…",

    # Widget lock screen
    "Pulse · Pro": "Pulse · Pro",
    "Unlock widget": "Widget'ı aç",
    "Tap to upgrade": "Yükseltmek için dokun",

    # Sprint 1: empty state + errors + delete + accessibility
    "Ready to scan": "Taramaya hazır",
    "Tap the button below to start.": "Başlamak için aşağıdaki düğmeye dokun.",
    "Pulse score": "Pulse skoru",
    "Photo access denied": "Fotoğraf erişimi reddedildi",
    "Pulse needs read access to count photos, videos and screenshots. Enable it in Settings.": "Pulse'ın fotoğraf, video ve ekran görüntülerini sayabilmesi için okuma izni gerekir. Ayarlar'dan etkinleştir.",
    "Open Settings": "Ayarları Aç",
    "Delete all data": "Tüm verimi sil",
    "Delete all Pulse data?": "Tüm Pulse verisi silinsin mi?",
    "Delete everything": "Hepsini sil",
    "Cancel": "İptal",
    "This removes every scan record, the widget snapshot, and the weekly reminder. Onboarding stays done. This cannot be undone.": "Tüm tarama kayıtlarını, widget verisini ve haftalık hatırlatmayı siler. Onboarding tekrar gösterilmez. Bu işlem geri alınamaz.",

    # Sprint 2: legal + paywall
    "Privacy Policy": "Gizlilik Politikası",
    "Terms of Use": "Kullanım Şartları",
    "Last updated: 5 June 2026": "Son güncelleme: 5 Haziran 2026",
    "Subscriptions auto-renew at the end of each billing period unless cancelled at least 24 hours before. Manage or cancel anytime in your App Store account. Payment is charged to your Apple ID. By continuing you agree to the Terms and Privacy Policy below.": "Abonelikler iptal edilmediği sürece her fatura dönemi sonunda otomatik yenilenir; en az 24 saat öncesinden iptal etmelisin. App Store hesabından istediğin zaman yönet veya iptal et. Ödeme Apple ID'ne yansıtılır. Devam ettiğinde aşağıdaki Şartlar ve Gizlilik Politikası'nı kabul etmiş olursun.",
    "Privacy": "Gizlilik",
    "Terms": "Şartlar",

    # Privacy Policy sections
    "Everything runs on your device": "Her şey cihazında çalışır",
    "Pulse performs every measurement locally using iOS APIs. Storage, thermal state, battery level, charging state, Low Power Mode, photo counts — all of this is read by your iPhone and stays on it. Nothing is uploaded.": "Pulse tüm ölçümleri iOS API'leri ile cihazında yapar. Depolama, termal durum, pil seviyesi, şarj durumu, Güç Tasarrufu, fotoğraf adetleri — hepsi iPhone'unda okunur ve orada kalır. Hiçbir şey yüklenmez.",
    "What we never collect": "Asla toplamadıklarımız",
    "No analytics SDK, no advertising identifier, no crash-reporting third party, no usage tracking. We do not ask for your email or any account.": "Analitik SDK yok, reklam tanımlayıcı yok, üçüncü taraf crash raporu yok, kullanım takibi yok. E-posta veya hesap istemiyoruz.",
    "Photo Library access": "Fotoğraf Kitaplığı erişimi",
    "If you grant Photo Library access, Pulse reads only metadata (counts and file sizes) to populate the Clean tab. Your photos and videos never leave your device.": "Fotoğraf Kitaplığı erişimi verirsen Pulse yalnızca meta veriyi (adet ve dosya boyutu) okur. Fotoğrafların ve videoların asla cihazından çıkmaz.",
    "Subscriptions": "Abonelikler",
    "Pulse Pro is handled by Apple via StoreKit. We receive only an entitlement flag (Pro: yes/no) from Apple — never your payment details.": "Pulse Pro Apple'ın StoreKit'i üzerinden yönetilir. Apple'dan yalnızca Pro: var/yok bilgisini alırız — ödeme bilgilerini asla görmeyiz.",
    "Notifications": "Bildirimler",
    "If you enable the weekly check-in, Pulse schedules a local notification on your device. No notification content leaves the phone.": "Haftalık kontrolü açarsan Pulse cihazına yerel bir bildirim planlar. Bildirim içeriği telefonundan çıkmaz.",
    "Your control": "Senin kontrolünde",
    "Settings → Privacy → Delete all data wipes every scan record, the widget snapshot, and the weekly reminder in one step.": "Ayarlar → Gizlilik → Tüm verimi sil komutu tüm tarama kayıtlarını, widget verisini ve haftalık hatırlatmayı tek adımda temizler.",
    "Contact": "İletişim",
    "Questions about privacy? Email support@pulseapp.app.": "Gizlilikle ilgili sorular için: support@pulseapp.app",

    # Terms sections
    "Use of the app": "Uygulamanın kullanımı",
    "Pulse is provided to help you monitor your phone's health. The Pulse Score and personality labels are interpretive summaries of real iOS signals — informational, not medical or diagnostic guarantees.": "Pulse, telefonunun sağlığını izlemene yardımcı olur. Pulse Skoru ve karakter etiketleri gerçek iOS sinyallerinin yorumlanmış özetidir — bilgi amaçlıdır; tıbbi veya teşhis garantisi vermez.",
    "Honesty about iOS limits": "iOS sınırları konusunda dürüstlük",
    "iOS does not expose true battery health, per-app storage usage, or precise temperature to third-party apps. Pulse shows only what iOS publishes and clearly marks anything outside that scope.": "iOS gerçek pil sağlığını, uygulama bazında depolama kullanımını veya kesin sıcaklığı üçüncü taraf uygulamalara açmaz. Pulse yalnızca iOS'un yayınladıklarını gösterir ve bunun dışındaki her şeyi açıkça belirtir.",
    "Pulse Pro subscription": "Pulse Pro aboneliği",
    "Subscriptions auto-renew at the end of each billing period unless cancelled at least 24 hours before the end of the current period. Payment is charged to your Apple ID. Manage or cancel anytime in your App Store account.": "Abonelikler her fatura dönemi sonunda otomatik yenilenir; mevcut dönemin bitiminden en az 24 saat önce iptal etmelisin. Ödeme Apple ID'ne yansıtılır. App Store hesabından istediğin zaman yönet veya iptal et.",
    "No file deletion": "Dosya silme yok",
    "Pulse never deletes photos, videos, or files on its own. Every cleanup action opens the relevant Apple app or Settings so you stay in control.": "Pulse hiçbir fotoğrafı, videoyu veya dosyayı kendi başına silmez. Her temizlik adımı ilgili Apple uygulamasını veya Ayarlar'ı açar; kontrol sende kalır.",
    "Liability": "Sorumluluk",
    "Pulse is provided “as is”. We are not liable for decisions you make based on the score, including device repair or replacement choices.": "Pulse \"olduğu gibi\" sunulur. Skora dayanarak verdiğin kararlardan (cihaz onarımı veya değişim dahil) sorumlu tutulamayız.",
    "Changes": "Değişiklikler",
    "We may update these terms. Material changes are announced in the app before they take effect.": "Bu şartları güncelleyebiliriz. Önemli değişiklikler yürürlüğe girmeden önce uygulama içinde duyurulur.",

    # Sprint 3: design pass (mostly tab labels — also in catalog already; re-affirm)
    "Status": "Durum",
    "just now": "az önce",

    # Sprint 4: gaps & polish
    "One nudge a week.": "Haftada bir küçük hatırlatma.",
    "A Sunday reminder to scan. Local only — nothing leaves your phone.": "Pazarları tarama için bir hatırlatma. Yalnızca cihazında — hiçbir şey dışarı çıkmaz.",
    "Enable weekly check-in": "Haftalık kontrolü aç",
    "Maybe later": "Belki sonra",
    "No scans yet": "Henüz tarama yok",
    "Once you run a scan from Home, your trend, stats, and weekly report will appear here.": "Ana ekrandan bir tarama yapınca trend, istatistikler ve haftalık rapor burada görünür.",

    # App Icon Picker (Pro perk)
    "Appearance": "Görünüm",
    "App Icon": "Uygulama Simgesi",
    "Pick your look": "Görünümünü seç",
    "Pro unlocks the four alternate icons. The change is instant.": "Pro dört alternatif simgenin kilidini açar. Değişim anında olur.",
    "Default": "Varsayılan",
    "Midnight": "Gece Yarısı",
    "Sunset": "Gün Batımı",
    "Mono": "Mono",
    "Alternate icons are a Pulse Pro perk.": "Alternatif simgeler Pulse Pro ayrıcalığıdır.",
    "4 alternate app icons": "4 alternatif uygulama simgesi",

    # Sprint 5: A+B+C launch polish
    "day": "gün",
    "days": "gün",
    "Undo": "Geri al",
    "All data deleted": "Tüm veri silindi",
    "How it works": "Nasıl çalışır",
    "How Pulse works": "Pulse nasıl çalışır",
    "Every number you see is read from iOS itself. We never guess, never round up, and never invent metrics to look impressive.": "Gördüğün her sayı doğrudan iOS'tan okunur. Tahmin etmez, abartmaz, uydurma metrik üretmeyiz.",
    "The Pulse Score (0–100)": "Pulse Skoru (0–100)",
    "Storage pressure × 55% + thermal state × 45%. Both signals come directly from iOS — `volumeAvailableCapacityKey` for storage, `ProcessInfo.thermalState` for thermal. The weights are documented in our source code and never change without an app update.": "Depolama baskısı × %55 + termal durum × %45. Her iki sinyal de doğrudan iOS'tan gelir — depolama için `volumeAvailableCapacityKey`, termal için `ProcessInfo.thermalState`. Ağırlıklar kaynak kodunda belgelidir ve uygulama güncellemesi olmadan değişmez.",
    "What we measure honestly": "Dürüstçe ölçtüklerimiz",
    "What iOS hides — and we don't fake": "iOS'un gizlediği — uydurmadıklarımız",
    "What we never do": "Asla yapmadıklarımız",
    "Verify it yourself": "Kendin doğrula",

    # Icon swap (Mono primary)
    "3 alternate app icons": "3 alternatif uygulama simgesi",
    "Pro unlocks the three alternate icons. The change is instant.": "Pro üç alternatif simgenin kilidini açar. Değişim anında olur.",
}


def ensure_tr(catalog: dict) -> int:
    """Add `tr` translation for any key in TR dict that lacks one. Returns count added."""
    strings = catalog.setdefault("strings", {})
    added = 0
    for key, tr in TR.items():
        entry = strings.setdefault(key, {})
        locs = entry.setdefault("localizations", {})
        existing = locs.get("tr", {}).get("stringUnit", {}).get("value")
        if existing == tr:
            continue
        locs["tr"] = {"stringUnit": {"state": "translated", "value": tr}}
        added += 1
    return added


def main() -> None:
    raw = CATALOG.read_text(encoding="utf-8")
    catalog = json.loads(raw)
    added = ensure_tr(catalog)
    CATALOG.write_text(
        json.dumps(catalog, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Updated {added} Turkish entries in {CATALOG.name}.")


if __name__ == "__main__":
    main()

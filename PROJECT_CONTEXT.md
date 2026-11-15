# 🎮 Bounce Back — Proje Bağlamı ve Teknik Mimari (`PROJECT_CONTEXT.md`)

Bu doküman, **Bounce Back** (2D Piksel Grafik Aksiyon/Parkur Oyunu) projesinde alınan tüm mimari kararları, tamamlanan modülleri, oyun içi veri/eşya veritabanı yapısını ve gelecekteki geliştirme adımlarını özetler.

* **Yapımcılar:** **Giray KESDİ** & **Umay ÇEKCEOĞLU**

---

## 1. Oyun Konsepti ve Hikaye Özeti
* **Tema:** *Bounce Back* (Geri Sekme / Dibe Vurup Toparlanma).
* **Hikaye:** Bir şirket çalışanı gece mesaisinde bilgisayarda meydana gelen kritik bir arıza (`0xB0U-NC3`) sonucu bilgisayarın içindeki karanlık ve neon kablolarla dolu eski donanım çöplüğüne çekilir. Zorlu aşamaları (Donanım Çöplüğü, Soğutma Suyu & Devre Labirenti, Kablo Boss Kaçışı ve Final Güvenlik Koridoru) geçip sistemin ana güç fişini çekerek gerçek dünyaya geri döner.

---

## 2. Mimari ve Teknik Kararlar

| Alan | Karar / Yapılandırma | Açıklama |
| :--- | :--- | :--- |
| **Oyun Motoru** | **Godot 4.7.2 (GDScript)** | `Forward Plus` render modu, `.uid` ve `.import` varlık yönetimi. |
| **Temel Çözünürlük** | **`320x180` piksel (16:9)** | Pencere önizleme boyutu `1280x720` (4x tam kat). `canvas_items` stretch mode + `integer` ölçekleme. |
| **Piksel Filtreleme** | **`Nearest` (`default_texture_filter=0`)** | Piksel grafiklerin bulanıklaşmadan keskin görünmesi için. |
| **Global Durum (State)** | **Autoload Singleton (`GameManager.gd`)** | Sahne geçişlerinde oyuncu canı (3 Kalp), aktif checkpoint, 4 slotlu envanter, ölüm durumu (`player_died`), hitstop ve ekran sarsıntısı korunur. |
| **Müzik ve Ses Sistemi** | **`MusicManager.gd` (`GameManager` alt modülü)** | `assets/audio/` altındaki 19 `.mp3` dosyasını otomatik tarar. Sahne değişiminde arka plan müziğini (`loop`) günceller; 10 kanallı SFX havuzu ve ayrı yürüme sesi kanalı yönetir. |
| **CRT ve Görsel Efektler** | **`crt_scanlines.gdshader` (`F1`)** | CRT tarama çizgisi/vignette efekti (`F1` ile açılıp kapatılabilir), vuruşlarda hitstop ve kamera sarsıntısı (`screen_shake_requested`). |
| **Dinamik Tuş Ataması** | **`GameManager._setup_inputs()`** | Hareket: `WASD`/Oklar, Zıplama: `Space`/`W`/`↑`, Eğilme: `S`/`Ctrl`/`↓`, Etkileşim: `E`, Saldırı: **Mouse Sol Tık** / **`Q`**, Envanter: `1-4`/`Tab`/`Z`, Yardım: **`H`**, CRT: **`F1`**. |
| **Boru Geçiş & Sersemleme** | **`LevelPortal.gd` & `Player.gd`** | Bölüm sonunda boruya girme animasyonu, yeni bölümde tavandaki borudan aşağı düşüş ve yere çarpınca dönen yıldızlarla `1.25s` sersemleme (stun) mekaniği. |
| **Ölüm & Ana Menü** | **`MainMenu.tscn` & `HUD.tscn` (`DeathPanel`)** | Oyun doğrudan Ana Menü (`Başla`, `H (Yardım)`, `Yapımcılar`) ile açılır. Haritadan aşağı düşme veya tüm kalpleri kaybetme durumunda `Try Again` ve `Menu` seçenekli Ölüm Ekranı açılır. |

---

## 3. Tamamlanan Modüller ve Klasör Yapısı

```text
OyunProjesi/
├── project.godot                        # Godot 4.7 proje yapılandırması (Başlangıç: MainMenu.tscn)
├── PROJECT_CONTEXT.md                   # Proje mimari ve durum dokümanı
├── autoload/
│   ├── GameManager.gd                   # Can (3 Kalp), Envanter (4 Slot), Checkpoint, InputMap, Ölüm Sinyali, Ses Köprüsü
│   └── MusicManager.gd                  # 19 MP3 müzik/SFX yöneticisi (Sahne müziği, loop, 10 kanallı SFX havuzu)
├── assets/
│   ├── audio/                           # 19 adet .mp3 müzik ve ses efekti (Menü, Bölüm, Boss, Final, Vuruş, Yürüme vb.)
│   ├── sprites/                         # Piksel sprite dosyaları (Player, Kılıçlar, Bant, Can, Moblar, Boss, Fiş, Bloklar)
│   ├── tilesets/                        # Donanım/Devre karo seti (hardware_tileset.png)
│   └── shaders/
│       └── crt_scanlines.gdshader       # CRT monitör tarama çizgisi ve vignette shader'ı
└── scenes/
    ├── player/
    │   ├── Player.tscn                  # Karakter, CollisionShape, CeilingCheck, SwordHitbox, InteractArea
    │   └── Player.gd                    # Yürüme, Zıplama, Tırmanma, Eğilme, Saldırı (Sol Tık/Q), Boru Düşüş & Sersemleme
    ├── ui/
    │   ├── MainMenu.tscn / .gd          # Ana Menü: Başla, H (Yardım) ve Yapımcılar (Giray KESDİ & Umay ÇEKCEOĞLU)
    │   ├── HUD.tscn                     # Sol üst 3 Kalp İkonu, Sağ üst 4 İtem Slotu, [H] Yardım, Ölüm Ekranı (Try Again / Menu)
    │   └── HUD.gd                       # GameManager sinyalleri ile Kalp, Envanter ve Ölüm Ekranı yönetimi
    ├── objects/
    │   ├── LevelBuilder.gd              # Prosedürel neon platform, Giriş Borusu, Lazer Kapısı, Şok Tuzağı, Plazma Dronu kurucu
    │   ├── BouncePad.tscn / .gd         # Trambolin devreleri (squash & stretch animasyonlu sekme)
    │   ├── ClimbableCable.tscn / .gd    # Basamaklı endüstriyel tırmanma merdiveni/kablosu + Kopuk kablo onarma mekaniği
    │   ├── PickupItem.tscn / .gd        # Yerdeki alınabilir eşyalar (Bant, Neon Kılıç, Enerji Hücresi)
    │   ├── LevelPortal.tscn / .gd       # Bölüm geçiş borusu (Boruya girme animasyonu + Checkpoint)
    │   └── PowerPlug.tscn / .gd         # Final sahnesindeki çekilebilir ana güç fişi
    ├── enemies/
    │   ├── JunkyardMonster.tscn / .gd   # 1. Bölüm canavarı (3 HP, ölünce Neon Güç Kılıcı düşürür)
    │   ├── LabyrinthBug.tscn / .gd      # 2. Bölüm labirent mobu (6 HP: 1. kılıçla 6, 2. kılıçla 2 vuruş)
    │   └── CableBoss.tscn / .gd         # 3. Bölüm arkadan kovalayan ve yakalayınca tek atan Kablo Boss'u
    └── levels/
        ├── Scene1_OfficeIntro.tscn / .gd # Sahne 1: Ofiste bilgisayara çekilme sekansı
        ├── Level1_Junkyard.tscn / .gd    # Sahne 2 (Bölüm 1): Donanım Çöplüğü, Bant alma, Canavar, Kablo onarma
        ├── Level2_Labyrinth.tscn / .gd   # Sahne 3 (Bölüm 2): Su birikintisi, 3 katlı Labirent, 6 HP moblar
        ├── Level3_BossChase.tscn / .gd   # Sahne 4 (Bölüm 3): 7 aşamalı uzun Kablo Boss kovalamacası (Lazer, Dron, Şok, Kuleler)
        └── Scene5_Finale.tscn / .gd      # Sahne 5 (Final): Güvenlik engelli uzun koridor, Fişi çekme ve Ofise dönüş
```

---

## 4. Oyun İçi Veritabanı ve Denge Matematiği

### 4.1. Eşya Veritabanı (`GameManager.ITEM_DATABASE`)
Envanter 4 sabit slottan (`slots = [null, null, null, null]`) oluşur ve `1`, `2`, `3`, `4` tuşları veya `Tab` / `Mouse Tekerleği` ile değiştirilir. Saldırı **Mouse Sol Tık** veya **`Q`** tuşu ile yapılır:

| Slot İndeksi | Eşya ID (`id`) | Eşya Adı (`name`) | Tür (`type`) | Hasar (`damage`) | Elde Edilme ve Kullanım Yeri |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Slot 0 (`[1]`)** | `spiky_sword` | Dikensi Küçük Kılıç | `weapon` | **`1`** | Oyun başında envanterde açık gelir. |
| **Slot 1 (`[2]`)** | `neon_sword` | Neon Güç Kılıcı | `weapon` | **`3`** | 1. Bölümdeki `JunkyardMonster` öldürüldüğünde düşer (`E` ile alınır). |
| **Slot 2 (`[3]`)** | `cable_tape` | İzole Kablo Bandı | `tool` | `0` | 1. Bölümde parkur sonunda `E` ile alınır; çıkıştaki kopuk kabloyu onarır. |
| **Slot 3 (`[4]`)** | `energy_cell` | Kalp (+1 Can) | `consumable` | `0` | Labirent ve Boss kaçışında bulunur; eksik kalbi `+1` doldurur veya slotta saklanır. |

---

## 5. Ses ve Müzik Sistemi (`MusicManager.gd`)

`GameManager` tarafından alt düğüm olarak başlatılır (`PROCESS_MODE_ALWAYS`) ve `assets/audio/` klasöründeki 19 `.mp3` dosyasını `EXACT_FILES` sözlüğü üzerinden rollerle eşleştirir:

* **Sahne Müzikleri (`SCENE_MUSIC`, otomatik loop):**
  * `MainMenu`, `Scene1_OfficeIntro` → `menu` (`menüdeyken çalan müzik.mp3`)
  * `Level1_Junkyard`, `Level2_Labyrinth` → `level` (`normal bölümlerde arka plan müziği.mp3`)
  * `Level3_BossChase` → `boss` (`boss geldiğinde arka plan müziği.mp3`)
  * `Scene5_Finale` → `finale` (`bossu geçince final sahnesindeki arka plan müziği.mp3`)
* **Bitiş & Arayüz & Oynanış Efektleri:**
  * `victory` (final bitiş ekranı), `click` (menü/diyalog butonları), `pickup` (eşya toplama), `attack_spiky` / `attack_neon` (silaha göre saldırı), `jump`, `bounce`, `bounce_land`, `walk` (ayrı `_walk_player` kanalı), `stun`, `water_splash`, `death`, `game_over`, `plug`, `lights_off`.

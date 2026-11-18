# focusHifz

Struktur:
- `app/lib/` : kode Flutter (UI/UX HifzFlow, hafalan, LCC, tajwid, sertifikasi)
- `app/MainActivity.kt` : kunci layar (pin), Jangan Ganggu, status (kode Focus Mode milikmu, tidak diubah)
- `.github/workflows/build.yml` : build APK otomatis (push ke `main` → APK di tab Releases)
- `*.html` : prototype/Figma asli (referensi)

Alur hafalan: Pilih ayat → atur pengulangan + Focus Mode (Mati / Target waktu / Target ayat)
→ Ulangi (tiap pengulangan baca ke mikrofon, ayat tampil, baru bisa lanjut)
→ Uji (ayat diblur, lafalkan dari ingatan) → Evaluasi (kata hijau/merah/kuning) → Simpan.

Pengaturan cepat (di kode):
- `lib/lock.dart` → `modeUji` (true = ada tombol "Keluar (mode uji)" saat terkunci)
- `lib/pages/hafal.dart` → `kAkurasiUlang` (0.6), `kAkurasiUji` (0.7), `kMaxGagal` (3)

Mushaf & murottal:
- Tab **Mushaf**: 114 surah, teks Utsmani bertajwid dari API quran.com (`lib/quran_api.dart`).
  Huruf berwarna bisa diketuk untuk melihat hukumnya (`lib/tajweed.dart`); tiap ayat juga punya
  tombol daftar hukum tajwid. Teks tersimpan di HP setelah dibuka sekali.
- **Murottal** (`lib/murottal.dart`, `lib/pages/murottal_page.dart`): audio per ayat dari everyayah.com.
  Qari bisa dipilih dari seluruh daftar online (bawaan: Abdurrahmaan As-Sudais 64 kbps), lalu diunduh
  semua, per surah, atau rentang ayat. File yang sudah diunduh diputar offline.
- Nama, tema, ukuran huruf, qari, dan posisi terakhir dibaca tersimpan di `pengaturan.json`.

Build lokal: `flutter create --org com.fokus --project-name fokus_hafalan --platforms android .`
lalu `flutter pub add speech_to_text:^7.0.0 google_fonts http path_provider just_audio`, salin `app/lib/*` ke `lib/`,
`MainActivity.kt` ke `android/app/src/main/kotlin/com/fokus/fokus_hafalan/`, dan tambahkan permission
RECORD_AUDIO + INTERNET + ACCESS_NOTIFICATION_POLICY di AndroidManifest (lihat build.yml).

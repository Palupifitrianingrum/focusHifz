# HifzFlow (Flutter) — Focus Mode + Cek Bacaan Suara

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

Build lokal: `flutter create --org com.fokus --project-name fokus_hafalan --platforms android .`
lalu `flutter pub add speech_to_text:^7.0.0 google_fonts`, salin `app/lib/*` ke `lib/`,
`MainActivity.kt` ke `android/app/src/main/kotlin/com/fokus/fokus_hafalan/`, dan tambahkan permission
RECORD_AUDIO + INTERNET + ACCESS_NOTIFICATION_POLICY di AndroidManifest (lihat build.yml).

# DESIGN.md: HifzFlow

Dial: ENERGY 2 / RHYTHM 3 / MOTION 1

Reading this as: aplikasi pendamping hafalan Al-Qur'an (mobile, Android) untuk penghafal pemula sampai menengah, dengan bahasa visual hangat bergaya mushaf cetak dan tata letak kartu ala aplikasi janji temu, dial ENERGY 2 / RHYTHM 3 / MOTION 1.

## Sumber arahan

- Identitas yang sudah ada: hijau tua, krem, emas, Fraunces untuk judul, Amiri untuk teks Arab.
- Referensi pola: aplikasi janji temu (header sapaan dengan avatar, kartu utama berwarna sebagai titik fokus, baris kategori ikon, kartu jadwal, navigasi bawah dengan penanda aktif). Halaman Dribbble DocSpot tidak bisa dibuka di lingkungan kerja, jadi yang dipakai adalah pola umum jenis aplikasi tersebut, bukan salinan visualnya.

## Token

| Token | Terang | Gelap | Alasan |
|---|---|---|---|
| bg | #F6F0E2 | #0E1915 | Krem seperti kertas mushaf; gelap hijau-hitam agar mata nyaman saat hafalan malam |
| card | #FFFDF7 | #16251F | Satu tingkat lebih terang dari latar supaya kartu terbaca tanpa bayangan |
| green (aksi) | #0F5C4A | #3DB38F | Warna identitas; versi gelap dinaikkan agar kontras tombol lolos 4.5:1 |
| green2 (hero) | #0A3D31 | #0F3D31 | Permukaan pekat untuk satu titik fokus per layar |
| gold (aksen) | #C9A24B | #D4B05A | Satu aksen: bingkai mushaf, cincin progres di atas hijau pekat, satu tombol utama per layar |
| goldInk | #7A5A00 | #D4B05A | Emas untuk teks kecil di atas krem harus digelapkan agar lolos kontras |
| muted | #56695F | #A8B9B0 | Dihitung 4.67:1 atau lebih di semua latar |

Status (benar, ragu, salah) punya pasangan latar dan teks sendiri di kedua tema, selalu disertai ikon atau teks, tidak hanya warna.

## Keputusan dan alasan (R-31)

- Plus Jakarta Sans untuk antarmuka: bentuk huruf jelas pada ukuran kecil dan dirancang dengan bahasa Indonesia dalam pikiran.
- Fraunces untuk judul: kesan buku cetak yang hangat di samping teks mushaf.
- Amiri untuk Arab: meniru naskh mushaf dan lengkap dengan harakat.
- Penanda identitas, bintang delapan sudut (RubBadge): penanda hizb pada mushaf cetak. Dipakai sebagai wadah ikon dan nomor ayat, bukan sebagai ikon fitur.
- Bingkai ganda emas pada Mushaf: meniru garis tepi halaman mushaf, sehingga area baca terasa seperti halaman, bukan kotak biasa.
- Kartu tanpa bayangan, dibatasi garis tipis: hierarki dibangun dari ukuran dan warna permukaan. Hanya kartu hero yang berwarna pekat.
- Radius: 24 hero, 18 kartu, 12 kontrol, 8 penanda status. Hanya chip pilihan dan avatar yang bundar penuh.
- Beranda: hero (fokus), baris akses cepat horizontal, satu kartu progres, daftar jadwal muraja'ah. Tiap bagian memakai komposisi berbeda.
- LCC: grid dua kolom untuk empat latihan biasa, kartu lebar pekat untuk Tantangan Waktu karena hanya itu yang bernilai skor.
- Navigasi bawah: empat tujuan nyata, penanda aktif berupa isi hijau dengan ikon terisi dan label tebal.
- Ikon: set Material bawaan Flutter agar tidak menambah dependency yang tidak bisa diverifikasi; bentuk outline untuk tidak aktif dan terisi untuk aktif. Tidak ada emoji sebagai ikon.
- Gerak: hanya gelombang suara saat merekam dan perpindahan indikator navigasi 160 ms. Gelombang berhenti bila pengguna meminta kurangi animasi.
- Ritme: layar tidak memakai pola judul + kartu seragam. Setiap tab dibangun dari kebutuhan isi.

## Keadaan

- Kosong: ringkasan muraja'ah, riwayat aktivitas, riwayat ujian, daftar sertifikat, filter muraja'ah, sertifikat tanpa data.
- Memuat: tombol "Menyiapkan…" saat sesi hafalan dimulai dan "Memeriksa…" saat bacaan dicek.
- Galat: galat mesin suara tampil sebagai kotak status merah dengan ikon.

## Data contoh yang sudah ada sebelum redesign

Nama "Ahmad Fauzi", email contoh, angka "6 hari beruntun", dan jadwal muraja'ah awal berasal dari kode asli dan tidak diubah. Angka hari beruntun kini diberi label "(contoh)" di layar Profil.

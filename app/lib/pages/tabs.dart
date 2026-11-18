import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data.dart';
import '../quran_api.dart';
import '../theme.dart';
import '../ui.dart';
import 'hafal.dart';
import 'murottal_page.dart';
import 'mushaf.dart';
import 'quiz.dart';
import 'tilawah.dart';

// Indeks tab di bawah. Mushaf disisipkan setelah Beranda.
const int kTabHome = 0, kTabMushaf = 1, kTabLearn = 2, kTabLcc = 3, kTabProfile = 4;

class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final pl = Pal.of(context);
        // Ikon Material (bukan emoji): bentuknya sama di semua HP dan punya label teks.
        // const items = [['🏠', 'Beranda'], ['📖', 'Belajar'], ['🏆', 'LCC'], ['👤', 'Profil']];
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: IndexedStack(
              index: app.tab,
              children: const [HomeTab(), MushafTab(), LearnTab(), LccTab(), ProfTab()],
            ),
          ),
          bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
            const PlayerBar(),
            NavigationBar(
              height: 68,
              backgroundColor: pl.card,
              indicatorColor: pl.green.withValues(alpha: .16),
              surfaceTintColor: Colors.transparent,
              selectedIndex: app.tab,
              onDestinationSelected: (i) => app.update(() => app.tab = i),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Beranda'),
                NavigationDestination(
                    icon: Icon(Icons.menu_book_outlined),
                    selectedIcon: Icon(Icons.menu_book),
                    label: 'Mushaf'),
                NavigationDestination(
                    icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Belajar'),
                NavigationDestination(
                    icon: Icon(Icons.emoji_events_outlined),
                    selectedIcon: Icon(Icons.emoji_events),
                    label: 'LCC'),
                NavigationDestination(
                    icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
              ],
            ),
          ]),
        );
      },
    );
  }
}

const EdgeInsets _pagePad = EdgeInsets.fromLTRB(16, 16, 16, 28);

class _Tile extends StatelessWidget {
  // final String emoji; // diganti ikon
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Tile(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: pl.line),
    );
    return FocusRing(
      radius: 16,
      child: Material(
      color: pl.card,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconBadge(icon, size: 38),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
      ),
    );
  }
}

// ================= BERANDA =================
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  void _continueReading(BuildContext context) {
    final c = QuranApi.chapterSync(app.lastSurah);
    if (c != null) {
      openSurah(context, c, ayah: app.lastAyah);
    } else {
      app.update(() => app.tab = kTabMushaf);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final last = QuranApi.chapterSync(app.lastSurah);
        final hasLast = app.lastSurah > 0;
        return ListView(
          padding: _pagePad,
          children: [
            // Kartu sambutan: gradasi hijau tua ke hijau mushaf + garis emas,
            // diambil dari prototype Figma. Satu-satunya gradasi di aplikasi,
            // jadi kartu ini tetap jadi titik fokus beranda.
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [pl.green2, Pal.light.green],
                    ),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: pl.gold, width: 3)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(tanggalHariIni(),
                          style: const TextStyle(color: Color(0xFFE9DFB8), fontSize: 13)),
                      const SizedBox(height: 6),
                      Semantics(
                        header: true,
                        child: Text(
                            app.name.isEmpty
                                ? "Assalamu'alaikum"
                                : "Assalamu'alaikum, ${app.name}",
                            style: serif(24, color: Colors.white)),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Semoga hari ini ringan. Hafalan terjaga oleh pengulangan kecil yang rutin, bukan oleh satu hari yang berat.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
            HCard(
              child: Row(children: [
                Ring(progress: app.today / app.tgt, label: '${app.today}/${app.tgt}'),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Target hafalan hari ini', style: TextStyle(fontWeight: FontWeight.w700)),
                    Muted('${app.today} dari ${app.tgt} ayat'),
                    const SizedBox(height: 6),
                    Text('Total dihafal: ${app.tot} ayat'),
                    Text('Sedang dipelajari: ${surahNameCurrent()}'),
                  ]),
                ),
              ]),
            ),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Dulu: "Progres tilawah 35%" (angka contoh tanpa sumber, antislop R-17).
              // Sekarang: posisi terakhir di Mushaf, yang benar-benar tercatat.
              Expanded(
                child: HCard(
                  onTap: () => _continueReading(context),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Muted('Terakhir dibaca', size: 13),
                    const SizedBox(height: 4),
                    Text(
                      hasLast ? (last?.name ?? 'Surah ${app.lastSurah}') : 'Belum ada',
                      style: serif(19),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Muted(hasLast ? 'Ayat ${app.lastAyah}' : 'Buka Mushaf', size: 13),
                  ]),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: HCard(
                  onTap: () => pushPage(context, const MurajaPage()),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Muted("Perlu muraja'ah", size: 13),
                    const SizedBox(height: 4),
                    Text('${app.pending} ayat', style: serif(19)),
                    Muted(app.pending == 0 ? 'Belum ada' : 'Buka daftar', size: 13),
                  ]),
                ),
              ),
            ]),
            const H4('Lanjutkan'),
            HButton(label: 'Lanjutkan hafalan', onPressed: () => pushPage(context, const HafalPage())),
            HButton(
                label: hasLast ? 'Lanjutkan membaca Mushaf' : 'Mulai membaca Mushaf',
                kind: BK.outline,
                onPressed: () => _continueReading(context)),
            HButton(
                label: "Lanjutkan muraja'ah",
                kind: BK.outline,
                onPressed: () => pushPage(context, const MurajaPage())),
            const H4('Akses cepat'),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.05,
              children: [
                // _Tile('📖', 'Tilawah', ...), _Tile('🏆', 'LCC', ...) // diganti tab Mushaf dan tab LCC
                _Tile(Icons.headphones, 'Murottal', () => pushPage(context, const MurottalPage())),
                _Tile(Icons.psychology_outlined, 'Hafalan', () => pushPage(context, const HafalPage())),
                _Tile(Icons.replay, "Muraja'ah", () => pushPage(context, const MurajaPage())),
                _Tile(Icons.timer_outlined, 'Tilawah berwaktu',
                    () => pushPage(context, const TilawahPage(mode: 'waktu'))),
                _Tile(Icons.palette_outlined, 'Tajwid', () => pushPage(context, const TajwidPage())),
                _Tile(Icons.workspace_premium_outlined, 'Sertifikasi',
                    () => pushPage(context, const SertifikasiPage())),
              ],
            ),
            // Kartu "Pengingat" berisi janji konten yang belum ada, dimatikan (antislop C-3).
            // const HCard(
            //   child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            //     Text('Pengingat', style: TextStyle(fontWeight: FontWeight.w700)),
            //     SizedBox(height: 6),
            //     Muted(
            //         "Kutipan ayat dan hadis akan tampil dengan sumber yang jelas setelah konten diverifikasi. Untuk sementara: sisihkan 10 menit hari ini untuk satu muraja'ah."),
            //   ]),
            // ),
          ],
        );
      },
    );
  }
}

String surahNameCurrent() => surahs[app.currentSurah].n;

// ================= BELAJAR =================
class LearnTab extends StatelessWidget {
  const LearnTab({super.key});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => ListView(
        padding: _pagePad,
        children: [
          Semantics(header: true, child: Text('Belajar', style: serif(24))),
          const SizedBox(height: 4),
          const H4('Tilawah'),
          NavCard(
              icon: Icons.menu_book_outlined,
              title: 'Baca Mushaf',
              sub: '114 surah dengan warna tajwid dan murottal',
              onTap: () => app.update(() => app.tab = kTabMushaf)),
          // NavCard(title: 'Tilawah bebas', sub: 'Pilih surah dan ayat, baca dalam tampilan mushaf',
          //     onTap: () => pushPage(context, const TilawahPage(mode: 'bebas'))), // diganti Baca Mushaf
          NavCard(
              icon: Icons.timer_outlined,
              title: 'Tilawah dengan waktu',
              sub: 'Timer 10, 15, 30, atau 60 menit',
              onTap: () => pushPage(context, const TilawahPage(mode: 'waktu'))),
          NavCard(
              icon: Icons.flag_outlined,
              title: 'Tilawah berdasarkan target',
              sub: 'Target ayat, halaman, atau surah',
              onTap: () => pushPage(context, const TilawahPage(mode: 'target'))),
          NavCard(
              icon: Icons.headphones,
              title: 'Murottal',
              sub: 'Pilih qari, unduh semua, per surah, atau rentang ayat',
              onTap: () => pushPage(context, const MurottalPage())),
          const H4('Hafalan'),
          NavCard(
              icon: Icons.psychology_outlined,
              title: 'Mulai hafalan',
              sub: "Ulangi tiap ayat sambil membaca ke mikrofon, uji, lalu muraja'ah. Focus Mode tersedia.",
              border: pl.gold,
              onTap: () => pushPage(context, const HafalPage())),
          NavCard(
              icon: Icons.replay,
              title: "Muraja'ah",
              sub: app.pending == 0 ? 'Belum ada ayat yang perlu diulang' : '${app.pending} ayat perlu diulang',
              onTap: () => pushPage(context, const MurajaPage())),
          const H4('Tajwid'),
          NavCard(
              icon: Icons.palette_outlined,
              title: 'Belajar tajwid',
              sub: 'Ringkasan hukum bacaan dan latihan',
              onTap: () => pushPage(context, const TajwidPage())),
        ],
      ),
    );
  }
}

// ================= LCC =================
class LccTab extends StatelessWidget {
  const LccTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Ikon dipilih sesuai jenis soal: sambung = rantai, tebak = kaca pembesar,
    // susun = kepingan puzzle, hukum = daftar aturan, tantangan = timer.
    const items = <(IconData, String, String, String)>[
      (Icons.link, 'Sambung Ayat', 'Pilih kelanjutan atau kata yang hilang', 'sambung'),
      (Icons.search, 'Tebak Ayat', 'Tebak surah dan nomor ayat', 'tebak'),
      (Icons.extension_outlined, 'Susun Ayat', 'Urutkan potongan ayat acak', 'susun'),
      (Icons.rule, 'Tebak Hukum Bacaan', 'Nun sukun, mim sukun, mad, dan lainnya', 'hukum'),
      (Icons.timer_outlined, 'Tantangan Waktu', '60 detik, skor, dan streak', 'tantang'),
    ];
    return ListView(
      padding: _pagePad,
      children: [
        Semantics(header: true, child: Text("LCC Al-Qur'an", style: serif(24))),
        const SizedBox(height: 4),
        const Muted('Latihan cerdas cermat dari 5 surah contoh di aplikasi ini.'),
        const SizedBox(height: 12),
        for (final x in items)
          NavCard(
            icon: x.$1,
            title: x.$2,
            sub: x.$3,
            onTap: () => pushPage(context, QuizPage(kind: x.$4)),
          ),
      ],
    );
  }
}

// ================= PROFIL =================
class ProfTab extends StatelessWidget {
  const ProfTab({super.key});

  void _editName(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Pal.of(context).card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => const _NameSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final initials = app.name
            .split(' ')
            .where((w) => w.isNotEmpty)
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join();
        final sc = app.certs.length;
        Widget stat(String v, String l) => Expanded(
              child: HCard(
                child: Column(children: [
                  Text(v, style: serif(19)),
                  Muted(l, size: 13, align: TextAlign.center),
                ]),
              ),
            );
        return ListView(
          padding: _pagePad,
          children: [
            HCard(
              onTap: () => _editName(context),
              child: SizedBox(
                width: double.infinity,
                child: Column(children: [
                  // Avatar inisial dari nama yang diisi sendiri (bukan foto buatan, antislop R-23).
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: pl.green, shape: BoxShape.circle),
                    child: initials.isEmpty
                        ? Icon(Icons.person, size: 36, color: pl.onAccent)
                        : Text(initials, style: serif(28, color: pl.onAccent)),
                  ),
                  const SizedBox(height: 8),
                  Text(app.name.isEmpty ? 'Atur nama panggilan' : app.name, style: serif(19)),
                  // const Muted('ahmad@contoh.id · akun contoh'), // email contoh, belum ada akun
                  Muted(app.name.isEmpty ? 'Ketuk untuk mengisi' : 'Ketuk untuk mengubah nama', size: 13),
                ]),
              ),
            ),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              stat('${app.tot}', 'ayat dihafal'),
              const SizedBox(width: 10),
              // stat('6', 'hari beruntun'), // angka tetap tanpa data (antislop R-17)
              stat('${app.today}', 'ayat hari ini'),
              const SizedBox(width: 10),
              stat('$sc', 'sertifikat'),
            ]),
            const H4('Riwayat aktivitas'),
            HCard(
              child: app.log.isEmpty
                  ? const Muted('Belum ada aktivitas. Riwayat muncul setelah kamu menghafal, tilawah, atau berlatih LCC.')
                  : Column(children: [
                      for (final x in app.log.take(5))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(children: [
                            Expanded(child: Text(x.t)),
                            Muted(x.d, size: 13),
                          ]),
                        ),
                    ]),
            ),
            NavCard(
              icon: Icons.workspace_premium_outlined,
              title: 'Sertifikat saya',
              sub: sc > 0 ? '$sc sertifikat' : 'Belum ada sertifikat',
              onTap: () => pushPage(context, const SertifikasiPage()),
            ),
            const H4('Pengaturan'),
            // Saklar Notifikasi dan Pengingat muraja'ah dimatikan: belum ada notifikasi
            // yang benar-benar dikirim, jadi saklarnya tidak melakukan apa-apa (antislop R-26).
            // TODO: aktifkan lagi setelah notifikasi lokal dibuat.
            // HCard(
            //   child: Column(children: [
            //     Row(children: [
            //       const Expanded(child: Text('Notifikasi')),
            //       HSwitch(value: app.notif, onChanged: (v) => app.update(() => app.notif = v)),
            //     ]),
            //     Row(children: [
            //       const Expanded(child: Text("Pengingat muraja'ah")),
            //       HSwitch(value: app.rem, onChanged: (v) => app.update(() => app.rem = v)),
            //     ]),
            //   ]),
            // ),
            NavCard(
              icon: Icons.record_voice_over_outlined,
              title: 'Qari murottal',
              sub: app.reciterName,
              onTap: () => pushPage(context, const ReciterPage()),
            ),
            HCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Tampilan', style: TextStyle(fontWeight: FontWeight.w700)),
                SpinRow(
                  label: 'Ukuran huruf Arab',
                  value: '${app.arabicSize.round()}',
                  onMinus: () =>
                      app.update(() => app.arabicSize = clampD(app.arabicSize - 2, 22, 44)),
                  onPlus: () =>
                      app.update(() => app.arabicSize = clampD(app.arabicSize + 2, 22, 44)),
                ),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: SizedBox(
                    width: double.infinity,
                    child: Text('ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ',
                        textAlign: TextAlign.center,
                        style: arabic(app.arabicSize, color: pl.text, height: 1.9)),
                  ),
                ),
                const SizedBox(height: 6),
                const Muted('Tema', size: 13),
                const SizedBox(height: 6),
                Wrap(children: [
                  HChip(
                      label: 'Ikuti HP',
                      on: app.themeMode == ThemeMode.system,
                      onTap: () => app.update(() => app.themeMode = ThemeMode.system)),
                  HChip(
                      label: 'Terang',
                      on: app.themeMode == ThemeMode.light,
                      onTap: () => app.update(() => app.themeMode = ThemeMode.light)),
                  HChip(
                      label: 'Gelap',
                      on: app.themeMode == ThemeMode.dark,
                      onTap: () => app.update(() => app.themeMode = ThemeMode.dark)),
                ]),
              ]),
            ),
            const SizedBox(height: 4),
            const Muted(
                "Nama, tampilan, qari, dan posisi baca tersimpan di HP. Riwayat hafalan dan muraja'ah belum tersimpan permanen dan hilang saat aplikasi ditutup.",
                align: TextAlign.center,
                size: 13),
          ],
        );
      },
    );
  }
}

class _NameSheet extends StatefulWidget {
  const _NameSheet();
  @override
  State<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<_NameSheet> {
  late final TextEditingController ctl = TextEditingController(text: app.name);

  @override
  void dispose() {
    ctl.dispose();
    super.dispose();
  }

  void _save() {
    app.update(() => app.name = ctl.text.trim());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Ruang untuk keyboard di layar, supaya kolom nama tidak tertutup.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Nama panggilan', style: serif(19)),
                const SizedBox(height: 4),
                const Muted('Dipakai untuk sapaan di beranda dan sertifikat.', size: 13),
                const SizedBox(height: 12),
                TextField(
                  controller: ctl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 40,
                  decoration: const InputDecoration(labelText: 'Nama', border: OutlineInputBorder()),
                  onSubmitted: (_) => _save(),
                ),
                HButton(label: 'Simpan nama', onPressed: _save),
                HButton(label: 'Batal', kind: BK.outline, onPressed: () => Navigator.of(context).pop()),
              ]),
        ),
      ),
    );
  }
}

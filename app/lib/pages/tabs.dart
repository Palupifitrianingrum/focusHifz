import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data.dart';
import '../theme.dart';
import '../ui.dart';
import 'hafal.dart';
import 'quiz.dart';
import 'tilawah.dart';

class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final pl = Pal.of(context);
        const items = [
          ['🏠', 'Beranda'],
          ['📖', 'Belajar'],
          ['🏆', 'LCC'],
          ['👤', 'Profil'],
        ];
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: IndexedStack(
              index: app.tab,
              children: const [HomeTab(), LearnTab(), LccTab(), ProfTab()],
            ),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: pl.card,
              border: Border(top: BorderSide(color: pl.line)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Row(children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: InkWell(
                        onTap: () => app.update(() => app.tab = i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(items[i][0], style: const TextStyle(fontSize: 21)),
                            Text(items[i][1],
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: app.tab == i ? pl.green : pl.muted)),
                          ]),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }
}

const EdgeInsets _pagePad = EdgeInsets.fromLTRB(16, 16, 16, 28);

class _Tile extends StatelessWidget {
  final String emoji, label;
  final VoidCallback onTap;
  const _Tile(this.emoji, this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: pl.line),
    );
    return Material(
      color: pl.card,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ================= BERANDA =================
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => ListView(
        padding: _pagePad,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [pl.green2, pl.green],
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
                        style: const TextStyle(color: Color(0xFFE9DFB8), fontSize: 12)),
                    const SizedBox(height: 6),
                    Text("Assalamu'alaikum, ${app.name}",
                        style: serif(24, color: Colors.white)),
                    const SizedBox(height: 6),
                    Text(
                      'Semoga hari ini ringan. Hafalan terjaga oleh pengulangan kecil yang rutin, bukan oleh satu hari yang berat.',
                      style: TextStyle(color: Colors.white.withValues(alpha: .9)),
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
                  const Text('Target hari ini', style: TextStyle(fontWeight: FontWeight.w700)),
                  Muted('${app.today} dari ${app.tgt} ayat'),
                  const SizedBox(height: 6),
                  Text('Total dihafal: ${app.tot} ayat'),
                  Text('Sedang dipelajari: ${surahNameCurrent()}'),
                ]),
              ),
            ]),
          ),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: HCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Muted('Progres tilawah', size: 12),
                    const Spacer(),
                    Text('${app.til}%', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ]),
                  HBar(app.til / 100),
                ]),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: HCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Muted("Perlu muraja'ah", size: 12),
                  const SizedBox(height: 4),
                  Text('${app.pending} ayat', style: serif(19)),
                ]),
              ),
            ),
          ]),
          const H4('Lanjutkan'),
          HButton(label: 'Lanjutkan hafalan', onPressed: () => pushPage(context, const HafalPage())),
          HButton(
              label: 'Lanjutkan tilawah',
              kind: BK.outline,
              onPressed: () => pushPage(context, const TilawahPage())),
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
            childAspectRatio: 1.1,
            children: [
              _Tile('📖', 'Tilawah', () => pushPage(context, const TilawahPage())),
              _Tile('🧠', 'Hafalan', () => pushPage(context, const HafalPage())),
              _Tile('🔁', "Muraja'ah", () => pushPage(context, const MurajaPage())),
              _Tile('🏆', 'LCC', () => app.update(() => app.tab = 2)),
              _Tile('✨', 'Tajwid', () => pushPage(context, const TajwidPage())),
              _Tile('🎓', 'Sertifikasi', () => pushPage(context, const SertifikasiPage())),
            ],
          ),
          const SizedBox(height: 14),
          const HCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Pengingat', style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 6),
              Muted(
                  "Kutipan ayat dan hadis akan tampil dengan sumber yang jelas setelah konten diverifikasi. Untuk sementara: sisihkan 10 menit hari ini untuk satu muraja'ah."),
            ]),
          ),
        ],
      ),
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
          Text('Belajar', style: serif(24)),
          const SizedBox(height: 12),
          const H4('Tilawah'),
          NavCard(
              title: 'Tilawah bebas',
              sub: 'Pilih surah dan ayat, baca dalam tampilan mushaf',
              onTap: () => pushPage(context, const TilawahPage(mode: 'bebas'))),
          NavCard(
              title: 'Tilawah dengan waktu',
              sub: 'Timer 10, 15, 30, atau 60 menit',
              onTap: () => pushPage(context, const TilawahPage(mode: 'waktu'))),
          NavCard(
              title: 'Tilawah berdasarkan target',
              sub: 'Target ayat, halaman, atau surah',
              onTap: () => pushPage(context, const TilawahPage(mode: 'target'))),
          const H4('Hafalan'),
          NavCard(
              title: 'Mulai hafalan',
              sub: "Ulangi tiap ayat sambil membaca ke mikrofon, uji, lalu muraja'ah. Focus Mode tersedia.",
              border: pl.gold,
              onTap: () => pushPage(context, const HafalPage())),
          NavCard(
              title: "Muraja'ah",
              sub: '${app.pending} ayat perlu diulang',
              onTap: () => pushPage(context, const MurajaPage())),
          const H4('Tajwid'),
          NavCard(
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
    const items = [
      ['🔗', 'Sambung Ayat', 'Pilih kelanjutan atau kata yang hilang', 'sambung'],
      ['🔍', 'Tebak Ayat', 'Tebak surah dan nomor ayat', 'tebak'],
      ['🧩', 'Susun Ayat', 'Urutkan potongan ayat acak', 'susun'],
      ['📚', 'Tebak Hukum Bacaan', 'Nun sukun, mim sukun, mad, dan lainnya', 'hukum'],
      ['⏱️', 'Tantangan Waktu', '60 detik, skor, dan streak', 'tantang'],
    ];
    return ListView(
      padding: _pagePad,
      children: [
        Text("LCC Al-Qur'an", style: serif(24)),
        const SizedBox(height: 4),
        const Muted('Latihan cerdas cermat dengan surah contoh di aplikasi ini.'),
        const SizedBox(height: 12),
        for (final x in items)
          NavCard(
            emoji: x[0],
            title: x[1],
            sub: x[2],
            onTap: () => pushPage(context, QuizPage(kind: x[3])),
          ),
      ],
    );
  }
}

// ================= PROFIL =================
class ProfTab extends StatelessWidget {
  const ProfTab({super.key});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final initials = app.name.split(' ').where((w) => w.isNotEmpty).map((w) => w[0]).join();
        final sc = app.certs.length;
        Widget stat(String v, String l) => Expanded(
              child: HCard(
                child: Column(children: [
                  Text(v, style: serif(19)),
                  Muted(l, size: 12, align: TextAlign.center),
                ]),
              ),
            );
        return ListView(
          padding: _pagePad,
          children: [
            HCard(
              child: SizedBox(
                width: double.infinity,
                child: Column(children: [
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: pl.green, shape: BoxShape.circle),
                    child: Text(initials, style: serif(28, color: Colors.white)),
                  ),
                  const SizedBox(height: 8),
                  Text(app.name, style: serif(19)),
                  const Muted('ahmad@contoh.id · akun contoh'),
                ]),
              ),
            ),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              stat('${app.tot}', 'ayat hafal'),
              const SizedBox(width: 10),
              stat('6', 'hari beruntun'),
              const SizedBox(width: 10),
              stat('$sc', 'sertifikat'),
            ]),
            const H4('Riwayat aktivitas'),
            HCard(
              child: Column(children: [
                for (final x in app.log.take(5))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(children: [
                      Expanded(child: Text(x.t)),
                      Muted(x.d, size: 12),
                    ]),
                  ),
              ]),
            ),
            NavCard(
              title: 'Sertifikat saya',
              sub: sc > 0 ? '$sc sertifikat' : 'Belum ada sertifikat',
              onTap: () => pushPage(context, const SertifikasiPage()),
            ),
            const H4('Pengaturan'),
            HCard(
              child: Column(children: [
                Row(children: [
                  const Expanded(child: Text('Notifikasi')),
                  HSwitch(value: app.notif, onChanged: (v) => app.update(() => app.notif = v)),
                ]),
                Row(children: [
                  const Expanded(child: Text("Pengingat muraja'ah")),
                  HSwitch(value: app.rem, onChanged: (v) => app.update(() => app.rem = v)),
                ]),
              ]),
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
                const SizedBox(height: 6),
                Wrap(children: [
                  HChip(
                      label: 'Otomatis',
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
            const Muted('HifzFlow · data contoh', align: TextAlign.center, size: 13),
          ],
        );
      },
    );
  }
}

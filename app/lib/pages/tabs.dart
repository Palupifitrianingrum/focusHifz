import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data.dart';
import '../theme.dart';
import '../ui.dart';
import 'hafal.dart';
import 'quiz.dart';
import 'tilawah.dart';

class _NavItem {
  final String label;
  final IconData icon, activeIcon;
  const _NavItem(this.label, this.icon, this.activeIcon);
}

const List<_NavItem> _navItems = [
  _NavItem('Beranda', Icons.home_outlined, Icons.home_rounded),
  _NavItem('Belajar', Icons.menu_book_outlined, Icons.menu_book_rounded),
  _NavItem('LCC', Icons.emoji_events_outlined, Icons.emoji_events_rounded),
  _NavItem('Profil', Icons.person_outline_rounded, Icons.person_rounded),
];

class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final pl = Pal.of(context);
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
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Row(children: [
                      for (var i = 0; i < _navItems.length; i++)
                        Expanded(child: _NavButton(_navItems[i], app.tab == i, () {
                          app.update(() => app.tab = i);
                        })),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool on;
  final VoidCallback onTap;
  const _NavButton(this.item, this.on, this.onTap);

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return Semantics(
      button: true,
      selected: on,
      label: item.label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(Rad.control + 2),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 52,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? pl.green : Colors.transparent,
                borderRadius: BorderRadius.circular(Rad.control),
              ),
              child: Icon(on ? item.activeIcon : item.icon,
                  size: 22, color: on ? pl.onGreen : pl.muted),
            ),
            const SizedBox(height: 3),
            Text(item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: sans(12,
                    weight: on ? FontWeight.w700 : FontWeight.w600,
                    color: on ? pl.text : pl.muted)),
          ]),
        ),
      ),
    );
  }
}

String surahNameCurrent() => surahs[app.currentSurah].n;

String _initials(String name) =>
    name.split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0]).join();

class _Avatar extends StatelessWidget {
  final double size;
  const _Avatar(this.size);

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: pl.green2,
          shape: BoxShape.circle,
          border: Border.all(color: pl.gold, width: 2),
        ),
        child: Text(_initials(app.name), style: serif(size * .38, color: pl.onHero)),
      ),
    );
  }
}

// ================= BERANDA =================
class _Quick extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Quick(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(Rad.card),
        onTap: onTap,
        child: SizedBox(
          width: 82,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(children: [
              RubIcon(icon, size: 58),
              const SizedBox(height: 8),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: sans(12.5, weight: FontWeight.w600)),
            ]),
          ),
        ),
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  Widget _hero(BuildContext context, Pal pl) {
    return Container(
      decoration: BoxDecoration(color: pl.green2, borderRadius: BorderRadius.circular(Rad.hero)),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        Positioned(
          right: -40,
          top: -40,
          child: ExcludeSemantics(
            child: Opacity(
              opacity: .14,
              child: RubBadge(size: 170, fill: pl.gold, child: const SizedBox.shrink()),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hafalan hari ini',
                style: sans(13, weight: FontWeight.w600, color: pl.onHero.withValues(alpha: .85))),
            const SizedBox(height: 14),
            Row(children: [
              Ring(
                progress: app.today / app.tgt,
                label: '${app.today}/${app.tgt}',
                size: 96,
                color: pl.gold,
                track: Colors.white.withValues(alpha: .16),
                textColor: pl.onHero,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Sedang dipelajari',
                      style: sans(12.5, color: pl.onHero.withValues(alpha: .85))),
                  const SizedBox(height: 2),
                  Text(surahNameCurrent(), style: serif(27, color: pl.onHero)),
                  const SizedBox(height: 8),
                  Text('${app.today} dari ${app.tgt} ayat target',
                      style: sans(13, color: pl.onHero)),
                  Text('Total dihafal: ${app.tot} ayat', style: sans(13, color: pl.onHero)),
                ]),
              ),
            ]),
            const SizedBox(height: 6),
            HButton(
              label: 'Lanjutkan hafalan',
              kind: BK.gold,
              onPressed: () => pushPage(context, const HafalPage()),
            ),
          ]),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final pending = app.muraja.where((x) => x.st != 'lancar').toList();
        const stName = {'ulang': 'Perlu diulang', 'belajar': 'Dipelajari', 'lancar': 'Lancar'};
        const stKind = {'ulang': 'r', 'belajar': 'y', 'lancar': 'g'};
        return PageList(
          children: [
            Row(children: [
              const _Avatar(50),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tanggalHariIni(), style: sans(12.5, color: pl.muted)),
                  const SizedBox(height: 2),
                  Text("Assalamu'alaikum,", style: sans(13.5, color: pl.muted)),
                  Text(app.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: serif(21)),
                ]),
              ),
              const SizedBox(width: 8),
              Stack(clipBehavior: Clip.none, children: [
                HIconBtn(
                  icon: Icons.repeat_rounded,
                  label: "Muraja'ah, ${app.pending} ayat perlu diulang",
                  onTap: () => pushPage(context, const MurajaPage()),
                ),
                if (app.pending > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: ExcludeSemantics(
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: pl.green2,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: pl.bg, width: 2)),
                        child: Text('${app.pending}',
                            style: sans(11, weight: FontWeight.w700, color: pl.onHero)),
                      ),
                    ),
                  ),
              ]),
            ]),
            const SizedBox(height: 20),
            _hero(context, pl),
            const H4('Akses cepat'),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _Quick(Icons.menu_book_outlined, 'Tilawah',
                    () => pushPage(context, const TilawahPage())),
                _Quick(Icons.record_voice_over_outlined, 'Hafalan',
                    () => pushPage(context, const HafalPage())),
                _Quick(Icons.repeat_rounded, "Muraja'ah",
                    () => pushPage(context, const MurajaPage())),
                _Quick(Icons.emoji_events_outlined, 'LCC', () => app.update(() => app.tab = 2)),
                _Quick(Icons.graphic_eq_rounded, 'Tajwid',
                    () => pushPage(context, const TajwidPage())),
                _Quick(Icons.workspace_premium_outlined, 'Sertifikasi',
                    () => pushPage(context, const SertifikasiPage())),
              ]),
            ),
            const SizedBox(height: 10),
            HCard(
              onTap: () => pushPage(context, const TilawahPage()),
              child: Row(children: [
                const RubIcon(Icons.auto_stories_outlined, size: 46),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(
                          child: Text('Progres tilawah',
                              style: sans(14.5, weight: FontWeight.w700))),
                      Text('${app.til}%', style: serif(18)),
                    ]),
                    HBar(app.til / 100),
                  ]),
                ),
              ]),
            ),
            H4("Perlu muraja'ah",
                action: pending.isEmpty ? null : 'Lihat semua',
                onAction: () => pushPage(context, const MurajaPage())),
            if (pending.isEmpty)
              const HCard(
                child: EmptyState(
                  icon: Icons.task_alt_rounded,
                  title: 'Semua ayat sudah lancar',
                  body: "Tidak ada ayat yang menunggu muraja'ah saat ini.",
                ),
              )
            else
              for (final x in pending.take(3))
                HCard(
                  onTap: () => pushPage(context, const MurajaPage()),
                  child: Row(children: [
                    RubBadge(
                      size: 46,
                      fill: pl.card2,
                      child: Text('${x.n}', style: serif(15, color: pl.green)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${surahs[x.s].n} : ${x.n}',
                            style: sans(14.5, weight: FontWeight.w700)),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: SizedBox(
                            width: double.infinity,
                            child: Text(surahs[x.s].a[x.n - 1],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: arabic(20, color: pl.text, height: 1.7)),
                          ),
                        ),
                        Muted('Jadwal: ${x.due}', size: 12.5),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    Bdg(stName[x.st] ?? '', kind: stKind[x.st] ?? ''),
                  ]),
                ),
            const SizedBox(height: 6),
            const StatusNote(
              kind: SK.info,
              title: 'Pengingat',
              body:
                  "Kutipan ayat dan hadis akan tampil dengan sumber yang jelas setelah konten diverifikasi. Untuk sementara: sisihkan 10 menit hari ini untuk satu muraja'ah.",
            ),
          ],
        );
      },
    );
  }
}

// ================= BELAJAR =================
class LearnTab extends StatelessWidget {
  const LearnTab({super.key});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => PageList(
        children: [
          Text('Belajar', style: serif(30)),
          const SizedBox(height: 4),
          const Muted('Pilih cara belajar yang sesuai dengan waktumu hari ini.'),
          const H4('Hafalan'),
          HCard(
            color: pl.green2,
            border: pl.green2,
            padding: const EdgeInsets.all(20),
            onTap: () => pushPage(context, const HafalPage()),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                RubIcon(Icons.record_voice_over_outlined,
                    size: 50, fill: pl.gold, color: const Color(0xFF2A2108)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text('Mulai hafalan', style: serif(22, color: pl.onHero)),
                ),
              ]),
              const SizedBox(height: 12),
              Text(
                "Ulangi tiap ayat sambil membaca ke mikrofon, uji, lalu muraja'ah. Focus Mode tersedia.",
                style: sans(14, color: pl.onHero, height: 1.5),
              ),
            ]),
          ),
          NavCard(
              icon: Icons.repeat_rounded,
              title: "Muraja'ah",
              sub: '${app.pending} ayat perlu diulang',
              onTap: () => pushPage(context, const MurajaPage())),
          const H4('Tilawah'),
          NavCard(
              icon: Icons.menu_book_outlined,
              title: 'Tilawah bebas',
              sub: 'Pilih surah dan ayat, baca dalam tampilan mushaf',
              onTap: () => pushPage(context, const TilawahPage(mode: 'bebas'))),
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
          const H4('Tajwid'),
          NavCard(
              icon: Icons.graphic_eq_rounded,
              title: 'Belajar tajwid',
              sub: 'Ringkasan hukum bacaan dan latihan',
              onTap: () => pushPage(context, const TajwidPage())),
        ],
      ),
    );
  }
}

// ================= LCC =================
class _LccTile extends StatelessWidget {
  final IconData icon;
  final String title, sub, kind;
  const _LccTile(this.icon, this.title, this.sub, this.kind);

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    return HCard(
      margin: EdgeInsets.zero,
      onTap: () => pushPage(context, QuizPage(kind: kind)),
      child: SizedBox(
        width: double.infinity,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RubIcon(icon, size: 48),
          const SizedBox(height: 14),
          Text(title, style: sans(15, weight: FontWeight.w700, height: 1.25)),
          const SizedBox(height: 4),
          Text(sub, style: sans(12.5, color: pl.muted, height: 1.4)),
        ]),
      ),
    );
  }
}

class LccTab extends StatelessWidget {
  const LccTab({super.key});

  @override
  Widget build(BuildContext context) {
    final pl = Pal.of(context);
    Widget pair(Widget a, Widget b) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: a),
              const SizedBox(width: 12),
              Expanded(child: b),
            ]),
          ),
        );
    return PageList(
      children: [
        Text("LCC Al-Qur'an", style: serif(30)),
        const SizedBox(height: 4),
        const Muted('Latihan cerdas cermat dengan surah contoh di aplikasi ini.'),
        const SizedBox(height: 18),
        pair(
          const _LccTile(Icons.link_rounded, 'Sambung Ayat',
              'Pilih kelanjutan atau kata yang hilang', 'sambung'),
          const _LccTile(Icons.manage_search_rounded, 'Tebak Ayat',
              'Tebak surah dan nomor ayat', 'tebak'),
        ),
        pair(
          const _LccTile(Icons.view_week_outlined, 'Susun Ayat',
              'Urutkan potongan ayat acak', 'susun'),
          const _LccTile(Icons.spellcheck_rounded, 'Tebak Hukum Bacaan',
              'Nun sukun, mim sukun, mad, dan lainnya', 'hukum'),
        ),
        HCard(
          color: pl.green2,
          border: pl.green2,
          padding: const EdgeInsets.all(20),
          onTap: () => pushPage(context, const QuizPage(kind: 'tantang')),
          child: Row(children: [
            RubIcon(Icons.timer_outlined,
                size: 52, fill: pl.gold, color: const Color(0xFF2A2108)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tantangan Waktu', style: serif(21, color: pl.onHero)),
                const SizedBox(height: 4),
                Text('60 detik, skor, dan streak', style: sans(13.5, color: pl.onHero)),
              ]),
            ),
            Icon(Icons.chevron_right_rounded, color: pl.onHero),
          ]),
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
        final sc = app.certs.length;
        Widget stat(String v, String l) => Expanded(
              child: HCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(children: [
                    Text(v, style: serif(24)),
                    const SizedBox(height: 4),
                    Muted(l, size: 12, align: TextAlign.center),
                  ]),
                ),
              ),
            );
        return PageList(
          children: [
            Center(child: _Avatar(84)),
            const SizedBox(height: 12),
            Center(child: Text(app.name, style: serif(24), textAlign: TextAlign.center)),
            const SizedBox(height: 2),
            const Center(child: Muted('ahmad@contoh.id · akun contoh')),
            const SizedBox(height: 20),
            IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                stat('${app.tot}', 'ayat hafal'),
                const SizedBox(width: 10),
                stat('6', 'hari beruntun (contoh)'),
                const SizedBox(width: 10),
                stat('$sc', 'sertifikat'),
              ]),
            ),
            const H4('Riwayat aktivitas'),
            if (app.log.isEmpty)
              const HCard(
                child: EmptyState(
                  icon: Icons.history_rounded,
                  title: 'Belum ada aktivitas',
                  body: 'Sesi hafalan, tilawah, dan kuis yang selesai akan tercatat di sini.',
                ),
              )
            else
              HCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(children: [
                  for (var i = 0; i < app.log.take(5).length; i++) ...[
                    if (i > 0) Divider(height: 1, color: pl.line),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(child: Text(app.log[i].t, style: sans(14))),
                        const SizedBox(width: 10),
                        Muted(app.log[i].d, size: 12),
                      ]),
                    ),
                  ],
                ]),
              ),
            NavCard(
              icon: Icons.workspace_premium_outlined,
              title: 'Sertifikat saya',
              sub: sc > 0 ? '$sc sertifikat' : 'Belum ada sertifikat',
              onTap: () => pushPage(context, const SertifikasiPage()),
            ),
            const H4('Pengaturan'),
            HCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(children: [
                SwitchRow(
                    label: 'Notifikasi',
                    value: app.notif,
                    onChanged: (v) => app.update(() => app.notif = v)),
                Divider(height: 1, color: pl.line),
                SwitchRow(
                    label: "Pengingat muraja'ah",
                    value: app.rem,
                    onChanged: (v) => app.update(() => app.rem = v)),
              ]),
            ),
            HCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tampilan', style: sans(15, weight: FontWeight.w700)),
                const SizedBox(height: 10),
                Seg(
                  labels: const ['Otomatis', 'Terang', 'Gelap'],
                  index: app.themeMode == ThemeMode.system
                      ? 0
                      : (app.themeMode == ThemeMode.light ? 1 : 2),
                  onChanged: (i) => app.update(() => app.themeMode =
                      i == 0 ? ThemeMode.system : (i == 1 ? ThemeMode.light : ThemeMode.dark)),
                ),
                SpinRow(
                  label: 'Ukuran huruf Arab',
                  value: '${app.arabicSize.round()}',
                  onMinus: () =>
                      app.update(() => app.arabicSize = clampD(app.arabicSize - 2, 22, 44)),
                  onPlus: () =>
                      app.update(() => app.arabicSize = clampD(app.arabicSize + 2, 22, 44)),
                ),
                Mushaf(child: AyatText(s: 0, from: 1, to: 1)),
              ]),
            ),
            const SizedBox(height: 4),
            const Muted('HifzFlow · data contoh', align: TextAlign.center, size: 13),
          ],
        );
      },
    );
  }
}

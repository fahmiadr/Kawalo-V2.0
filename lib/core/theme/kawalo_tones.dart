import 'package:flutter/material.dart';

/// One task colour: [color] fills the primary action, [on] is the content on
/// it, [soft] tints icons and active markers.
@immutable
class KawaloTone {
  const KawaloTone({required this.color, required this.on, required this.soft});

  final Color color;
  final Color on;
  final Color soft;

  KawaloTone lerpTo(KawaloTone other, double t) => KawaloTone(
    color: Color.lerp(color, other.color, t)!,
    on: Color.lerp(on, other.on, t)!,
    soft: Color.lerp(soft, other.soft, t)!,
  );

  @override
  bool operator ==(Object other) =>
      other is KawaloTone &&
      other.color == color &&
      other.on == on &&
      other.soft == soft;

  @override
  int get hashCode => Object.hash(color, on, soft);
}

/// Redesign 2026 tokens ("satu halaman, satu tugas"), copied from
/// `Task/redesign/lib.py` (`rd.css`): one tone per task plus the neutral
/// surfaces the redesigned screens are drawn on. A task colour is only a
/// secondary cue; always pair it with the task's icon and name.
///
/// Installed on `AppTheme.lightThemeData()`/`darkThemeData()`. Read it with
/// [KawaloTones.of], which falls back to the built-in set for the current
/// brightness when a test theme does not carry the extension.
@immutable
class KawaloTones extends ThemeExtension<KawaloTones> {
  const KawaloTones({
    required this.background,
    required this.surface,
    required this.surface2,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.line,
    required this.ptt,
    required this.sos,
    required this.inc,
    required this.pat,
    required this.abs,
    required this.gst,
    required this.adm,
    required this.ok,
    required this.okSoft,
    required this.warn,
    required this.warnSoft,
  });

  /// Page background (`--p-bg`).
  final Color background;
  final Color surface;
  final Color surface2;
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color line;

  /// Brand green: PTT, Informasi and app-wide primary actions.
  final KawaloTone ptt;

  /// SOS, and destructive actions.
  final KawaloTone sos;
  final KawaloTone inc;

  /// Patroli and Jadwal.
  final KawaloTone pat;

  /// Absensi and the "Lainnya" card.
  final KawaloTone abs;
  final KawaloTone gst;

  /// Admin-only "Kelola" screens.
  final KawaloTone adm;

  final Color ok;
  final Color okSoft;
  final Color warn;
  final Color warnSoft;

  static const light = KawaloTones(
    background: Color(0xFFF5F8F3),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFE8EEE7),
    ink: Color(0xFF16201A),
    ink2: Color(0xFF4B584E),
    ink3: Color(0xFF7A867C),
    line: Color(0xFFD4DDD3),
    ptt: KawaloTone(
      color: Color(0xFF316A42),
      on: Color(0xFFFFFFFF),
      soft: Color(0xFFCDEBD4),
    ),
    sos: KawaloTone(
      color: Color(0xFFB3261E),
      on: Color(0xFFFFFFFF),
      soft: Color(0xFFF9DEDC),
    ),
    inc: KawaloTone(
      color: Color(0xFF8A4B00),
      on: Color(0xFFFFFFFF),
      soft: Color(0xFFFFE2C2),
    ),
    pat: KawaloTone(
      color: Color(0xFF2D5B7B),
      on: Color(0xFFFFFFFF),
      soft: Color(0xFFD4E5F1),
    ),
    abs: KawaloTone(
      color: Color(0xFF5A5810),
      on: Color(0xFFFFFFFF),
      soft: Color(0xFFECE9BE),
    ),
    gst: KawaloTone(
      color: Color(0xFF6B4F35),
      on: Color(0xFFFFFFFF),
      soft: Color(0xFFF0E1D2),
    ),
    adm: KawaloTone(
      color: Color(0xFF3B4A42),
      on: Color(0xFFFFFFFF),
      soft: Color(0xFFDCE5DF),
    ),
    ok: Color(0xFF2E7D32),
    okSoft: Color(0xFFD7EFD8),
    warn: Color(0xFF8A5A00),
    warnSoft: Color(0xFFFFE6BF),
  );

  static const dark = KawaloTones(
    background: Color(0xFF101612),
    surface: Color(0xFF171E19),
    surface2: Color(0xFF222A24),
    ink: Color(0xFFE1EAE2),
    ink2: Color(0xFFA6B4A9),
    ink3: Color(0xFF83908A),
    line: Color(0xFF323D35),
    ptt: KawaloTone(
      color: Color(0xFF97D5A5),
      on: Color(0xFF00391B),
      soft: Color(0xFF1C4B2B),
    ),
    sos: KawaloTone(
      color: Color(0xFFFFB4AB),
      on: Color(0xFF690005),
      soft: Color(0xFF5A1A15),
    ),
    inc: KawaloTone(
      color: Color(0xFFFFB870),
      on: Color(0xFF4A2800),
      soft: Color(0xFF4A2A06),
    ),
    pat: KawaloTone(
      color: Color(0xFF9CCAEA),
      on: Color(0xFF0C324A),
      soft: Color(0xFF16364C),
    ),
    abs: KawaloTone(
      color: Color(0xFFD9D57C),
      on: Color(0xFF323100),
      soft: Color(0xFF3A3906),
    ),
    gst: KawaloTone(
      color: Color(0xFFE4C2A3),
      on: Color(0xFF3B2410),
      soft: Color(0xFF43301F),
    ),
    adm: KawaloTone(
      color: Color(0xFFB9CBC0),
      on: Color(0xFF1F2B24),
      soft: Color(0xFF2B3630),
    ),
    ok: Color(0xFF8FD694),
    okSoft: Color(0xFF1D3B20),
    warn: Color(0xFFF2BE6B),
    warnSoft: Color(0xFF4A3300),
  );

  static KawaloTones of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<KawaloTones>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  KawaloTones copyWith() => this;

  @override
  KawaloTones lerp(KawaloTones? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    KawaloTone k(KawaloTone a, KawaloTone b) => a.lerpTo(b, t);
    return KawaloTones(
      background: c(background, other.background),
      surface: c(surface, other.surface),
      surface2: c(surface2, other.surface2),
      ink: c(ink, other.ink),
      ink2: c(ink2, other.ink2),
      ink3: c(ink3, other.ink3),
      line: c(line, other.line),
      ptt: k(ptt, other.ptt),
      sos: k(sos, other.sos),
      inc: k(inc, other.inc),
      pat: k(pat, other.pat),
      abs: k(abs, other.abs),
      gst: k(gst, other.gst),
      adm: k(adm, other.adm),
      ok: c(ok, other.ok),
      okSoft: c(okSoft, other.okSoft),
      warn: c(warn, other.warn),
      warnSoft: c(warnSoft, other.warnSoft),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/features/home/domain/entities/home_layout.dart';

extension HomeCardUi on HomeCard {
  /// Bottom-bar label; also the name in "Atur Beranda".
  String get label => switch (this) {
    HomeCard.ptt => 'PTT',
    HomeCard.sos => 'SOS',
    HomeCard.inc => 'Insiden',
    HomeCard.pat => 'Patroli',
    HomeCard.gst => 'Buku Tamu',
    HomeCard.sch => 'Jadwal',
  };

  String get description => switch (this) {
    HomeCard.ptt => 'Bicara ke semua anggota grup',
    HomeCard.sos => 'Selalu tampil (keselamatan)',
    HomeCard.inc => 'Laporkan kejadian dengan foto',
    HomeCard.pat => 'Absen di tiap titik',
    HomeCard.gst => 'Catat tamu yang datang',
    HomeCard.sch => 'Lihat jadwal shift Anda',
  };

  IconData get icon => switch (this) {
    HomeCard.ptt => Icons.mic_none_rounded,
    HomeCard.sos => Icons.warning_amber_rounded,
    HomeCard.inc => Icons.feedback_outlined,
    HomeCard.pat => Icons.location_on_outlined,
    HomeCard.gst => Icons.menu_book_outlined,
    HomeCard.sch => Icons.calendar_month_outlined,
  };

  KawaloTone tone(KawaloTones tones) => switch (this) {
    HomeCard.ptt => tones.ptt,
    HomeCard.sos => tones.sos,
    HomeCard.inc => tones.inc,
    HomeCard.pat || HomeCard.sch => tones.pat,
    HomeCard.gst => tones.gst,
  };
}

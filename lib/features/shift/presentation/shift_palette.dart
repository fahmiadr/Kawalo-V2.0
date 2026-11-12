import 'package:flutter/material.dart';

/// Colours an admin can give a shift. Fixed and purple-free (the app never
/// shows purple); readable on light and dark surfaces.
class ShiftSwatch {
  const ShiftSwatch(this.hex, this.name);

  final String hex;
  final String name;

  Color get color => Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));
}

const shiftPalette = [
  ShiftSwatch('#F2A900', 'Kuning'),
  ShiftSwatch('#E8710A', 'Oranye'),
  ShiftSwatch('#C62828', 'Merah'),
  ShiftSwatch('#8D6E4F', 'Cokelat'),
  ShiftSwatch('#2E8B57', 'Hijau'),
  ShiftSwatch('#0F8B8D', 'Teal'),
  ShiftSwatch('#2F6FB3', 'Biru'),
  ShiftSwatch('#546E7A', 'Abu-abu biru'),
];

/// Icon colour that stays readable on a shift-coloured tile.
Color onShiftColor(Color background) => background.computeLuminance() > 0.4
    ? const Color(0xFF181D18)
    : Colors.white;

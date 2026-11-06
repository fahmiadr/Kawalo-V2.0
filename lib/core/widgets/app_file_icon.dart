import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';

/// Widget representasi ikon berkas standar dan resmi (Official Document Badge).
///
/// Mematuhi warna resmi dokumen (Adobe Red untuk PDF, Word Blue untuk DOC,
/// Excel Green untuk XLS, PowerPoint Orange untuk PPT, dsb.) dengan lipatan
/// sudut standar (dog-ear flap).
class AppFileIcon extends StatelessWidget {
  /// Membuat instance [AppFileIcon].
  const AppFileIcon({
    required this.extension,
    this.width = 42,
    this.height = 50,
    super.key,
  });

  /// Ekstensi dokumen (misal: 'pdf', 'docx', 'xlsx', 'txt', dsb.).
  final String extension;

  /// Lebar widget ikon berkas dalam satuan dp (default: 42).
  final double width;

  /// Tinggi widget ikon berkas dalam satuan dp (default: 50).
  final double height;

  Color _getBadgeColor() {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return const Color(0xFFD32F2F); // Official Adobe PDF Red
      case 'doc':
      case 'docx':
        return const Color(0xFF1565C0); // Official Microsoft Word Blue
      case 'xls':
      case 'xlsx':
      case 'csv':
        return const Color(0xFF2E7D32); // Official Excel Green
      case 'ppt':
      case 'pptx':
        return const Color(0xFFD84315); // Official PowerPoint Orange
      case 'txt':
      case 'json':
      case 'log':
      case 'md':
      case 'xml':
        return const Color(0xFF455A64); // Slate Grey
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
        return const Color(0xFF7B1FA2); // Archive Violet
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
      case 'gif':
        return const Color(0xFF00838F); // Image Cyan
      default:
        return const Color(0xFF546E7A); // Neutral Blue-Grey
    }
  }

  String _getBadgeLabel() {
    if (extension.isEmpty) return 'FILE';
    final upper = extension.toUpperCase();
    if (upper.length <= 4) return upper;
    return upper.substring(0, 4);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final badgeColor = _getBadgeColor();
    final badgeLabel = _getBadgeLabel();

    return Semantics(
      label: 'Ikon format berkas $badgeLabel',
      container: true,
      child: CustomPaint(
        size: Size(width, height),
        painter: AppFileBadgePainter(color: badgeColor),
        child: SizedBox(
          width: width,
          height: height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: height * 0.14),
                child: Center(
                  child: Text(
                    badgeLabel,
                    style: theme.typography.emphasized.labelSmall.copyWith(
                      color: Colors.white,
                      fontSize: (width * 0.238).clamp(8.0, 12.0),
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// CustomPainter untuk menggambar dokumen dengan sudut terlipat (dog-ear flap).
class AppFileBadgePainter extends CustomPainter {
  /// Membuat instance [AppFileBadgePainter].
  const AppFileBadgePainter({required this.color});

  /// Warna latar belakang badge berkas.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final foldSize = size.width * 0.26;
    final cornerRadius = (size.width * 0.14).clamp(4.0, 8.0);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(cornerRadius, 0)
      ..lineTo(size.width - foldSize, 0)
      ..lineTo(size.width, foldSize)
      ..lineTo(size.width, size.height - cornerRadius)
      ..quadraticBezierTo(
        size.width,
        size.height,
        size.width - cornerRadius,
        size.height,
      )
      ..lineTo(cornerRadius, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - cornerRadius)
      ..lineTo(0, cornerRadius)
      ..quadraticBezierTo(0, 0, cornerRadius, 0)
      ..close();

    canvas.drawPath(path, paint);

    // Lipatan sudut kanan atas (Folded Corner Dog-Ear)
    final foldPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final foldPath = Path()
      ..moveTo(size.width - foldSize, 0)
      ..lineTo(size.width - foldSize, foldSize)
      ..lineTo(size.width, foldSize)
      ..close();

    canvas.drawPath(foldPath, foldPaint);

    // Garis lipatan halus
    final foldLinePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas
      ..drawLine(
        Offset(size.width - foldSize, 0),
        Offset(size.width - foldSize, foldSize),
        foldLinePaint,
      )
      ..drawLine(
        Offset(size.width - foldSize, foldSize),
        Offset(size.width, foldSize),
        foldLinePaint,
      );
  }

  @override
  bool shouldRepaint(covariant AppFileBadgePainter oldDelegate) =>
      oldDelegate.color != color;
}

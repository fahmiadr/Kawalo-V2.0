import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_image_placeholder.dart';

class GroupLogo extends StatelessWidget {
  const GroupLogo({required this.logoUrl, required this.groupName, super.key});

  final String? logoUrl;
  final String groupName;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(child: _buildVisual());
  }

  Widget _buildVisual() {
    final url = logoUrl;
    if (url != null &&
        url.isNotEmpty &&
        (url.startsWith('http://') || url.startsWith('https://'))) {
      return ClipRRect(
        borderRadius: AppRadius.borderMedium,
        child: Image.network(
          url,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallback(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildFallback();
          },
        ),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    return AppImagePlaceholder(
      width: 48,
      height: 48,
      borderRadius: AppRadius.borderMedium,
      icon: Image.asset(
        KawaloColorVectors.group2,
        width: 32,
        height: 32,
        fit: BoxFit.contain,
      ),
      semanticLabel: 'Identitas $groupName',
    );
  }
}

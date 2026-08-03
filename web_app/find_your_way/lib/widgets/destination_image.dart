import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';

/// Renders a destination photo, falling back to a branded gradient tile
/// with a category icon when no image is available or the network request
/// fails — several seed destinations intentionally ship without a photo.
class DestinationImage extends StatelessWidget {
  final String? path;
  final String category;
  final BoxFit fit;

  const DestinationImage({super.key, required this.path, required this.category, this.fit = BoxFit.cover});

  IconData get _categoryIcon {
    switch (category) {
      case 'Hotel':
        return Icons.hotel_rounded;
      case 'Restaurant':
        return Icons.restaurant_rounded;
      case 'Nature':
        return Icons.park_rounded;
      case 'Landmark':
        return Icons.account_balance_rounded;
      case 'Museum':
        return Icons.museum_rounded;
      case 'Market':
        return Icons.storefront_rounded;
      case 'Shopping & Entertainment':
        return Icons.theater_comedy_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.isEmpty) {
      return _fallback();
    }

    return Image.network(
      '$assetBaseUrl$path',
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.border.withValues(alpha: 0.4),
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.primary),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      alignment: Alignment.center,
      child: Icon(_categoryIcon, color: Colors.white.withValues(alpha: 0.85), size: 36),
    );
  }
}

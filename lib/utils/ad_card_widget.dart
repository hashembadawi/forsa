

// All imports must be at the very top
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../screens/ad_details_screen.dart';
import '../screens/home_screen.dart' as home;

typedef FavoriteIconBuilder = Widget Function(String adId, {
  required bool isFavorite,
  required bool isLoggedIn,
  required bool isLoading,
});

/// Default favorite heart icon builder
Widget defaultFavoriteHeartIcon(
  String adId, {
  required bool isFavorite,
  required bool isLoggedIn,
  required bool isLoading,
}) {
  return Container(
    width: 32,
    height: 32,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.9),
      shape: BoxShape.circle,
      // No shadow
    ),
    child: (isLoggedIn && isLoading)
        ? const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
            ),
          )
        : Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.red : Colors.grey[600],
            size: 20,
          ),
  );
}


class AdCardWidget extends StatelessWidget {
  final home.AdModel ad;
  final Widget Function(home.AdModel ad)? adDetailsBuilder;
  final Widget Function(String adId)? favoriteIconBuilder;
  final VoidCallback? onTap;

  const AdCardWidget({
    super.key,
    required this.ad,
    this.adDetailsBuilder,
    this.favoriteIconBuilder,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final images = ad.images ?? [];
    final firstImageBase64 = images.isNotEmpty ? images[0] : null;
    final String adId = ad.id ?? '';
    final bool isSpecial = ad.isSpecial ?? false;


    Widget _buildNoImagePlaceholder() {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0F8FF), Color(0xFFE6F3FF)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, size: 40, color: Colors.blue[400]),
              const SizedBox(height: 4),
              Text(
                'لا توجد صورة',
                style: GoogleFonts.cairo(
                  color: Colors.blue[700],
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildAdImage(String? firstImageBase64) {
      if (firstImageBase64 != null) {
        try {
          final decodedImage = base64Decode(firstImageBase64);
          return Image.memory(
            decodedImage,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => _buildNoImagePlaceholder(),
          );
        } catch (_) {
          return _buildNoImagePlaceholder();
        }
      }
      return _buildNoImagePlaceholder();
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFF8FBFF),
            Color(0xFFF0F8FF),
          ],
        ),
        border: Border.all(color: Colors.blue[300]!, width: 1.5),
        // No shadow
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          splashColor: Colors.blue[300]!.withOpacity(0.2),
          highlightColor: Colors.blue[100]!.withOpacity(0.1),
          onTap: onTap ?? () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AdDetailsScreen(ad: ad.toJson())),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      child: SizedBox(
                        width: double.infinity,
                        child: Stack(
                          children: [
                            _buildAdImage(firstImageBase64),
                            if (isSpecial)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[700]?.withOpacity(0.95),
                                    borderRadius: BorderRadius.circular(12),
                                    // No shadow
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.star, color: Colors.white, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        'إعلان مميز',
                                        style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 80),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
            child: adDetailsBuilder != null
              ? adDetailsBuilder!(ad)
              : _DefaultAdDetails(ad: ad),
                      ),
                    ),
                  ),
                ],
              ),
              if (favoriteIconBuilder != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: favoriteIconBuilder!(adId),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Default ad details layout for AdCardWidget (mimics home screen)
class _DefaultAdDetails extends StatelessWidget {
  final home.AdModel ad;
  const _DefaultAdDetails({required this.ad});

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final difference = now.difference(date);
      if (difference.inDays >= 1) return 'منذ ${difference.inDays} يوم';
      if (difference.inHours >= 1) return 'منذ ${difference.inHours} ساعة';
      if (difference.inMinutes >= 1) return 'منذ ${difference.inMinutes} دقيقة';
      return 'الآن';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text(
          ad.adTitle ?? '',
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[300]!, width: 1),
                ),
                child: Text(
                  '${ad.price ?? '0'} ${ad.currencyName ?? ''}',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[300]!, width: 1),
              ),
              child: Text(
                ad.forSale == true ? 'للبيع' : 'للإيجار',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, size: 12, color: Colors.blue[600]),
            const SizedBox(width: 2),
            Expanded(
              child: Text(
                '${ad.cityName ?? ''} - ${_formatDate(ad.createDate)}',
                style: GoogleFonts.cairo(
                  color: Colors.black87,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}



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
      color: Colors.white,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: (isLoggedIn && isLoading)
        ? const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
            ),
          )
        : Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.red : Colors.grey[400],
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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap ?? () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AdDetailsScreen(ad: ad.toJson())),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: AspectRatio(
                      aspectRatio: 1.6,
                      child: _buildAdImage(firstImageBase64),
                    ),
                  ),
                  if (favoriteIconBuilder != null)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: favoriteIconBuilder!(adId),
                    ),
                  if (isSpecial)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber[700],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.white, size: 14),
                            const SizedBox(width: 3),
                            Text(
                              'مميز',
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: adDetailsBuilder != null
                    ? adDetailsBuilder!(ad)
                    : _DefaultAdDetails(ad: ad),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              child: Text(
                ad.adTitle ?? '',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                softWrap: true,
              ),
            ),
            const SizedBox(height: 10),
            // Divider
            Container(
              height: 1,
              color: Colors.blue.withOpacity(0.10),
              margin: const EdgeInsets.symmetric(vertical: 2),
            ),
            const SizedBox(height: 6),
            // Price and Type
            Row(
              children: [
                Flexible(
                  flex: 2,
                  child: Text(
                    '${ad.price ?? '0'} ${ad.currencyName ?? ''}',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[800],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  flex: 1,
                  child: Text(
                    ad.forSale == true ? 'للبيع' : 'للإيجار',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Divider
            Container(
              height: 1,
              color: Colors.blue.withOpacity(0.10),
              margin: const EdgeInsets.symmetric(vertical: 2),
            ),
            const SizedBox(height: 6),
            // Location and Date
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.blue[600]),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    '${ad.cityName ?? ''} - ${_formatDate(ad.createDate)}',
                    style: GoogleFonts.cairo(
                      color: Colors.grey[700],
                      fontSize: 11,
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
      },
    );
  }
}

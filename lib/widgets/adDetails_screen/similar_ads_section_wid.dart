import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/ad_model.dart';

class SimilarAdsSectionWid extends StatelessWidget {
  final bool isLoading;
  final bool hasError;
  final List<AdModel> similarAds;
  final VoidCallback onRetry;
  final Widget Function(AdModel) adCardBuilder;
  final int currentPage;
  final PageController? pageController;
  final int limitSimilarAds;

  const SimilarAdsSectionWid({
    Key? key,
    required this.isLoading,
    required this.hasError,
    required this.similarAds,
    required this.onRetry,
    required this.adCardBuilder,
    required this.currentPage,
    required this.pageController,
    required this.limitSimilarAds,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.15),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Text(
                'إعلانات مشابهة',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: colorScheme.onPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: _buildContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (isLoading) {
      return Container(
        height: 120,
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ),
              SizedBox(height: 12),
              Text(
                'جاري تحميل الإعلانات المشابهة...',
                style: GoogleFonts.cairo(
                  color: colorScheme.outline,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    if (hasError) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 40,
              color: colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              'فشل في تحميل الإعلانات المشابهة',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh, size: 18, color: colorScheme.onPrimary),
                label: Text('إعادة المحاولة', style: GoogleFonts.cairo(color: colorScheme.onPrimary)),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (similarAds.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 40,
              color: colorScheme.outline,
            ),
            SizedBox(height: 12),
            Text(
              'لا توجد إعلانات مشابهة في الوقت الحالي',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return _buildSimilarAdsList(context);
  }

  Widget _buildSimilarAdsList(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double cardHeight = 290.0;
    if (similarAds.length <= 1) {
      return Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.92,
          height: cardHeight,
          child: similarAds.isNotEmpty
              ? adCardBuilder(similarAds.first)
              : const SizedBox.shrink(),
        ),
      );
    } else {
      return SizedBox(
        height: cardHeight + 32,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: cardHeight,
              child: PageView.builder(
                controller: pageController,
                itemCount: similarAds.length,
                itemBuilder: (context, index) => adCardBuilder(similarAds[index]),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                similarAds.length,
                (index) => Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentPage == index
                        ? colorScheme.primary
                        : colorScheme.outline.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}

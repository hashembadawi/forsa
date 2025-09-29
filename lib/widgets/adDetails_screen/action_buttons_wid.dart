import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActionButtonsWid extends StatelessWidget {
  final bool isFavorite;
  final bool isLoadingFavorite;
  final VoidCallback onShare;
  final VoidCallback onReport;
  final VoidCallback onToggleFavorite;
  const ActionButtonsWid({
    Key? key,
    required this.isFavorite,
    required this.isLoadingFavorite,
    required this.onShare,
    required this.onReport,
    required this.onToggleFavorite,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            context: context,
            icon: Icons.share,
            label: 'مشاركة',
            color: colorScheme.primary,
            onTap: onShare,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            context: context,
            icon: Icons.report_outlined,
            label: 'ابلاغ',
            color: colorScheme.error,
            onTap: onReport,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            context: context,
            icon: isFavorite ? Icons.favorite : Icons.favorite_border,
            label: 'تفضيل',
            color: isFavorite ? colorScheme.error : colorScheme.outline,
            onTap: onToggleFavorite,
            isLoading: isLoadingFavorite,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        onPressed: isLoading ? null : onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                ),
              )
            else
              Icon(icon, color: colorScheme.onPrimary, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.cairo(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

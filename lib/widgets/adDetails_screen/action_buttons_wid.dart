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
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.06),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // مشاركة button uses primary color (like call button)
          _buildActionButton(
            context: context,
            icon: Icons.share,
            label: 'مشاركة',
            color: colorScheme.primary, // Primary color
            onTap: onShare,
            iconSize: 18,
            fontSize: 11,
            verticalPadding: 6,
            forceWhiteText: true,
          ),
          const SizedBox(width: 4),
          _buildActionButton(
            context: context,
            icon: Icons.report_outlined,
            label: 'ابلاغ',
            color: const Color(0xFFE53935), // Red for report
            onTap: onReport,
            iconSize: 18,
            fontSize: 11,
            verticalPadding: 6,
          ),
          const SizedBox(width: 4),
          // تفضيل button: white text, red icon/text if favorite
          _buildActionButton(
            context: context,
            icon: isFavorite ? Icons.favorite : Icons.favorite_border,
            label: 'تفضيل',
            color: Colors.white, // Always white background
            onTap: onToggleFavorite,
            isLoading: isLoadingFavorite,
            iconSize: 18,
            fontSize: 11,
            verticalPadding: 6,
            heartRed: isFavorite,
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
    double iconSize = 18,
    double fontSize = 11,
    double verticalPadding = 6,
    bool forceWhiteText = false,
    bool heartRed = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    Color iconColor = colorScheme.onPrimary;
    Color textColor = colorScheme.onPrimary;
    if (forceWhiteText) {
      textColor = Colors.white;
      iconColor = Colors.white;
    }
    if (heartRed) {
      iconColor = Colors.red;
      textColor = Colors.red;
    } else if (color == Colors.white) {
      // For 'تفضيل' button when not favorite: black icon/text
      iconColor = Colors.black;
      textColor = Colors.black;
    }
    return Expanded(
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        onPressed: isLoading ? null : onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: iconSize + 6,
                height: iconSize + 6,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                ),
              )
            else
              Icon(icon, color: iconColor, size: iconSize),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.cairo(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

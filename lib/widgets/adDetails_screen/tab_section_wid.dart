import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TabSectionWid extends StatelessWidget {
  final int selectedTabIndex;
  final void Function(int) onTabSelected;
  final Widget tabContent;
  const TabSectionWid({
    Key? key,
    required this.selectedTabIndex,
    required this.onTabSelected,
    required this.tabContent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.primary.withOpacity(0.15), width: 1.5),
        borderRadius: BorderRadius.circular(18),
        color: colorScheme.surface,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            // Tab Headers
            Row(
              children: [
                _buildTabButton(context, 'معلومات الإعلان', 0),
                _buildTabButton(context, 'الوصف', 1),
                _buildTabButton(context, 'الموقع', 2),
              ],
            ),
            // Tab Content with fluid animation
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder: (child, animation) {
                final inFromRight = Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(animation);
                final outToLeft = Tween<Offset>(
                  begin: Offset.zero,
                  end: const Offset(-1.0, 0.0),
                ).animate(animation);
                return SlideTransition(
                  position: animation.status == AnimationStatus.reverse ? outToLeft : inFromRight,
                  child: child,
                );
              },
              child: Container(
                key: ValueKey<int>(selectedTabIndex),
                padding: const EdgeInsets.all(16),
                child: tabContent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(BuildContext context, String title, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = selectedTabIndex == index;
    final isFirst = index == 0;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabSelected(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            border: !isFirst
                ? Border(
                    right: BorderSide(color: colorScheme.primary.withOpacity(0.15), width: 1),
                  )
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}


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
    // Use a light, neutral background color to match the general screen
    const Color kTabSectionBg = Color(0xFFFAFAFA); // Matches general background
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kTabSectionBg, colorScheme.surface.withOpacity(0.97)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: colorScheme.primary.withOpacity(0.10), width: 1.2),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            // Tab Headers with icons
            Row(
              children: [
                _buildTabButton(context, 'معلومات', 0, icon: Icons.info_outline),
                _buildTabButton(context, 'الوصف', 1, icon: Icons.description_outlined),
                _buildTabButton(context, 'الموقع', 2, icon: Icons.location_on_outlined),
              ],
            ),
            // Tab Content with fluid animation
            // Set a static height for the tab content area
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
              child: SizedBox(
                key: ValueKey<int>(selectedTabIndex),
                height: 365, // Fixed height for content area
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: tabContent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(BuildContext context, String title, int index, {IconData? icon}) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = selectedTabIndex == index;
    final isFirst = index == 0;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          border: !isFirst
              ? Border(
                  right: BorderSide(color: colorScheme.primary.withOpacity(0.15), width: 1),
                )
              : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => onTabSelected(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null)
                  Icon(
                    icon,
                    size: 20,
                    color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
                  ),
                const SizedBox(height: 2),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


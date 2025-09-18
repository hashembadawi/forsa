import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FullScreenLoadingWid extends StatelessWidget {
  final String message;
  final Color color;

  const FullScreenLoadingWid({
    Key? key,
    this.message = 'جاري تحميل الإعلانات...',
    this.color = const Color(0xFF1976D2), // Default blue[700]
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFFFD54F); // Golden Yellow
    const Color secondaryColor = Color(0xFF42A5F5); // Light Blue
    const Color surfaceColor = Color(0xFFF5F5F5); // Light Gray
// Dark Black
    return Scaffold(
      backgroundColor: surfaceColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Simple grid shimmer for ads (2 per row, only 2 blocks)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 2,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.82,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 18,
                  ),
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.13),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: secondaryColor.withOpacity(0.18), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: secondaryColor.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 70,
                            decoration: BoxDecoration(
                              color: secondaryColor.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: 80,
                            height: 12,
                            color: secondaryColor.withOpacity(0.13),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 60,
                            height: 10,
                            color: primaryColor.withOpacity(0.13),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  message,
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: secondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

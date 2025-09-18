import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Material 3 color palette (same as home_screen.dart)
const Color kPrimaryColor = Color(0xFFFFD54F); // Golden Yellow
const Color kSecondaryColor = Color(0xFF42A5F5); // Light Blue
const Color kAccentColor = Color(0xFFFF7043); // Soft Orange
const Color kBackgroundColor = Color(0xFFFAFAFA); // White
const Color kSurfaceColor = Color(0xFFF5F5F5); // Light Gray
const Color kTextColor = Color(0xFF212121); // Dark Black
const Color kTextSecondary = Color(0xFF424242); // Dark Gray
const Color kSuccessColor = Color(0xFF66BB6A); // Green
const Color kErrorColor = Color(0xFFE53935); // Red
const Color kOutlineColor = Color(0xFFE0E3E7); // Soft Gray

/// Utility class for showing common dialogs throughout the app
class DialogUtils {
  
  /// Show a success dialog with a green check icon
  /// 
  /// [context] - The build context
  /// [title] - The title of the dialog (default: 'تم بنجاح')
  /// [message] - The success message to display
  /// [buttonText] - The text for the action button (default: 'موافق')
  /// [onPressed] - Optional callback when button is pressed
  /// [barrierDismissible] - Whether dialog can be dismissed by tapping outside (default: false)
  static void showSuccessDialog({
    required BuildContext context,
    String title = 'تم بنجاح',
    required String message,
    String buttonText = 'موافق',
    VoidCallback? onPressed,
    bool barrierDismissible = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.maxFinite,
          decoration: BoxDecoration(
            color: kBackgroundColor,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: kSuccessColor.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kSuccessColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Body
              Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: kTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onPressed ?? () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kSuccessColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          buttonText,
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show an error dialog with a red error icon
  /// 
  /// [context] - The build context
  /// [title] - The title of the dialog (default: 'خطأ')
  /// [message] - The error message to display
  /// [buttonText] - The text for the action button (default: 'موافق')
  /// [onPressed] - Optional callback when button is pressed
  /// [barrierDismissible] - Whether dialog can be dismissed by tapping outside (default: true)
  static void showErrorDialog({
    required BuildContext context,
    String title = 'خطأ',
    required String message,
    String buttonText = 'موافق',
    VoidCallback? onPressed,
    bool barrierDismissible = true,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.maxFinite,
          decoration: BoxDecoration(
            color: kBackgroundColor,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: kErrorColor.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kErrorColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Body
              Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: kTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onPressed ?? () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kErrorColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          buttonText,
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show a loading dialog with a circular progress indicator
  /// 
  /// [context] - The build context
  /// [title] - The title of the dialog (default: 'جارٍ التحميل...')
  /// [message] - Optional message to display below the loading indicator
  /// [barrierDismissible] - Whether dialog can be dismissed by tapping outside (default: false)
  static void showLoadingDialog({
    required BuildContext context,
    String title = 'جارٍ التحميل...',
    String? message,
    bool barrierDismissible = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.maxFinite,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kSecondaryColor.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Blue Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: kSecondaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Text(
                  title,
          style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // White Body
              Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.blue),
                    if (message != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        message,
            style: GoogleFonts.cairo(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show a confirmation dialog with yes/no options
  /// 
  /// [context] - The build context
  /// [title] - The title of the dialog
  /// [message] - The confirmation message to display
  /// [confirmText] - The text for the confirm button (default: 'نعم')
  /// [cancelText] - The text for the cancel button (default: 'لا')
  /// [onConfirm] - Callback when confirm button is pressed
  /// [onCancel] - Optional callback when cancel button is pressed
  /// [confirmColor] - Color for the confirm button (default: Colors.blue)
  /// [cancelColor] - Color for the cancel button (default: Colors.grey)
  static void showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'نعم',
    String cancelText = 'لا',
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    Color confirmColor = Colors.blue,
    Color cancelColor = Colors.grey,
  }) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.maxFinite,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kSecondaryColor.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Blue Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: kSecondaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Text(
                  title,
            style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // White Body
              Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message,
              style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: onCancel ?? () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: cancelColor,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            child: Text(
                              cancelText,
                              style: GoogleFonts.cairo(color: cancelColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              onConfirm();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: confirmColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              confirmText,
                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show a no internet connection dialog
  /// 
  /// [context] - The build context
  /// [onRetry] - Optional callback for retry button
  /// [title] - The title of the dialog (default: 'لا يوجد اتصال بالإنترنت')
  /// [message] - The message to display (default: standard no internet message)
  static void showNoInternetDialog({
    required BuildContext context,
    VoidCallback? onRetry,
    String title = 'لا يوجد اتصال بالإنترنت',
    String message = 'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى',
  }) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.maxFinite,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kSecondaryColor.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Blue Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: kSecondaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                            style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // White Body
              Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message,
                          style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            child: Text(
                              'إغلاق',
                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        if (onRetry != null) ...[
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                onRetry();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'إعادة المحاولة',
                                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Close any open dialog
  /// 
  /// [context] - The build context
  static void closeDialog(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      try {
        Navigator.of(context).pop();
      } catch (e) {
        // Ignore if already popped
      }
    }
  }
}

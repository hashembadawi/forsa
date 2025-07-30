import 'package:flutter/material.dart';

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
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: onPressed ?? () => Navigator.of(context).pop(),
            child: Text(
              buttonText,
              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
        ],
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
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: onPressed ?? () => Navigator.of(context).pop(),
            child: Text(
              buttonText,
              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
        ],
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
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.blue),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 10),
              Text(
                message,
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ],
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
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: onCancel ?? () => Navigator.of(context).pop(),
            child: Text(
              cancelText,
              style: TextStyle(color: cancelColor, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            child: Text(
              confirmText,
              style: TextStyle(color: confirmColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
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
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.blue[300]!, width: 1.5),
        ),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.orange),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.black87),
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق', style: TextStyle(color: Colors.orange)),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('إعادة المحاولة', style: TextStyle(color: Colors.blue)),
            ),
        ],
      ),
    );
  }

  /// Close any open dialog
  /// 
  /// [context] - The build context
  static void closeDialog(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}

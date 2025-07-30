# Dialog Utils Usage Guide

This guide explains how to use the `DialogUtils` class to create consistent dialogs throughout your Flutter application.

## Overview

The `DialogUtils` class provides reusable dialog methods to maintain consistency in user interface and reduce code duplication across your app.

## Available Dialog Methods

### 1. Success Dialog
Shows a green checkmark with a success message.

```dart
DialogUtils.showSuccessDialog(
  context: context,
  message: 'تم إنشاء حسابك بنجاح، يمكنك تسجيل الدخول الآن',
  onPressed: () {
    Navigator.of(context).pop(); // Close dialog
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  },
);
```

**Parameters:**
- `context` (required): BuildContext
- `message` (required): Success message to display
- `title` (optional): Dialog title (default: 'تم بنجاح')
- `buttonText` (optional): Button text (default: 'موافق')
- `onPressed` (optional): Callback when button is pressed
- `barrierDismissible` (optional): Whether dialog can be dismissed by tapping outside (default: false)

### 2. Error Dialog
Shows a red error icon with an error message.

```dart
DialogUtils.showErrorDialog(
  context: context,
  message: 'حدث خطأ في الاتصال بالخادم',
);
```

**Parameters:**
- `context` (required): BuildContext
- `message` (required): Error message to display
- `title` (optional): Dialog title (default: 'خطأ')
- `buttonText` (optional): Button text (default: 'موافق')
- `onPressed` (optional): Callback when button is pressed
- `barrierDismissible` (optional): Whether dialog can be dismissed by tapping outside (default: true)

### 3. Loading Dialog
Shows a circular progress indicator with a loading message.

```dart
DialogUtils.showLoadingDialog(
  context: context,
  title: 'جارٍ إنشاء الحساب...',
  message: 'يرجى الانتظار حتى يتم إنشاء حسابك',
);
```

**Parameters:**
- `context` (required): BuildContext
- `title` (optional): Loading title (default: 'جارٍ التحميل...')
- `message` (optional): Additional message below loading indicator
- `barrierDismissible` (optional): Whether dialog can be dismissed by tapping outside (default: false)

### 4. Confirmation Dialog
Shows a dialog with yes/no options for user confirmation.

```dart
DialogUtils.showConfirmationDialog(
  context: context,
  title: 'تأكيد الحذف',
  message: 'هل أنت متأكد من حذف هذا الإعلان؟',
  onConfirm: () {
    // Delete the ad
    _deleteAd();
  },
);
```

**Parameters:**
- `context` (required): BuildContext
- `title` (required): Dialog title
- `message` (required): Confirmation message
- `onConfirm` (required): Callback when confirm button is pressed
- `confirmText` (optional): Confirm button text (default: 'نعم')
- `cancelText` (optional): Cancel button text (default: 'لا')
- `onCancel` (optional): Callback when cancel button is pressed
- `confirmColor` (optional): Confirm button color (default: Colors.blue)
- `cancelColor` (optional): Cancel button color (default: Colors.grey)

### 5. No Internet Dialog
Shows a no internet connection dialog with retry option.

```dart
DialogUtils.showNoInternetDialog(
  context: context,
  onRetry: _tryAgain,
);
```

**Parameters:**
- `context` (required): BuildContext
- `onRetry` (optional): Callback for retry button
- `title` (optional): Dialog title (default: 'لا يوجد اتصال بالإنترنت')
- `message` (optional): Dialog message (default: standard no internet message)

### 6. Close Dialog
Closes any open dialog.

```dart
DialogUtils.closeDialog(context);
```

## Migration Guide

### Before (using custom dialog methods):
```dart
// Old way - custom dialog methods in each screen
void _showErrorDialog(String message) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.error, color: Colors.red),
          SizedBox(width: 10),
          Text('خطأ'),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('موافق', style: TextStyle(color: Colors.blue)),
        ),
      ],
    ),
  );
}

// Usage
_showErrorDialog('حدث خطأ في الاتصال بالخادم');
```

### After (using DialogUtils):
```dart
// New way - using DialogUtils
import 'package:syria_market/utils/dialog_utils.dart';

// Usage
DialogUtils.showErrorDialog(
  context: context,
  message: 'حدث خطأ في الاتصال بالخادم',
);
```

## Benefits

1. **Consistency**: All dialogs follow the same design patterns
2. **Maintainability**: Changes to dialog design only need to be made in one place
3. **Reusability**: Dialog methods can be used across all screens
4. **Cleaner Code**: Reduces code duplication and improves readability
5. **Easy Customization**: Flexible parameters allow customization when needed

## Complete Integration Example

Here's how to integrate DialogUtils in a typical screen:

```dart
import 'package:flutter/material.dart';
import 'package:syria_market/utils/dialog_utils.dart';

class ExampleScreen extends StatefulWidget {
  @override
  _ExampleScreenState createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  
  Future<void> _performAction() async {
    // Show loading dialog
    DialogUtils.showLoadingDialog(
      context: context,
      title: 'جارٍ العملية...',
      message: 'يرجى الانتظار',
    );

    try {
      // Perform your async operation
      await someAsyncOperation();
      
      // Close loading dialog
      DialogUtils.closeDialog(context);
      
      // Show success dialog
      DialogUtils.showSuccessDialog(
        context: context,
        message: 'تمت العملية بنجاح',
      );
      
    } catch (e) {
      // Close loading dialog
      DialogUtils.closeDialog(context);
      
      // Show error dialog
      DialogUtils.showErrorDialog(
        context: context,
        message: 'حدث خطأ أثناء العملية',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Example Screen')),
      body: Center(
        child: ElevatedButton(
          onPressed: _performAction,
          child: Text('تنفيذ العملية'),
        ),
      ),
    );
  }
}
```

## Best Practices

1. **Always import DialogUtils**: Add `import 'package:syria_market/utils/dialog_utils.dart';` to any screen that uses dialogs
2. **Use appropriate dialog types**: Choose the right dialog method for your use case
3. **Handle loading states**: Always close loading dialogs in both success and error cases
4. **Provide meaningful messages**: Use clear, user-friendly Arabic text
5. **Consider user flow**: Think about what should happen after each dialog action

## File Structure

```
lib/
├── utils/
│   └── dialog_utils.dart          # Main DialogUtils class
├── screens/
│   ├── login_screen.dart          # Example usage
│   ├── register_screen.dart       # Example usage
│   └── my_ads_screen.dart         # Can be updated to use DialogUtils
└── ...
```

# App Installation & Troubleshooting Guide

## The APK was built successfully ✅
**Debug APK**: `build\app\outputs\flutter-apk\app-debug.apk`
**Release APK**: `build\app\outputs\flutter-apk\app-release.apk` (Recommended)

## ⚠️ **CRITICAL FIX APPLIED**
**المشكلة الرئيسية تم حلها**: كانت هناك مشاكل في URLs للـ API - بعض الروابط لم تحتوي على `https://`

### URLs تم إصلاحها:
- ✅ تسجيل الدخول 
- ✅ التسجيل والتحقق
- ✅ جلب الإعلانات 
- ✅ إضافة/تحديث الإعلانات
- ✅ البحث في الإعلانات

## Common Issues & Solutions:

### 1. **App Crashes on Startup**
- **Check connectivity**: The app requires internet connection to work
- **Check permissions**: Ensure the app has necessary permissions
- **Check device compatibility**: Minimum Android version required

### 2. **App Doesn't Install**
- Enable "Unknown Sources" in Android settings
- Ensure sufficient storage space
- Try installing via ADB: `adb install app-debug.apk`

### 3. **App Installs but Won't Open**
- Check if the app appears in the device app list
- Try clearing app data/cache
- Restart the device and try again

### 4. **App Opens but Shows Errors**
- Check internet connection (app has connectivity checking)
- Ensure the API endpoints are accessible
- Check device logs for specific errors

## Debug Steps:

### Step 1: Install with logging
```bash
adb install build\app\outputs\flutter-apk\app-debug.apk
```

### Step 2: Check device logs
```bash
adb logcat | findstr flutter
```

### Step 3: Build release version
```bash
flutter build apk --release
```

## App Features That Require Internet:
- The app has ConnectivityWrapper that checks internet connection
- If no internet, it shows "لا يوجد اتصال بالإنترنت" message
- All API calls require internet connectivity

## Next Steps:
1. **نزل التطبيق الجديد**: `build\app\outputs\flutter-apk\app-release.apk` (22.6MB)
2. **امسح النسخة القديمة** من الهاتف أولاً
3. **نصب النسخة الجديدة** مع الإصلاحات
4. **جرب تسجيل الدخول وجلب الإعلانات** - يجب أن تعمل الآن!

## إذا لم تعمل بعد:
- تأكد من اتصال الإنترنت قوي
- جرب إعادة تشغيل التطبيق
- تأكد من أن الخادم `sahbo-app-api.onrender.com` يعمل

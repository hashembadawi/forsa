import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_fonts/google_fonts.dart';

// Screen imports
import 'FAQ_screen.dart';
import 'ad_terms_screen.dart';
import 'contact_us_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';

// Utils imports
import '../utils/dialog_utils.dart';

/// SIMPLIFIED VERSION - Much easier to understand and maintain
class AccountScreen extends StatefulWidget {
  //final String userName;
  final String userFirstName;
  final String userLastName;
  final String userEmail;
  final String phoneNumber;
  final bool isLoggedIn;
  final String userId;
  final String? userProfileImage;
  final String? userAccountNumber;

  const AccountScreen({
    super.key,
    //required this.userName,
    required this.userFirstName,
    required this.userLastName, 
    required this.userEmail,
    required this.phoneNumber,
    required this.isLoggedIn,
    required this.userId,
    this.userProfileImage,
    this.userAccountNumber,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {

  bool _isConnected = true;
  File? _newProfileImage;
  
  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  // Image picker
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  // Simple connectivity check
  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _isConnected = result != ConnectivityResult.none;
    });
  }

  // Simple image picker
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _newProfileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showMessage('حدث خطأ أثناء اختيار الصورة', Colors.red);
    }
  }

  // Simple image getter
  ImageProvider? _getAvatarImage() {
    if (_newProfileImage != null) {
      return FileImage(_newProfileImage!);
    }
    if (widget.userProfileImage != null && widget.userProfileImage!.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(widget.userProfileImage!));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Simple update method
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Show uploading dialog
    _showUploadingDialog();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      // Prepare data
      final data = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'userId': widget.userId,
      };

      // Add image if selected
      if (_newProfileImage != null) {
        final bytes = await FlutterImageCompress.compressWithFile(
          _newProfileImage!.path,
          quality: 70,
        );
        if (bytes != null) {
          data['profileImage'] = base64Encode(bytes);
        }
      }

      final response = await http.put(
        Uri.parse('https://sahbo-app-api.onrender.com/api/user/update-info'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(data),
      );

      // Close uploading dialog
      DialogUtils.closeDialog(context);

      if (response.statusCode == 200) {
        // Close the edit dialog as well
        DialogUtils.closeDialog(context);
        _showMessage('لقد تم تغير البيانات بنجاح لملاحظة التغييرات اعد تسجيل الدخول', Colors.green);
      } else {
        _showMessage('حدث خطأ', Colors.red);
      }
    } catch (e) {
      // Close uploading dialog
      DialogUtils.closeDialog(context);
      _showMessage('خطأ في الاتصال', Colors.red);
    }
  }

  // Simple message using DialogUtils
  void _showMessage(String message, Color color, {bool navigateToHome = false}) {
    if (color == Colors.green) {
      // Show success dialog
      DialogUtils.showSuccessDialog(
        context: context,
        message: message,
        onPressed: () {
          Navigator.pop(context);
          if (navigateToHome) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          }
        },
      );
    } else {
      // Show error dialog
      DialogUtils.showErrorDialog(
        context: context,
        message: message,
      );
    }
  }

  // Show uploading dialog using DialogUtils
  void _showUploadingDialog() {
    DialogUtils.showLoadingDialog(
      context: context,
      title: 'جارٍ تحديث البيانات...',
      message: 'يرجى الانتظار حتى يتم إرسال البيانات',
    );
  }

  // Show deleting dialog using DialogUtils
  void _showDeletingDialog() {
    DialogUtils.showLoadingDialog(
      context: context,
      title: 'جارٍ حذف الحساب...',
      message: 'يرجى الانتظار حتى يتم حذف الحساب',
    );
  }

  // Simple delete account
  Future<void> _deleteAccount() async {
    // Show uploading dialog
    _showDeletingDialog();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    try {
      final response = await http.delete(
        Uri.parse('https://sahbo-app-api.onrender.com/api/user/delete-account'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({'userId': widget.userId}),
      );
      
      // Close uploading dialog
      DialogUtils.closeDialog(context);
      
      if (response.statusCode == 200) {
        await prefs.clear();
        _showMessage('تم حذف الحساب', Colors.green, navigateToHome: true);
      } else {
        _showMessage('حدث خطأ في حذف الحساب', Colors.red);
      }
    } catch (e) {
      // Close uploading dialog
      DialogUtils.closeDialog(context);
      _showMessage('خطأ في الاتصال', Colors.red);
    }
  }

  // Simple edit dialog with keyboard handling
  void _showEditDialog() {
    //final names = widget.userName.split(' ');
    final firstName = widget.userFirstName;
    final lastName = widget.userLastName;
    _firstNameController.text = firstName;
    _lastNameController.text = lastName;

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setDialogState) => Dialog(
            insetPadding: const EdgeInsets.all(16),
            backgroundColor: Colors.transparent,
            child: Container(
              width: double.maxFinite,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dialog title
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'تعديل الملف الشخصي',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  
                  // Scrollable content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Simple image section
                            GestureDetector(
                              onTap: () {
                                _pickImage().then((_) => setDialogState(() {}));
                              },
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.blue, width: 2),
                                  color: Colors.grey[100],
                                ),
                                child: ClipOval(
                                  child: _getAvatarImage() != null
                                      ? Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Image(image: _getAvatarImage()!, fit: BoxFit.cover),
                                            if (_newProfileImage != null)
                                              Positioned(
                                                top: 5,
                                                right: 5,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    setDialogState(() {
                                                      _newProfileImage = null;
                                                    });
                                                  },
                                                  child: Container(
                                                    width: 20,
                                                    height: 20,
                                                    decoration: const BoxDecoration(
                                                      color: Colors.red,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.close,
                                                      color: Colors.white,
                                                      size: 12,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        )
                                      : Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.add_a_photo, size: 30, color: Colors.blue),
                                            const SizedBox(height: 4),
                                            Text(
                                              'اضغط لاختيار صورة',
                                              style: GoogleFonts.cairo(fontSize: 10, color: Colors.blue),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Simple name fields
                            TextFormField(
                              controller: _firstNameController,
                              decoration: InputDecoration(
                                labelText: 'الاسم الأول',
                                labelStyle: GoogleFonts.cairo(),
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _lastNameController,
                              decoration: InputDecoration(
                                labelText: 'الاسم الأخير',
                                labelStyle: GoogleFonts.cairo(),
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Action buttons
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('إلغاء', style: GoogleFonts.cairo()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('حفظ', style: GoogleFonts.cairo()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Simple delete dialog using DialogUtils
  void _showDeleteDialog() {
    DialogUtils.showConfirmationDialog(
      context: context,
      title: 'حذف الحساب',
      message: 'هل أنت متأكد من حذف حسابك؟ لا يمكن التراجع عن هذا الإجراء.',
      confirmText: 'حذف',
      cancelText: 'إلغاء',
      confirmColor: Colors.red,
      onConfirm: _deleteAccount,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isConnected) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text('لا يوجد اتصال بالإنترنت', style: GoogleFonts.cairo()),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  DialogUtils.showNoInternetDialog(
                    context: context,
                    onRetry: _checkConnectivity,
                  );
                },
                child: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
              ),
            ],
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text('حسابي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 22)),
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // User card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.blue[300]!,
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: widget.isLoggedIn
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Main content: Profile image, separator, and user info
                              IntrinsicHeight(
                                child: Row(
                                  children: [
                                    // Profile image on the right
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.blue[400]!,
                                          width: 2,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: MediaQuery.of(context).size.width * 0.12, // Responsive radius
                                        backgroundColor: Colors.grey[100],
                                        backgroundImage: _getAvatarImage(),
                                        child: _getAvatarImage() == null 
                                            ? Icon(
                                                Icons.person, 
                                                color: Colors.blue, 
                                                size: MediaQuery.of(context).size.width * 0.1, // Responsive icon size
                                              )
                                            : null,
                                      ),
                                    ),
                                    
                                    const SizedBox(width: 16),
                                    
                                    // Vertical separator
                                    Container(
                                      width: 2,
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.blue[300]!.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    ),
                                    
                                    const SizedBox(width: 16),
                                    
                                    // User information column (expandable)
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // Username
                                          Text(
                                            '${widget.userFirstName} ${widget.userLastName}',
                                            style: GoogleFonts.cairo(
                                              fontSize: MediaQuery.of(context).size.width * 0.045, // Responsive font size
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          
                                          const SizedBox(height: 8),
                                          
                                          // Phone number
                                          Text(
                                            widget.phoneNumber,
                                            style: GoogleFonts.cairo(
                                              fontSize: MediaQuery.of(context).size.width * 0.035, // Responsive font size
                                              color: Colors.black.withOpacity(0.7),
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          
                                          // Account number if available
                                          if (widget.userAccountNumber != null && widget.userAccountNumber!.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              widget.userAccountNumber!,
                                              style: GoogleFonts.cairo(
                                                fontSize: MediaQuery.of(context).size.width * 0.032, // Responsive font size
                                                color: Colors.black.withOpacity(0.6),
                                                fontWeight: FontWeight.w400,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              // Guest avatar with enhanced styling
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.blue[400]!,
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 35,
                                  backgroundColor: Colors.grey[100],
                                  child: const Icon(Icons.person, size: 35, color: Colors.grey),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'مرحباً بك!',
                                        style: GoogleFonts.cairo(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'سجل الدخول للوصول لجميع الميزات',
                                      style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Edit and Delete buttons (only for logged in users)
              if (widget.isLoggedIn) ...[
                Row(
                  children: [
                    // Edit button
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          onPressed: _showEditDialog,
                          icon: const Icon(Icons.edit),
                          label: Text('تعديل الملف الشخصي', style: GoogleFonts.cairo( fontWeight: FontWeight.bold,fontSize: 12)),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8), // Spacing between buttons
                    
                    // Delete button
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _showDeleteDialog,
                          icon: const Icon(Icons.delete_outline),
                          label: Text('حذف الحساب', style: GoogleFonts.cairo( fontWeight: FontWeight.bold,fontSize: 12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              
              // Menu items
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.article, color: Colors.blue),
                      title: Text('شروط الإعلان', style: GoogleFonts.cairo()),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdTermsScreen()),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.help, color: Colors.blue),
                      title: Text('الأسئلة الشائعة', style: GoogleFonts.cairo()),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FAQScreen()),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.call, color: Colors.blue),
                      title: Text('اتصل بنا', style: GoogleFonts.cairo()),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ContactUsScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Auth button
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isLoggedIn ? Colors.orange : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: widget.isLoggedIn 
                      ? () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                            (route) => false,
                          );
                        }
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        ),
                  child: Text(
                    widget.isLoggedIn ? 'تسجيل الخروج' : 'تسجيل الدخول',
                    style: GoogleFonts.cairo( 
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
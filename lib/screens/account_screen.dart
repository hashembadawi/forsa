import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

// Screen imports
import 'FAQ_screen.dart';
import 'ad_terms_screen.dart';
import 'contact_us_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// SIMPLIFIED VERSION - Much easier to understand and maintain
class AccountScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String phoneNumber;
  final bool isLoggedIn;
  final String userId;
  final String? userProfileImage;
  final String? userAccountNumber;

  const AccountScreen({
    super.key,
    required this.userName,
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
  // Basic state
  bool _isConnected = true;
  bool _isLoading = false;
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

    setState(() => _isLoading = true);

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
        Uri.parse('https://sahbo-app-api.onrender.com/api/user/update-name'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        _showMessage('لقد تم تغير البيانات بنجاح لملاحظة التغييرات اعد تسجيل الدخول', Colors.green);
      } else {
        _showMessage('حدث خطأ', Colors.red);
      }
    } catch (e) {
      _showMessage('خطأ في الاتصال', Colors.red);
    }

    setState(() => _isLoading = false);
  }

  // Simple message with OK button for success
  void _showMessage(String message, Color color) {
    if (color == Colors.green) {
      // Show dialog for success message
      showDialog(
        context: context,
        builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('نجح'),
            content: Text(message),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('موافق'),
              ),
            ],
          ),
        ),
      );
    } else {
      // Show snackbar for error messages
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
    }
  }

  // Simple delete account
  Future<void> _deleteAccount() async {
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
      
      if (response.statusCode == 200) {
        await prefs.clear();
        _showMessage('تم حذف الحساب بنجاح', Colors.green);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        _showMessage('حدث خطأ في حذف الحساب', Colors.red);
      }
    } catch (e) {
      _showMessage('خطأ في الاتصال', Colors.red);
    }
  }

  // Simple edit dialog
  void _showEditDialog() {
    final names = widget.userName.split(' ');
    _firstNameController.text = names.isNotEmpty ? names.first : '';
    _lastNameController.text = names.length > 1 ? names.sublist(1).join(' ') : '';

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('تعديل الملف الشخصي'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, size: 30, color: Colors.blue),
                                  SizedBox(height: 4),
                                  Text(
                                    'اضغط لاختيار صورة',
                                    style: TextStyle(fontSize: 10, color: Colors.blue),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Simple name fields
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'الاسم الأول',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'الاسم الأخير',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                child: _isLoading 
                    ? const SizedBox(
                        width: 16, 
                        height: 16, 
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Simple delete dialog
  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف الحساب'),
          content: const Text('هل أنت متأكد من حذف حسابك؟ لا يمكن التراجع عن هذا الإجراء.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteAccount();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('حذف', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
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
              const Text('لا يوجد اتصال بالإنترنت'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkConnectivity,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('حسابي'),
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
                  boxShadow: [
                    BoxShadow(
                      color: (widget.isLoggedIn ? Colors.blue : Colors.grey).withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
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
                    padding: const EdgeInsets.all(20),
                    child: widget.isLoggedIn
                        ? Column(
                            children: [
                              Row(
                                children: [
                                  // Enhanced Avatar with border and shadow
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          spreadRadius: 1,
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 28,
                                      backgroundColor: Colors.grey[100],
                                      backgroundImage: _getAvatarImage(),
                                      child: _getAvatarImage() == null 
                                          ? const Icon(Icons.person, color: Colors.blue, size: 28)
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  // User info with enhanced styling
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.userName,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text(
                                              '${widget.phoneNumber}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (widget.userAccountNumber != null && widget.userAccountNumber!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  widget.userAccountNumber!,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  // Action buttons on the left side without borders
                                  Column(
                                    children: [
                                      // Edit button
                                      IconButton(
                                        onPressed: _showEditDialog,
                                        icon: const Icon(Icons.edit, color: Colors.blue, size: 28),
                                        tooltip: 'تعديل الملف الشخصي',
                                        padding: const EdgeInsets.all(8),
                                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                                      ),
                                      const SizedBox(height: 12),
                                      // Delete button
                                      IconButton(
                                        onPressed: _showDeleteDialog,
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 28),
                                        tooltip: 'حذف الحساب',
                                        padding: const EdgeInsets.all(8),
                                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                                      ),
                                    ],
                                  ),
                                ],
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
                                    color: Colors.grey[300]!,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      spreadRadius: 2,
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
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
                                      child: const Text(
                                        'مرحباً بك!',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'سجل الدخول للوصول لجميع الميزات',
                                      style: TextStyle(
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
              
              // Menu items
              Card(
                elevation: 2,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.article, color: Colors.blue),
                      title: const Text('شروط الإعلان'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdTermsScreen()),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.help, color: Colors.blue),
                      title: const Text('الأسئلة الشائعة'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FAQScreen()),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.call, color: Colors.blue),
                      title: const Text('اتصل بنا'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ContactUsScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Auth button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isLoggedIn ? Colors.red : Colors.blue,
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
                  child: Text(widget.isLoggedIn ? 'تسجيل الخروج' : 'تسجيل الدخول'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
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
import '../widgets/account_screen/profile_card_wid.dart';
import '../widgets/account_screen/edit_delete_buttons_wid.dart';
import '../widgets/account_screen/menu_items_wid.dart';
import '../widgets/account_screen/auth_button_wid.dart';
import '../../widgets/no_internet_wid.dart';
import '../widgets/account_screen/edit_profile_dialog_wid.dart';

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
    _loadUserData();
    _checkConnectivity();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _firstNameController.text = prefs.getString('userFirstName') ?? widget.userFirstName;
      _lastNameController.text = prefs.getString('userLastName') ?? widget.userLastName;
      _localProfileImage = prefs.getString('userProfileImage') ?? widget.userProfileImage;
    });
  }

  String? _localProfileImage;

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
    if (_localProfileImage != null && _localProfileImage!.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(_localProfileImage!));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Simple update method
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    _showUploadingDialog();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final data = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'userId': widget.userId,
      };
      String? newProfileImageBase64;
      if (_newProfileImage != null) {
        final bytes = await FlutterImageCompress.compressWithFile(
          _newProfileImage!.path,
          quality: 70,
        );
        if (bytes != null) {
          newProfileImageBase64 = base64Encode(bytes);
          data['profileImage'] = newProfileImageBase64;
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
      DialogUtils.closeDialog(context);
      if (response.statusCode == 200) {
        // Save updated info to SharedPreferences
        await prefs.setString('userFirstName', _firstNameController.text.trim());
        await prefs.setString('userLastName', _lastNameController.text.trim());
        if (newProfileImageBase64 != null) {
          await prefs.setString('userProfileImage', newProfileImageBase64);
          setState(() {
            _localProfileImage = newProfileImageBase64;
          });
        }
        setState(() {}); // Refresh UI with new name
        DialogUtils.closeDialog(context);
        _showMessage('لقد تم تغير البيانات بنجاح', Colors.green);
      } else {
        _showMessage('حدث خطأ', Colors.red);
      }
    } catch (e) {
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
    final firstName = widget.userFirstName;
    final lastName = widget.userLastName;
    _firstNameController.text = firstName;
    _lastNameController.text = lastName;

    // Save current image state before dialog
    final File? prevNewProfileImage = _newProfileImage;
    final String? prevLocalProfileImage = _localProfileImage;

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setDialogState) => EditProfileDialogWid(
            firstNameController: _firstNameController,
            lastNameController: _lastNameController,
            formKey: _formKey,
            avatarImage: _getAvatarImage(),
            onPickImage: () {
              _pickImage().then((_) => setDialogState(() {}));
            },
            onRemoveImage: () {
              setDialogState(() {
                _newProfileImage = null;
                _localProfileImage = null;
              });
            },
            onSave: () async {
              await _updateProfile();
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    ).then((value) {
      // If user cancelled (did not save), restore previous image state
      if (_newProfileImage != prevNewProfileImage || _localProfileImage != prevLocalProfileImage) {
        _newProfileImage = prevNewProfileImage;
        _localProfileImage = prevLocalProfileImage;
        setState(() {});
      }
    });
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
      return NoInternetWid(
        onRetry: () {
          DialogUtils.showNoInternetDialog(
            context: context,
            onRetry: _checkConnectivity,
          );
        },
      );
    }

    const Color headerColor = Color(0xFF7C4DFF); // Light Blue
    const Color backgroundColor = Color(0xFFFAFAFA); // White
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text('حسابي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 25, color: const Color.fromARGB(255, 0, 0, 0))),
          backgroundColor: headerColor,
          foregroundColor: Color(0xFF212121),
          elevation: 4,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
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
        backgroundColor: backgroundColor,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ProfileCardWid(
                avatarImage: _getAvatarImage(),
                firstName: _firstNameController.text,
                lastName: _lastNameController.text,
                phoneNumber: widget.phoneNumber,
                accountNumber: widget.userAccountNumber,
                isLoggedIn: widget.isLoggedIn,
              ),
              const SizedBox(height: 16),
              if (widget.isLoggedIn) ...[
                EditDeleteButtonsWid(
                  onEdit: _showEditDialog,
                  onDelete: _showDeleteDialog,
                ),
                const SizedBox(height: 16),
              ],
              MenuItemsWid(
                onAdTerms: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdTermsScreen()),
                ),
                onFAQ: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FAQScreen()),
                ),
                onContactUs: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ContactUsScreen()),
                ),
              ),
              const Spacer(),
              AuthButtonWid(
                isLoggedIn: widget.isLoggedIn,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Screen imports
import 'FAQ_screen.dart';
import 'ad_terms_screen.dart';
import 'contact_us_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class AccountScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String phoneNumber;
  final bool isLoggedIn;

  const AccountScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.phoneNumber,
    required this.isLoggedIn,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  bool _isConnected = true;
  bool _isCheckingConnectivity = true;

  // Constants
  static const double _borderRadius = 18.0;
  static const double _padding = 16.0;
  static const EdgeInsets _screenPadding = EdgeInsets.all(_padding);

  @override
  void initState() {
    super.initState();
    _initializeConnectivity();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  // Connectivity Methods
  void _initializeConnectivity() {
    _checkInitialConnectivity();
    _subscribeToConnectivityChanges();
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (mounted) {
        setState(() {
          _isConnected = connectivityResult != ConnectivityResult.none;
          _isCheckingConnectivity = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _isCheckingConnectivity = false;
        });
      }
    }
  }

  void _subscribeToConnectivityChanges() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      if (mounted) {
        setState(() {
          _isConnected = result != ConnectivityResult.none;
        });
      }
    });
  }

  // Navigation Methods
  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  Future<void> _handleLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove('token'),
        prefs.remove('username'),
        prefs.remove('email'),
      ]);
      _navigateToHome();
    } catch (e) {
      // Handle error silently or show snackbar
      _navigateToHome();
    }
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingConnectivity) {
      return _buildLoadingScreen();
    }

    if (!_isConnected) {
      return _buildNoConnectionScreen();
    }

    return _buildMainScreen();
  }

  // Screen Builders
  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildNoConnectionScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wifi_off,
                size: 100,
                color: Colors.grey,
              ),
              const SizedBox(height: 20),
              const Text(
                'لا يوجد اتصال بالإنترنت',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _checkInitialConnectivity,
                child: const Text(
                  'إعادة المحاولة',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainScreen() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Container(
          color: Colors.white,
          child: SingleChildScrollView(
            padding: _screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserCard(),
                const SizedBox(height: 24),
                const SizedBox(height: 16),
                _buildSectionTitle('المعلومات'),
                _buildInfoList(),
                const SizedBox(height: 32),
                _buildAuthButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('حسابي'),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.blue[700],
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.home),
          onPressed: _navigateToHome,
        ),
      ],
    );
  }

  // UI Component Builders
  Widget _buildUserCard() {
    return Container(
      decoration: _buildCardDecoration(),
      padding: const EdgeInsets.all(_padding),
      child: widget.isLoggedIn ? _buildLoggedInUser() : _buildGuestUser(),
    );
  }

  Widget _buildLoggedInUser() {
    return Row(
      children: [
        _buildUserAvatar(Icons.person),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserName(),
              const SizedBox(height: 4),
              _buildUserEmail(),
              if (widget.phoneNumber.isNotEmpty) ...[
                const SizedBox(height: 4),
                _buildPhoneNumber(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuestUser() {
    return Column(
      children: [
        _buildUserAvatar(Icons.person_outline),
        const SizedBox(height: 16),
        const Text(
          'مرحباً بك!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'سجل الدخول للوصول إلى جميع الميزات',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUserAvatar(IconData icon) {
    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.white.withOpacity(0.8),
      child: Icon(
        icon,
        size: 30,
        color: widget.isLoggedIn ? Colors.blue[700] : Colors.blue,
      ),
    );
  }

  Widget _buildUserName() {
    return Text(
      widget.userName,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildUserEmail() {
    return Text(
      widget.userEmail,
      style: TextStyle(
        fontSize: 14,
        color: Colors.white.withOpacity(0.9),
      ),
    );
  }

  Widget _buildPhoneNumber() {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        widget.phoneNumber,
        style: TextStyle(
          fontSize: 14,
          color: Colors.white.withOpacity(0.9),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInfoList() {
    return Container(
      decoration: _buildInfoListDecoration(),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.article,
            title: 'شروط الإعلان',
            onTap: () => _navigateToScreen(const AdTermsScreen()),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.help_center,
            title: 'الأسئلة الشائعة',
            onTap: () => _navigateToScreen(const FAQScreen()),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.call,
            title: 'اتصل بنا',
            onTap: () => _navigateToScreen(const ContactUsScreen()),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue[700]),
      title: Text(
        title,
        style: const TextStyle(color: Colors.black87),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.black87,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: _padding),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: _padding,
      endIndent: _padding,
      color: Colors.blue[200],
    );
  }

  Widget _buildAuthButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: _buildButtonStyle(),
        onPressed: widget.isLoggedIn ? _handleLogout : _navigateToLogin,
        child: Text(
          widget.isLoggedIn ? 'تسجيل الخروج' : 'تسجيل الدخول',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  // Style Builders
  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(_borderRadius),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.blue, Color(0xFF87CEEB)],
      ),
      border: Border.all(color: Colors.blue, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  BoxDecoration _buildInfoListDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(_borderRadius),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, Color(0xFFF8FDFD)],
      ),
      border: Border.all(color: Colors.blue[300]!, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  ButtonStyle _buildButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: widget.isLoggedIn 
          ? const Color(0xFFFF7A59) 
          : Colors.blue[700],
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: _padding),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
    );
  }

  // Utility Methods
  void _navigateToScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}
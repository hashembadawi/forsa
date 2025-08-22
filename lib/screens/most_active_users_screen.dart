import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:syria_market/screens/advertiser_page_screen.dart';

class MostActiveUsersScreen extends StatefulWidget {
  const MostActiveUsersScreen({Key? key}) : super(key: key);

  @override
  State<MostActiveUsersScreen> createState() => _MostActiveUsersScreenState();
}

class _MostActiveUsersScreenState extends State<MostActiveUsersScreen> {
  List<Map<String, dynamic>> _mostActiveUsers = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchMostActiveUsers();
  }

  Future<void> _fetchMostActiveUsers() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final url = Uri.parse('https://sahbo-app-api.onrender.com/api/user/most-active?limit=30');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> users = jsonDecode(response.body);
        setState(() {
          _mostActiveUsers = users.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue[700],
          title: Text('المستخدمين الأكثر حركة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _hasError
                ? Center(child: Text('تعذر تحميل المستخدمين الأكثر حركة', style: GoogleFonts.cairo(color: Colors.red)))
                : _mostActiveUsers.isEmpty
                    ? Center(child: Text('لا يوجد مستخدمين نشطين', style: GoogleFonts.cairo()))
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _mostActiveUsers.length,
                          itemBuilder: (context, index) {
                            final user = _mostActiveUsers[index];
                            final String? base64Image = user['profileImage'];
                            final String userName = ((user['firstName'] ?? '') + ' ' + (user['lastName'] ?? '')).trim();
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AdvertiserPageScreen(
                                      userId: user['userId'] ?? '',
                                      initialUserName: userName,
                                      initialUserPhone: user['phoneNumber'] ?? '',
                                    ),
                                  ),
                                );
                              },
                              child: Column(
                                children: [
                                  Container(
                                    width: 110,
                                    height: 110,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.blue[300]!, width: 2),
                                      color: Colors.white,
                                    ),
                                    child: base64Image != null && base64Image.isNotEmpty
                                        ? ClipOval(
                                            child: Image.memory(
                                              base64Decode(base64Image),
                                              fit: BoxFit.cover,
                                              width: 110,
                                              height: 110,
                                              errorBuilder: (context, error, stackTrace) => Icon(Icons.person, size: 60, color: Colors.blue[400]),
                                            ),
                                          )
                                        : Icon(Icons.person, size: 60, color: Colors.blue[400]),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: 110,
                                    child: Text(
                                      userName,
                                      style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}

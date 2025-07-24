import 'package:flutter/material.dart';
import 'package:sahbo_app/screens/start_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'سوق سوريا',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: 'Arabic',
      ),
      home: const ConnectivityWrapper(),
      debugShowCheckedModeBanner: false
    );
  }
}

class ConnectivityWrapper extends StatefulWidget {
  const ConnectivityWrapper({super.key});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  late StreamSubscription<ConnectivityResult> subscription;
  bool isConnected = true;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    checkInitialConnectivity();
    subscribeToConnectivityChanges();
  }

  Future<void> checkInitialConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      isConnected = connectivityResult != ConnectivityResult.none;
      isLoading = false;
    });
  }

  void subscribeToConnectivityChanges() {
    subscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        isConnected = result != ConnectivityResult.none;
      });
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!isConnected) {
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
                  onPressed: checkInitialConnectivity,
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

    return const StartScreen();
  }
}
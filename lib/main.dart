import 'package:flutter/material.dart';
import 'package:demo1/auth/auth_screen.dart'; // Corrected Import
import 'package:demo1/core/auth_manager.dart'; // Corrected Import
import 'package:demo1/task/task_list_screen.dart'; // Corrected Import
//import 'package:http/http.dart' as http; 

// --- Global Configuration ---
const String apiUrl = 'http://10.0.2.2:3000/api';
//const String apiUrl = 'http://localhost:3000/api'; for the chrome emulator
const String defaultErrorMessage = "An unknown error occurred.";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter To-Do App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

// --- Main Auth Wrapper Widget ---

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isAuthenticated = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final token = await AuthManager.getToken();
    setState(() {
      _isAuthenticated = token != null;
      _isLoading = false;
    });
  }

  void _onLoginSuccess() {
    setState(() {
      _isAuthenticated = true;
    });
  }

  void _onLogout() async {
    await AuthManager.logout();
    setState(() {
      _isAuthenticated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isAuthenticated) {
      return TaskListScreen(onLogout: _onLogout);
    } else {
      return AuthScreen(onLoginSuccess: _onLoginSuccess);
    }
  }
}

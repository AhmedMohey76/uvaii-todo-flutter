import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// -------------------------------------------------------------------
// 1. APP ENTRY POINT (Fixes the "Undefined name 'main'" error)
// -------------------------------------------------------------------
void main() {
  // Use runApp to start the Flutter framework with your main widget
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Warmup App',
      // Set the initial screen to the one that handles API calls
      home: WarmupScreen(),
    );
  }
}

// -------------------------------------------------------------------
// 2. API INTEGRATION SCREEN
// -------------------------------------------------------------------
class WarmupScreen extends StatefulWidget {
  const WarmupScreen({super.key});

  @override
  State<WarmupScreen> createState() => _WarmupScreenState();
}

class _WarmupScreenState extends State<WarmupScreen> {
  // Define variables for data, loading state, and error messages
  List<dynamic> _users = [];
  bool _isLoading = true;
  String _error = '';

  // Function to fetch data from the backend
  Future<void> fetchUsers() async {
    try {
      // *** IMPORTANT ***
      // Use 10.0.2.2 for Android Emulator to connect to your host machine's localhost:3000
      final uri = Uri.parse('http://localhost:3000/api/test/users');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // Successful connection and data retrieval
        setState(() {
          _users = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        // Handle HTTP errors (e.g., 404, 500)
        setState(() {
          _error = 'Failed to load data: Status ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle network errors (e.g., server is down)
      setState(() {
        _error = 'Connection Error: Is the backend server running?';
        _isLoading = false;
      });
      print('Network Error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    // Start fetching data immediately when the widget is created
    fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Integrated Warmup'),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            ) // Show a spinner while loading
          : _error.isNotEmpty
          ? Center(
              child: Text(_error, style: const TextStyle(color: Colors.red)),
            ) // Show error message
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return ListTile(
                  leading: const Icon(Icons.person),
                  // Display the data fetched from the JSON payload
                  title: Text(user['username']),
                  subtitle: Text('ID: ${user['id']} | Role: ${user['role']}'),
                );
              },
            ),
    );
  }
}

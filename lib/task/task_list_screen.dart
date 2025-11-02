import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:demo1/core/auth_manager.dart';
import 'package:demo1/main.dart'; // To access apiUrl

// --- Task Model ---

class Task {
  final int id;
  final String title;
  final bool completed;

  Task({required this.id, required this.title, required this.completed});

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      title: json['title'] as String,
      completed: json['completed'] as bool,
    );
  }
}

// --- Task List Screen ---

class TaskListScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const TaskListScreen({super.key, required this.onLogout});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  bool _isLoading = true;
  final TextEditingController _newTaskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await AuthManager.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _fetchTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$apiUrl/tasks'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List jsonList = jsonDecode(response.body);
        setState(() {
          _tasks = jsonList.map((json) => Task.fromJson(json)).toList();
        });
      } else if (response.statusCode == 401) {
        widget.onLogout(); // Token expired or invalid
      } else {
        // Handle other errors (optional, usually just logs to console)
      }
    } catch (e) {
      // Handle network error (optional, usually just logs to console)
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _addTask() async {
    if (_newTaskController.text.isEmpty) return;
    final title = _newTaskController.text;
    _newTaskController.clear();

    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$apiUrl/tasks'),
        headers: headers,
        body: jsonEncode({'title': title}),
      );

      if (response.statusCode == 201) {
        _fetchTasks();
      } else if (response.statusCode == 401) {
        widget.onLogout();
      }
    } catch (e) {
      // Handle network error
    }
  }

  Future<void> _toggleTaskStatus(Task task) async {
    final newStatus = !task.completed;

    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$apiUrl/tasks/${task.id}'),
        headers: headers,
        body: jsonEncode({'completed': newStatus}),
      );

      if (response.statusCode == 200) {
        _fetchTasks();
      } else if (response.statusCode == 401) {
        widget.onLogout();
      }
    } catch (e) {
      // Handle network error
    }
  }

  Future<void> _deleteTask(int id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$apiUrl/tasks/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        _fetchTasks();
      } else if (response.statusCode == 401) {
        widget.onLogout();
      }
    } catch (e) {
      // Handle network error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My To-Do List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: widget.onLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newTaskController,
                    decoration: const InputDecoration(
                      labelText: 'New Task',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                    onSubmitted: (_) => _addTask(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle,
                    color: Colors.teal,
                    size: 40,
                  ),
                  onPressed: _addTask,
                  tooltip: 'Add Task',
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tasks.isEmpty
                ? Center(
                    child: Text(
                      "No tasks yet. Add one!",
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        elevation: 2,
                        child: ListTile(
                          leading: IconButton(
                            icon: Icon(
                              task.completed
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: task.completed
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            onPressed: () => _toggleTaskStatus(task),
                          ),
                          title: Text(
                            task.title,
                            style: TextStyle(
                              decoration: task.completed
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color: task.completed
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteTask(task.id),
                            tooltip: 'Delete Task',
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

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

  Task copyWith({String? title, bool? completed}) {
    return Task(
      id: id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      // NOTE: Ensure your Task model matches the backend structure (id is required here)
    );
  }

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

  // --- Utility Functions ---

  void _showSnackBar(String message, Color color) {
    // Check if the widget is still mounted before showing SnackBar
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await AuthManager.getToken();
    // If the token is null or empty, this will result in a 401 on the server
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // --- CRUD Operations ---

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
        // The backend returns an array of tasks
        final List jsonList = jsonDecode(response.body);
        setState(() {
          _tasks = jsonList.map((json) => Task.fromJson(json)).toList();
        });
      } else if (response.statusCode == 401) {
        // Token expired or invalid, log out
        widget.onLogout();
      } else {
        _showSnackBar(
          'Failed to load tasks. Status: ${response.statusCode}. Body: ${response.body}',
          Colors.orange,
        );
      }
    } catch (e) {
      // Catch specific network errors like SocketException (no connection)
      _showSnackBar(
        'Network error. Please check the server address ($apiUrl) and connection.',
        Colors.red,
      );
      print('Network Error: $e');
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
        _showSnackBar('Task added successfully!', Colors.green);
        _fetchTasks(); // Refresh the list
      } else if (response.statusCode == 401) {
        widget.onLogout();
      } else {
        _showSnackBar(
          'Failed to add task. Status: ${response.statusCode}. Body: ${response.body}',
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar('Network error. Could not add task.', Colors.red);
      print('Network Error: $e');
    }
  }

  // Generalized update function for both status and title
  Future<void> _updateTask({
    required Task task,
    bool? newCompletedStatus,
    String? newTitle,
  }) async {
    final updatedTask = task.copyWith(
      completed: newCompletedStatus ?? task.completed,
      title: newTitle ?? task.title,
    );

    // Prepare the body with only the fields that are actually changing
    final Map<String, dynamic> updateBody = {
      // Send both title and completed status in the PUT request
      'completed': updatedTask.completed, 
      'title': updatedTask.title, 
    };

    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$apiUrl/tasks/${task.id}'),
        headers: headers,
        body: jsonEncode(updateBody),
      );

      if (response.statusCode == 200) {
        // Optimistic UI update: immediately update the list
        setState(() {
          final index = _tasks.indexWhere((t) => t.id == task.id);
          if (index != -1) {
            _tasks[index] = updatedTask;
          }
        });
        if (newTitle != null) {
          _showSnackBar('Task updated successfully!', Colors.green);
        }
      } else if (response.statusCode == 401) {
        widget.onLogout();
      } else {
        _showSnackBar(
          'Failed to update task. Status: ${response.statusCode}. Body: ${response.body}',
          Colors.red,
        );
        _fetchTasks(); // Re-fetch on failure to sync state
      }
    } catch (e) {
      _showSnackBar('Network error. Could not update task.', Colors.red);
      _fetchTasks(); // Re-fetch on network error
      print('Network Error: $e');
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
        // Optimistic UI update: remove from list immediately
        setState(() {
          _tasks.removeWhere((t) => t.id == id);
        });
        _showSnackBar('Task deleted successfully!', Colors.grey);
      } else if (response.statusCode == 401) {
        widget.onLogout();
      } else {
        _showSnackBar(
          'Failed to delete task. Status: ${response.statusCode}. Body: ${response.body}',
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar('Network error. Could not delete task.', Colors.red);
      print('Network Error: $e');
    }
  }

  // --- Edit Dialog ---

  Future<void> _showEditDialog(Task task) async {
    final TextEditingController editController = TextEditingController(
      text: task.title,
    );

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Task'),
          content: TextField(
            controller: editController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Task Title'),
            onSubmitted: (value) {
              if (value.isNotEmpty && value != task.title) {
                _updateTask(task: task, newTitle: value);
              }
              Navigator.of(context).pop();
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                if (editController.text.isNotEmpty &&
                    editController.text != task.title) {
                  _updateTask(task: task, newTitle: editController.text);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // --- Widget Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Secure To-Do List'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchTasks,
            tooltip: 'Refresh List',
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: widget.onLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newTaskController,
                    decoration: InputDecoration(
                      labelText: 'New Task',
                      hintText: 'Enter task title...',
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      fillColor: Colors.grey.shade100,
                      filled: true,
                    ),
                    onSubmitted: (_) => _addTask(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle,
                    color: Colors.teal,
                    size: 44,
                  ),
                  onPressed: _addTask,
                  tooltip: 'Add Task',
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.teal),
                  )
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
                              horizontal: 12,
                              vertical: 4,
                            ),
                            elevation: 3,
                            child: ListTile(
                              // Tapping the main body opens the edit dialog
                              onTap: () => _showEditDialog(task),
                              leading: IconButton(
                                icon: Icon(
                                  task.completed
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked,
                                  color: task.completed
                                      ? Colors.green.shade600
                                      : Colors.teal.shade300,
                                  size: 28,
                                ),
                                onPressed: () => _updateTask(
                                  task: task,
                                  newCompletedStatus: !task.completed,
                                ),
                                tooltip: task.completed
                                    ? 'Mark incomplete'
                                    : 'Mark complete',
                              ),
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  decoration: task.completed
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  color: task.completed
                                      ? Colors.grey.shade600
                                      : Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_forever,
                                  color: Colors.redAccent,
                                ),
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

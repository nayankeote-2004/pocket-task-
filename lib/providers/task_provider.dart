import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocket_task/models/task.dart';

enum FilterType { all, active, done }

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  String _searchQuery = '';
  FilterType _currentFilter = FilterType.all;
  Timer? _debounceTimer;
  static const String storageKey = 'pocket_tasks_v1';

  List<Task> get tasks => _tasks;
  List<Task> get filteredTasks => _filteredTasks;
  FilterType get currentFilter => _currentFilter;
  String get searchQuery => _searchQuery;

  int get totalTasks => _tasks.length;
  int get completedTasks => _tasks.where((task) => task.done).length;

  TaskProvider() {
    _updateFilteredTasks();
  }

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString(storageKey);
    
    if (tasksJson != null) {
      _tasks = Task.fromJsonList(tasksJson);
      _updateFilteredTasks();
      notifyListeners();
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, Task.toJsonList(_tasks));
  }

  void _updateFilteredTasks() {
    _filteredTasks = _tasks.where((task) {
      final matchesSearch = _searchQuery.isEmpty || 
          task.title.toLowerCase().contains(_searchQuery.toLowerCase());
  
      final matchesFilter = _currentFilter == FilterType.all ||
          (_currentFilter == FilterType.active && !task.done) ||
          (_currentFilter == FilterType.done && task.done);
      
      return matchesSearch && matchesFilter;
    }).toList();
    
   
    _filteredTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> addTask(String title) async {
    if (title.trim().isEmpty) return;
    
    final newTask = Task(title: title.trim());
    _tasks.add(newTask);
    _updateFilteredTasks();
    notifyListeners();
    await _saveTasks();
  }

  Future<void> toggleTask(String id) async {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      _tasks[index].done = !_tasks[index].done;
      _updateFilteredTasks();
      notifyListeners();
      await _saveTasks();
    }
  }

  Future<Task?> deleteTask(String id) async {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      final deletedTask = _tasks[index];
      _tasks.removeAt(index);
      _updateFilteredTasks();
      notifyListeners();
      await _saveTasks();
      return deletedTask; // Return for undo functionality
    }
    return null;
  }

  Future<void> undoDelete(Task task) async {
    _tasks.add(task);
    _updateFilteredTasks();
    notifyListeners();
    await _saveTasks();
  }

  Future<void> undoToggle(String id) async {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      _tasks[index].done = !_tasks[index].done;
      _updateFilteredTasks();
      notifyListeners();
      await _saveTasks();
    }
  }

  void setFilter(FilterType filter) {
    _currentFilter = filter;
    _updateFilteredTasks();
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    // Cancel any previous debounce timer
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    // Set a new timer
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchQuery = query;
      _updateFilteredTasks();
      notifyListeners();
    });
  }
}
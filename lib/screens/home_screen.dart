import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pocket_task/providers/task_provider.dart';
import 'package:pocket_task/widgets/task_progress_ring.dart';
import 'package:pocket_task/widgets/task_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _hasError = false;

  @override
  void dispose() {
    _taskController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addTask() {
    if (_taskController.text.trim().isEmpty) {
      setState(() {
        _hasError = true;
      });
      return;
    }

    setState(() {
      _hasError = false;
    });

    Provider.of<TaskProvider>(
      context,
      listen: false,
    ).addTask(_taskController.text);
    _taskController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final taskProvider = Provider.of<TaskProvider>(context);
    final completedTasks = taskProvider.completedTasks;
    final totalTasks = taskProvider.totalTasks;

    return GestureDetector(
      onTap: () {
        // Remove focus from text fields when tapping elsewhere
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 100,
          title: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: TaskProgressRing(
                      completed: completedTasks,
                      total: totalTasks > 0 ? totalTasks : 0,
                    ),
                  ),
                  Text(
                    totalTasks > 0 ? '$completedTasks/$totalTasks' : '0',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              const Text(
                'Pocket Tasks',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Add task section
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _taskController,
                      decoration: InputDecoration(
                        hintText: 'Add Task',
                        errorText: _hasError ? 'Task cannot be empty' : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      onSubmitted: (_) => _addTask(),
                      onChanged: (_) {
                        if (_hasError) {
                          setState(() {
                            _hasError = false;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _addTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF5C2E9D)
                          : Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Search box
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onChanged: taskProvider.updateSearchQuery,
              ),

              const SizedBox(height: 16),

              // Filter chips
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: taskProvider.currentFilter == FilterType.all,
                    onSelected: (_) => taskProvider.setFilter(FilterType.all),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Active'),
                    selected: taskProvider.currentFilter == FilterType.active,
                    onSelected: (_) =>
                        taskProvider.setFilter(FilterType.active),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Done'),
                    selected: taskProvider.currentFilter == FilterType.done,
                    onSelected: (_) => taskProvider.setFilter(FilterType.done),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Task list
              Expanded(
                child: taskProvider.filteredTasks.isEmpty
                    ? Center(
                        child: Text(
                          'No tasks found',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: taskProvider.filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = taskProvider.filteredTasks[index];
                          return Dismissible(
                            key: ValueKey(task.id),
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) {
                              final deletedTask = task;
                              taskProvider.deleteTask(task.id);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  duration: const Duration(seconds: 5),
                                  content: const Text('Task deleted'),
                                  action: SnackBarAction(
                                    label: 'Undo',
                                    onPressed: () {
                                      taskProvider.undoDelete(deletedTask);
                                    },
                                  ),
                                ),
                              );
                            },
                            child: TaskItem(
                              task: task,
                              onToggle: () {
                                taskProvider.toggleTask(task.id);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      task.done
                                          ? 'Task marked as done'
                                          : 'Task marked as active',
                                    ),
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      onPressed: () {
                                        taskProvider.undoToggle(task.id);
                                      },
                                    ),
                                  ),
                                );
                              },
                              onDelete: () {
                                final deletedTask = task;
                                taskProvider.deleteTask(task.id);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Task deleted'),
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      onPressed: () {
                                        taskProvider.undoDelete(deletedTask);
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

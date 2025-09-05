import 'package:flutter/material.dart';
import 'package:smart_warehouse_manager/models/task_model.dart';
import 'package:smart_warehouse_manager/services/task_service.dart';
import 'package:intl/intl.dart';
import 'add_edit_task_screen.dart'; // Import màn hình Thêm/Sửa

class TasksView extends StatefulWidget {
  const TasksView({Key? key}) : super(key: key);

  @override
  _TasksViewState createState() => _TasksViewState();
}

class _TasksViewState extends State<TasksView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TaskService _taskService = TaskService();
  final TextEditingController _searchController = TextEditingController();

  List<Task> _allTasks = [];
  List<Task> _filteredTasks = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTasks();
    _tabController.addListener(_runFilter);
    _searchController.addListener(_runFilter);
  }

  Future<void> _loadTasks({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = '';
      });
    }
    try {
      final tasks = await _taskService.getTasks();
      setState(() {
        _allTasks = tasks;
        _runFilter();
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi tải dữ liệu: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _runFilter() {
    List<Task> results = [];
    final enteredKeyword = _searchController.text.toLowerCase();
    
    // 1. Lọc theo từ khóa tìm kiếm
    if (enteredKeyword.isEmpty) {
      results = _allTasks;
    } else {
      results = _allTasks.where((task) {
        final typeMatch = task.type.toLowerCase().contains(enteredKeyword);
        final skuMatch = task.payload.sku.toLowerCase().contains(enteredKeyword);
        final whMatch = task.payload.wh.toLowerCase().contains(enteredKeyword);
        final assigneeMatch = task.assignee?.toLowerCase().contains(enteredKeyword) ?? false;
        return typeMatch || skuMatch || whMatch || assigneeMatch;
      }).toList();
    }
    
    // 2. Lọc theo Tab
    final tabIndex = _tabController.index;
    List<Task> finalResults = [];
    if (tabIndex == 1) { // Open
      finalResults = results.where((task) => task.status == 'open').toList();
    } else if (tabIndex == 2) { // Done
      finalResults = results.where((task) => task.status == 'done').toList();
    } else { // All
      finalResults = results;
    }

    setState(() {
      _filteredTasks = finalResults;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.orange;
      case 'done':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  
  // --- CÁC CHỨC NĂNG CHÍNH ---

  void _navigateToAddTask() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const AddEditTaskScreen()),
    );
    if (result == true) {
      _loadTasks();
    }
  }

  void _navigateToEditTask(Task task) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => AddEditTaskScreen(task: task)),
    );
    if (result == true) {
      _loadTasks();
    }
  }

  void _deleteTask(String id) async {
    try {
      await _taskService.deleteTask(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa công việc!')),
      );
      _loadTasks(showLoading: false); // Tải lại danh sách không cần indicator
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xóa: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Open'),
            Tab(text: 'Done'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadTasks(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by type, SKU, WH, assignee...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error.isNotEmpty
                        ? Center(child: Text(_error))
                        : _buildTaskList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTask,
        child: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildTaskList() {
    if (_filteredTasks.isEmpty) {
      return Center(child: Text(_searchController.text.isEmpty 
        ? 'Không có công việc nào trong mục này.'
        : 'Không tìm thấy kết quả nào.'));
    }
    return ListView.builder(
      itemCount: _filteredTasks.length,
      itemBuilder: (context, index) {
        final task = _filteredTasks[index];
        final title = '${task.type.toUpperCase()}: ${task.payload.sku} - WH: ${task.payload.wh}';

        return GestureDetector(
          onTap: () => _navigateToEditTask(task),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                        onPressed: () => _deleteTask(task.id),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.person, 'Assignee: ${task.assignee ?? "Chưa gán"}'),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.priority_high, 'Priority: ${task.priority}'),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.calendar_today, 'Due date: ${task.dueAt != null ? DateFormat.yMd().format(task.dueAt!) : 'N/A'}'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _getStatusColor(task.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Status: ${task.status}',
                        style: TextStyle(
                          color: _getStatusColor(task.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}
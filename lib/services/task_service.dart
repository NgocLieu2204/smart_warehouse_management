import 'package:dio/dio.dart';
import 'package:smart_warehouse_manager/models/task_model.dart';

class TaskService {
  // Thay thế 'localhost' bằng địa chỉ IP của máy bạn nếu chạy trên thiết bị thật
  // Ví dụ: 'http://192.168.1.10:5000/api/tasks'
  final String _baseUrl = 'http://10.0.2.2:5000/api/tasks';
  final Dio _dio = Dio();

  // Lấy tất cả Tasks
  Future<List<Task>> getTasks() async {
    try {
      final response = await _dio.get('$_baseUrl/getTasks');
      return (response.data as List).map((task) => Task.fromJson(task)).toList();
    } catch (e) {
      throw Exception('Failed to load tasks: $e');
    }
  }

  // Tạo Task mới
  Future<Task> createTask(Task task) async {
    try {
      final response = await _dio.post(_baseUrl, data: task.toJson());
      return Task.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  // Cập nhật Task
  Future<Task> updateTask(String id, Task task) async {
    try {
      final response = await _dio.put('$_baseUrl/$id', data: task.toJson());
      return Task.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  // Xóa Task
  Future<void> deleteTask(String id) async {
    try {
      await _dio.delete('$_baseUrl/$id');
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }
}
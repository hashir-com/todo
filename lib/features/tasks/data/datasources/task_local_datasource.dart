import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/task_model.dart';

abstract class TaskLocalDataSource {
  Future<void> cacheTasks(List<TaskModel> tasks);
  Future<List<TaskModel>> getCachedTasks();
  Future<void> cacheTask(TaskModel task);
  Future<TaskModel?> getCachedTask(String taskId);
  Future<void> deleteTask(String taskId);
  Future<void> clearCache();
}

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  static const String tasksBoxName = 'tasks_box';

  @override
  Future<void> cacheTasks(List<TaskModel> tasks) async {
    try {
      final box = await Hive.openBox(tasksBoxName);
      final tasksMap = {
        for (var task in tasks) task.id: task.toJson()
      };
      await box.put('all_tasks', tasksMap);
    } catch (e) {
      throw CacheException('Failed to cache tasks');
    }
  }

  @override
  Future<List<TaskModel>> getCachedTasks() async {
    try {
      final box = await Hive.openBox(tasksBoxName);
      final tasksMap = box.get('all_tasks');
      
      if (tasksMap == null) return [];

      final Map<String, dynamic> tasks = Map<String, dynamic>.from(tasksMap);
      return tasks.values
          .map((taskJson) => TaskModel.fromJson(Map<String, dynamic>.from(taskJson)))
          .toList();
    } catch (e) {
      throw CacheException('Failed to get cached tasks');
    }
  }

  @override
  Future<void> cacheTask(TaskModel task) async {
    try {
      final box = await Hive.openBox(tasksBoxName);
      final tasksMap = box.get('all_tasks') ?? {};
      final tasks = Map<String, dynamic>.from(tasksMap);
      tasks[task.id] = task.toJson();
      await box.put('all_tasks', tasks);
    } catch (e) {
      throw CacheException('Failed to cache task');
    }
  }

  @override
  Future<TaskModel?> getCachedTask(String taskId) async {
    try {
      final box = await Hive.openBox(tasksBoxName);
      final tasksMap = box.get('all_tasks');
      
      if (tasksMap == null) return null;

      final tasks = Map<String, dynamic>.from(tasksMap);
      final taskJson = tasks[taskId];
      
      if (taskJson == null) return null;
      
      return TaskModel.fromJson(Map<String, dynamic>.from(taskJson));
    } catch (e) {
      throw CacheException('Failed to get cached task');
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    try {
      final box = await Hive.openBox(tasksBoxName);
      final tasksMap = box.get('all_tasks') ?? {};
      final tasks = Map<String, dynamic>.from(tasksMap);
      tasks.remove(taskId);
      await box.put('all_tasks', tasks);
    } catch (e) {
      throw CacheException('Failed to delete cached task');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final box = await Hive.openBox(tasksBoxName);
      await box.clear();
    } catch (e) {
      throw CacheException('Failed to clear cache');
    }
  }
}
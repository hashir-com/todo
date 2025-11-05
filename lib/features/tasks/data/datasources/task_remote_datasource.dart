// lib/features/tasks/data/datasources/task_remote_datasource.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/task_model.dart';

abstract class TaskRemoteDataSource {
  Future<List<TaskModel>> getTasks(String userId);
  Future<TaskModel> getTaskById(String taskId, String userId);
  Future<TaskModel> createTask(TaskModel task);
  Future<TaskModel> updateTask(TaskModel task);
  Future<void> deleteTask(String taskId, String userId);
  Future<TaskModel> toggleTaskStatus(String taskId, String userId);
  Stream<List<TaskModel>> watchTasks(String userId);
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final FirebaseFirestore firestore;

  TaskRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<TaskModel>> getTasks(String userId) async {
    try {
      final querySnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .orderBy('createdAt', descending: true)
          .get();

      // Check and update overdue statuses asynchronously
      for (final doc in querySnapshot.docs) {
        final task = TaskModel.fromFirestore(doc.data(), doc.id);
        final now = DateTime.now();
        final graceEnd = task.dueDate.add(const Duration(hours: 24));
        if (task.status == 'pending' && now.isAfter(task.dueDate)) {
          // Set to overdue
          doc.reference.update({
            'status': 'overdue',
            'updatedAt': now.toIso8601String(),
          });
        } else if (task.status == 'overdue' &&
            !task.permanentlyOverdue &&
            now.isAfter(graceEnd)) {
          // Set permanently overdue
          doc.reference.update({
            'permanentlyOverdue': true,
            'updatedAt': now.toIso8601String(),
          });
        }
      }

      return querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch tasks: ${e.toString()}');
    }
  }

  @override
  Future<TaskModel> getTaskById(String taskId, String userId) async {
    try {
      final doc = await firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .get();

      if (!doc.exists) {
        throw ServerException('Task not found');
      }

      return TaskModel.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw ServerException('Failed to fetch task: ${e.toString()}');
    }
  }

  @override
  Future<TaskModel> createTask(TaskModel task) async {
    try {
      final docRef = await firestore
          .collection('users')
          .doc(task.userId)
          .collection('tasks')
          .add(task.toFirestore());

      final createdDoc = await docRef.get();
      return TaskModel.fromFirestore(createdDoc.data()!, createdDoc.id);
    } catch (e) {
      throw ServerException('Failed to create task: ${e.toString()}');
    }
  }

  @override
  Future<TaskModel> updateTask(TaskModel task) async {
    try {
      final taskRef = firestore
          .collection('users')
          .doc(task.userId)
          .collection('tasks')
          .doc(task.id);

      final currentDoc = await taskRef.get();
      if (!currentDoc.exists) {
        throw ServerException('Task not found');
      }

      final currentData = currentDoc.data()!;
      final currentStatus = currentData['status'] ?? 'pending';
      final currentPermOverdue = currentData['permanentlyOverdue'] ?? false;
      final currentDueDateStr = currentData['dueDate'];
      final currentDueDate = currentDueDateStr != null
          ? DateTime.parse(currentDueDateStr)
          : DateTime.now();

      // Prevent completing permanently overdue tasks
      if (task.status == 'completed' &&
          currentStatus == 'overdue' &&
          currentPermOverdue) {
        throw ServerException('Cannot complete permanently overdue task');
      }

      // Handle rescheduling past due to future: reset status
      bool shouldReset = false;
      if (currentDueDate.isBefore(DateTime.now()) &&
          task.dueDate.isAfter(DateTime.now())) {
        shouldReset = true;
      }

      Map<String, dynamic> updateData = task.toFirestore();
      if (shouldReset) {
        updateData['status'] = 'pending';
        updateData['permanentlyOverdue'] = false;
      } else if (task.status == 'completed' && currentStatus == 'overdue') {
        updateData['permanentlyOverdue'] = false;
      }

      await taskRef.update(updateData);

      final updatedDoc = await taskRef.get();
      return TaskModel.fromFirestore(updatedDoc.data()!, updatedDoc.id);
    } catch (e) {
      throw ServerException('Failed to update task: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteTask(String taskId, String userId) async {
    try {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .delete();
    } catch (e) {
      throw ServerException('Failed to delete task: ${e.toString()}');
    }
  }

  @override
  Future<TaskModel> toggleTaskStatus(String taskId, String userId) async {
    try {
      final taskRef = firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId);

      final doc = await taskRef.get();

      if (!doc.exists) {
        throw ServerException('Task not found');
      }

      final taskData = doc.data()!;
      final currentStatus = taskData['status'] ?? 'pending';
      final currentPermOverdue = taskData['permanentlyOverdue'] ?? false;

      // Prevent toggling permanently overdue tasks
      if (currentStatus == 'overdue' && currentPermOverdue) {
        throw ServerException('Cannot complete permanently overdue task');
      }

      final newStatus = currentStatus == 'completed' ? 'pending' : 'completed';

      Map<String, dynamic> updateData = {
        'status': newStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (newStatus == 'completed' && currentStatus == 'overdue') {
        updateData['permanentlyOverdue'] = false;
      }

      await taskRef.update(updateData);

      final updatedDoc = await taskRef.get();
      return TaskModel.fromFirestore(updatedDoc.data()!, updatedDoc.id);
    } catch (e) {
      throw ServerException('Failed to toggle task status: ${e.toString()}');
    }
  }

  @override
  Stream<List<TaskModel>> watchTasks(String userId) {
    try {
      return firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        final tasks = snapshot.docs.map((doc) {
          final model = TaskModel.fromFirestore(doc.data(), doc.id);
          final now = DateTime.now();
          final graceEnd = model.dueDate.add(const Duration(hours: 24));

          // Async update to overdue if past due
          if (model.status == 'pending' && now.isAfter(model.dueDate)) {
            doc.reference.update({
              'status': 'overdue',
              'updatedAt': now.toIso8601String(),
            });
          }
          // Async set permanently overdue if grace period ended
          else if (model.status == 'overdue' &&
              !model.permanentlyOverdue &&
              now.isAfter(graceEnd)) {
            doc.reference.update({
              'permanentlyOverdue': true,
              'updatedAt': now.toIso8601String(),
            });
          }

          return model;
        }).toList();
        return tasks;
      });
    } catch (e) {
      throw ServerException('Failed to watch tasks: ${e.toString()}');
    }
  }
}

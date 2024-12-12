import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/models/task.dart';
import 'package:app/models/subtask.dart';
import 'package:app/models/subtask_item.dart';
import 'package:app/models/attachment.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String collectionPath = 'tasks';
  //final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// Fetch tasks for a specific project along with their subtasks
  Stream<List<Task>> getTasksForProject(String projectId) {
    return _db
        .collection('tasks') // Firestore tasks collection
        .where('projectId', isEqualTo: projectId) // Filter by project ID
        .snapshots()
        .asyncMap((snapshot) async {
      List<Task> tasks = [];

      print("Debug: Fetching tasks for project ID: $projectId");

      for (var doc in snapshot.docs) {
        try {
          final taskData = doc.data();
          final taskId = doc.id;

          print("Debug: Processing Task ID: $taskId, Task Data: $taskData");

          // Fetch subtasks for the current task
          final subTasksSnapshot = await _db
              .collection('tasks') // Parent collection
              .doc(taskId)
              .collection('subtasks') // Nested subtasks collection
              .get();

          print(
              "Debug: Found ${subTasksSnapshot.docs.length} subtasks for Task ID: $taskId");

          // Map subtasks data
          final subtasks = subTasksSnapshot.docs.map((subDoc) {
            return SubTask.fromMap(subDoc.data());
          }).toList();

          // Combine task and its subtasks
          final task =
              Task.fromMap(taskData, taskId).copyWith(subTasks: subtasks);
          tasks.add(task);

          print(
              "Debug: Task '$taskId' enriched with ${subtasks.length} subtasks.");
        } catch (e, stackTrace) {
          print("Error: Failed to fetch subtasks for Task ID: ${doc.id}");
          print("Error Details: $e");
          print("Stack Trace: $stackTrace");
        }
      }

      print(
          "Debug: Completed fetching tasks with subtasks. Total: ${tasks.length}");
      return tasks;
    });
  }

// Fetch tasks for the currently logged-in user along with subtasks
  Stream<List<Task>> getTasksForUser() {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      log("User not logged in. Returning empty task stream.");
      return const Stream.empty();
    }

    log("Fetching tasks for user ID: $currentUserId with subtasks.");

    return _db
        .collection('tasks') // Firestore tasks collection
        .where('createdBy',
            isEqualTo: currentUserId) // Filter tasks created by user
        .snapshots()
        .asyncMap((snapshot) async {
      List<Task> tasks = [];

      for (var doc in snapshot.docs) {
        try {
          final taskData = doc.data();
          final taskId = doc.id;

          log("Processing Task ID: $taskId");

          // Fetch subtasks for the current task
          final subTasksSnapshot = await _db
              .collection('tasks') // Parent tasks collection
              .doc(taskId)
              .collection('subtasks') // Subtasks collection
              .get();

          final subtasks = subTasksSnapshot.docs.map((subDoc) {
            return SubTask.fromMap(subDoc.data());
          }).toList();

          // Combine task and its subtasks
          final task =
              Task.fromMap(taskData, taskId).copyWith(subTasks: subtasks);
          tasks.add(task);

          log("Task '$taskId' enriched with ${subtasks.length} subtasks.");
        } catch (e, stackTrace) {
          log("Error fetching subtasks for Task ID: ${doc.id}");
          log("Details: $e");
        }
      }

      return tasks;
    });
  }

  // Add a task to Firestore
  Future<void> addTask(Task task) async {
    try {
      await _db.collection(collectionPath).doc(task.id).set(task.toMap());
      print("Task added successfully with ID: ${task.id}");
    } catch (e) {
      print("Error adding task to Firestore: $e");
      rethrow;
    }
  }

  // Stream to get a task with its subtasks
  Stream<Task> getTaskStreamById(String taskId) {
    return _db.collection(collectionPath).doc(taskId).snapshots().asyncMap(
      (taskSnapshot) async {
        if (taskSnapshot.exists) {
          // Fetch the subtasks
          final subTasksSnapshot = await _db
              .collection(collectionPath)
              .doc(taskId)
              .collection('subtasks')
              .get();

          final subtasks = subTasksSnapshot.docs
              .map((subDoc) => SubTask.fromMap(subDoc.data()))
              .toList();

          // Return the task with its subtasks
          return Task.fromMap(
                  taskSnapshot.data() as Map<String, dynamic>, taskId)
              .copyWith(subTasks: subtasks);
        } else {
          throw Exception("Task not found");
        }
      },
    );
  }

  // Get a task by its ID from Firestore, including its subtasks
  Future<Task> getTaskById(String taskId) async {
    try {
      print("Debug: Fetching task with ID: $taskId");

      // Step 1: Fetch the task document
      DocumentSnapshot taskSnapshot =
          await _db.collection(collectionPath).doc(taskId).get();

      if (taskSnapshot.exists) {
        print("Debug: Task document found for ID: $taskId");

        // Step 2: Fetch subtasks from the 'subtasks' subcollection
        final subTasksSnapshot = await _db
            .collection(collectionPath)
            .doc(taskId)
            .collection('subtasks')
            .get();

        print(
            "Debug: Fetched ${subTasksSnapshot.docs.length} subtasks for Task ID: $taskId");

        // Step 3: Convert subtasks to a list of SubTask objects
        final subtasks = subTasksSnapshot.docs.map((subDoc) {
          print("Debug: SubTask Data: ${subDoc.data()}");
          return SubTask.fromMap(subDoc.data());
        }).toList();

        // Step 4: Construct the Task object with subtasks
        final task = Task.fromMap(
          taskSnapshot.data() as Map<String, dynamic>,
          taskSnapshot.id,
        ).copyWith(subTasks: subtasks);

        print(
            "Debug: Task '${task.title}' fetched successfully with ${subtasks.length} subtasks.");

        return task;
      } else {
        print("Error: Task with ID $taskId not found in Firestore.");
        throw Exception("Task not found");
      }
    } catch (e, stackTrace) {
      print("Error: Failed to fetch task with ID $taskId - $e");
      print("Stack Trace: $stackTrace");
      rethrow;
    }
  }

  /// Retrieves a Task along with its Subtasks as a Stream
  Stream<Task> getTaskWithSubtasks(String taskId) {
    return _db
        .collection(collectionPath)
        .doc(taskId)
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.exists) {
        final taskData = snapshot.data() as Map<String, dynamic>;

        // Fetch subtasks for this task
        final subTasksSnapshot = await _db
            .collection(collectionPath)
            .doc(taskId)
            .collection('subtasks')
            .get();

        final subtasks = subTasksSnapshot.docs
            .map((subDoc) => SubTask.fromMap(subDoc.data()))
            .toList();

        // Return Task with its Subtasks
        return Task.fromMap(taskData, snapshot.id).copyWith(subTasks: subtasks);
      } else {
        throw Exception("Task not found");
      }
    });
  }

  // Update an existing task in Firestore
  Future<void> updateTask(Task task) async {
    try {
      await _db.collection(collectionPath).doc(task.id).update(task.toMap());
      print("Task updated successfully with ID: ${task.id}");
    } catch (e) {
      print("Error updating task in Firestore: $e");
      rethrow;
    }
  }

  // Delete a task from Firestore
  Future<void> deleteTask(String taskId) async {
    try {
      await _db.collection(collectionPath).doc(taskId).delete();
      print("Task deleted successfully with ID: $taskId");
    } catch (e) {
      print("Error deleting task from Firestore: $e");
      rethrow;
    }
  }

// Add a subtask to a task with detailed debugging
  Future<void> addSubTask(String taskId, SubTask subTask) async {
    try {
      // Step 1: Log the incoming taskId and subTask details
      print("Debug: Adding subtask to Task ID: $taskId");
      print(
          "Debug: SubTask Details - ID: ${subTask.id}, Title: ${subTask.title}, Data: ${subTask.toMap()}");

      // Step 2: Get Firestore references
      final taskRef = _db.collection(collectionPath).doc(taskId);
      final subTasksRef = taskRef.collection('subtasks');

      print(
          "Debug: Firestore Reference - Collection: $collectionPath, Document: $taskId, Subtasks Collection: subtasks");

      // Step 3: Add the subtask to Firestore
      await subTasksRef.doc(subTask.id).set(subTask.toMap());

      // Step 4: Log success
      print(
          "Success: Subtask '${subTask.title}' added successfully with ID: ${subTask.id} under Task ID: $taskId");
    } catch (e, stackTrace) {
      // Step 5: Log error details with stack trace for debugging
      print(
          "Error: Failed to add subtask '${subTask.title}' to Task ID: $taskId");
      print("Error Details: $e");
      print("Stack Trace: $stackTrace");

      // Step 6: Rethrow the error for further handling
      rethrow;
    }
  }

  Stream<List<SubTask>> getSubTasks(String taskId) {
    return _db
        .collection('tasks')
        .doc(taskId)
        .collection('subtasks')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return SubTask.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Stream<SubTask> getSubTaskById(String taskId, String subTaskId) {
    return _db
        .collection('tasks')
        .doc(taskId)
        .collection('subtasks')
        .doc(subTaskId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return SubTask.fromMap(snapshot.data()!);
      } else {
        throw Exception("Subtask not found");
      }
    });
  }

  // Toggle task completion status
  Future<void> toggleTaskCompletion(Task task) async {
    try {
      final taskRef = _db.collection(collectionPath).doc(task.id);
      await taskRef.update({'isCompleted': !task.isCompleted});
      print("Task completion status toggled for Task ID: ${task.id}");
    } catch (e) {
      print("Error toggling task completion: $e");
      rethrow;
    }
  }

  // Remove an attachment from a task
  Future<void> removeAttachment(String taskId, String attachmentId) async {
    try {
      final taskRef = _db.collection(collectionPath).doc(taskId);
      final taskDoc = await taskRef.get();

      if (taskDoc.exists) {
        final taskData = taskDoc.data()!;
        final attachments = List.from(taskData['attachments']);

        attachments
            .removeWhere((attachment) => attachment['id'] == attachmentId);

        await taskRef.update({'attachments': attachments});
        print("Attachment removed successfully for Task ID: $taskId");
      }
    } catch (e) {
      print("Error removing attachment: $e");
      rethrow;
    }
  }

  // Add an attachment to a task
  Future<void> addAttachment(String taskId, Attachment attachment) async {
    try {
      final taskRef = _db.collection(collectionPath).doc(taskId);
      final taskDoc = await taskRef.get();

      if (taskDoc.exists) {
        final taskData = taskDoc.data()!;
        final attachments = List.from(taskData['attachments']);

        attachments.add(attachment.toMap());

        await taskRef.update({'attachments': attachments});
        print("Attachment added successfully for Task ID: $taskId");
      }
    } catch (e) {
      print("Error adding attachment: $e");
      rethrow;
    }
  }

  // Method to delete a task from Firestore
  Future<void> removeTask(String taskId) async {
    try {
      // Delete the task document from Firestore using the task ID
      await _db.collection(collectionPath).doc(taskId).delete();
      print("Task deleted successfully with ID: $taskId");
    } catch (e) {
      print("Error deleting task from Firestore: $e");
      rethrow; // Propagate the error to be handled by the caller
    }
  }

  Future<void> deleteRepeatingTasks(Task task, {required String option}) async {
    try {
      WriteBatch batch = _db.batch(); // Create a Firestore batch

      switch (option) {
        case "all":
          await _deleteTasksByGroupId(task.repeatingGroupId, batch);
          break;
        case "this_and_following":
          await _deleteThisAndFollowingTasks(task, batch);
          break;
        case "only_this":
          await _deleteOnlyThisTask(task, batch);
          break;
        default:
          log('Unknown delete option: $option');
      }

      await batch.commit(); // Commit all operations atomically
      log('Batch delete operation completed successfully.');
    } catch (e, stackTrace) {
      log('Error performing batch deletion: $e');
      log(stackTrace.toString());
      rethrow;
    }
  }

  // Helper method: Batch delete tasks by groupId
  Future<void> _deleteTasksByGroupId(
      String? repeatingGroupId, WriteBatch batch) async {
    if (repeatingGroupId == null) {
      log('Task does not have a repeatingGroupId');
      return;
    }

    final querySnapshot = await _db
        .collection(collectionPath)
        .where('repeatingGroupId', isEqualTo: repeatingGroupId)
        .get();

    for (var doc in querySnapshot.docs) {
      batch.delete(doc.reference); // Add each delete operation to the batch
    }

    log('Added ${querySnapshot.docs.length} tasks to batch for groupId: $repeatingGroupId');
  }

  // Helper method: Batch delete this task and all subsequent tasks
  Future<void> _deleteThisAndFollowingTasks(Task task, WriteBatch batch) async {
    if (task.repeatingGroupId == null || task.deadline == null) {
      log('Task does not have a repeatingGroupId or deadline: ${task.title}');
      return;
    }

    try {
      // Query tasks with the same repeatingGroupId and deadline >= current task
      final querySnapshot = await _db
          .collection(collectionPath)
          .where('repeatingGroupId', isEqualTo: task.repeatingGroupId)
          .where('deadline', isGreaterThanOrEqualTo: task.deadline)
          .get();

      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference); // Add each delete operation to the batch
      }
      log("Batch deletion prepared for ${querySnapshot.docs.length} tasks.");
    } catch (e) {
      log("Error fetching tasks for batch deletion: $e");
      rethrow; // Rethrow the exception to handle it upstream
    }
  }

  // Helper method: Batch delete only this specific task
  Future<void> _deleteOnlyThisTask(Task task, WriteBatch batch) async {
    final taskRef = _db.collection(collectionPath).doc(task.id);
    batch.delete(taskRef); // Add delete operation to the batch
    log('Added task ${task.title} to batch for deletion.');
  }

// Remove a subtask from a task
  Future<void> removeSubTask(String taskId, String subTaskId) async {
    try {
      final taskRef = _db.collection(collectionPath).doc(taskId);
      final subTasksRef = taskRef.collection('subtasks');

      // Delete the subtask document from the Firestore subtask collection
      await subTasksRef.doc(subTaskId).delete();
      print("Subtask removed successfully for Task ID: $taskId");
    } catch (e) {
      print("Error removing subtask: $e");
      rethrow; // Propagate the error
    }
  }

  // Update the status of a subtask
  Future<void> updateSubTaskStatus(
      String taskId, String subTaskId, SubtaskStatus status) async {
    try {
      final taskRef = _db.collection(collectionPath).doc(taskId);
      final subTaskRef = taskRef.collection('subtasks').doc(subTaskId);
      await subTaskRef.update({'status': status.toString().split('.').last});
      print("Subtask status updated successfully for Task ID: $taskId");
    } catch (e) {
      print("Error updating subtask status: $e");
      rethrow;
    }
  }

  // Stream to fetch real-time updates for SubTask items
  Stream<List<SubTaskItem>> getSubTaskItems(String taskId, String subTaskId) {
    return _db
        .collection('tasks')
        .doc(taskId)
        .collection('subtasks')
        .doc(subTaskId)
        .snapshots()
        .map((snapshot) {
      final subTaskData = snapshot.data();
      if (subTaskData != null && subTaskData['items'] != null) {
        final items = List<Map<String, dynamic>>.from(subTaskData['items']);
        return items.map((item) => SubTaskItem.fromMap(item)).toList();
      } else {
        return [];
      }
    });
  }

  // Add a subtask item to a subtask
  Future<void> addSubTaskItem(
      String taskId, String subTaskId, SubTaskItem item) async {
    try {
      final taskRef = _db.collection(collectionPath).doc(taskId);
      final subTaskRef = taskRef.collection('subtasks').doc(subTaskId);

      await subTaskRef.update({
        'items': FieldValue.arrayUnion([item.toMap()])
      });

      print("Subtask item added successfully for SubTask ID: $subTaskId");
    } catch (e) {
      print("Error adding subtask item: $e");
      rethrow;
    }
  }

  // Toggle the completion status of a subtask item
  Future<void> toggleSubTaskItemCompletion(
      String taskId, String subTaskId, String itemId) async {
    try {
      final taskRef = _db.collection(collectionPath).doc(taskId);
      final subTaskRef = taskRef.collection('subtasks').doc(subTaskId);
      final subTaskDoc = await subTaskRef.get();
      final subTaskData = subTaskDoc.data()!;
      final items = List<Map<String, dynamic>>.from(subTaskData['items']);
      final itemIndex = items.indexWhere((item) => item['id'] == itemId);

      if (itemIndex != -1) {
        final item = items[itemIndex];
        item['isCompleted'] = !item['isCompleted']; // Toggle completion status

        await subTaskRef.update({'items': items});
        print("Subtask item completion status toggled for Item ID: $itemId");
      }
    } catch (e) {
      print("Error toggling subtask item completion: $e");
      rethrow;
    }
  }

  // Remove a subtask item from a subtask
  Future<void> removeSubTaskItem(
      String taskId, String subTaskId, String itemId) async {
    try {
      final taskRef = _db.collection(collectionPath).doc(taskId);
      final subTaskRef = taskRef.collection('subtasks').doc(subTaskId);
      final subTaskDoc = await subTaskRef.get();
      final subTaskData = subTaskDoc.data()!;
      final items = List<Map<String, dynamic>>.from(subTaskData['items']);
      final itemIndex = items.indexWhere((item) => item['id'] == itemId);

      if (itemIndex != -1) {
        items.removeAt(itemIndex); // Remove the item
        await subTaskRef.update({'items': items});
        print("Subtask item removed successfully for Item ID: $itemId");
      }
    } catch (e) {
      print("Error removing subtask item: $e");
      rethrow;
    }
  }
}

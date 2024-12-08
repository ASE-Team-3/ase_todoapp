import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/models/task.dart';
import 'package:app/models/subtask.dart';
import 'package:app/models/subtask_item.dart';
import 'package:app/models/attachment.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer'; // For log function


class TaskFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String collectionPath = 'tasks';
  //final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch tasks for a specific project using projectId
  Stream<List<Task>> getTasksForProject(String projectId) {
    return _db
        .collection('tasks') // Replace with your Firestore collection name
        .where('projectId', isEqualTo: projectId) // Filter by project ID
        .snapshots()
        .map((snapshot) {
      // Convert Firestore data to a list of Task objects
      return snapshot.docs.map((doc) {
        return Task.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
  /// Fetch tasks for the currently logged-in user
  Stream<List<Task>> getTasksForUser() {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      log("User not logged in. Returning empty task stream.");
      return const Stream.empty();
    }

    log("Fetching tasks for user ID: $currentUserId");

    return _db
        .collection(collectionPath)
        .where('createdBy', isEqualTo: currentUserId) // Filter tasks created by user
        .snapshots()
        .map((snapshot) {
      // Debug: Log the raw snapshot
      log("Snapshot returned with ${snapshot.docs.length} documents");

      return snapshot.docs.map((doc) {
        log("Document ID: ${doc.id}, Data: ${doc.data()}");
        return Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
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

  // Get a task by its ID from Firestore
  Future<Task> getTaskById(String taskId) async {
    try {
      DocumentSnapshot taskSnapshot = await _db.collection(collectionPath).doc(taskId).get();
      if (taskSnapshot.exists) {
        return Task.fromMap(taskSnapshot.data() as Map<String, dynamic>, taskSnapshot.id);
      } else {
        throw Exception("Task not found");
      }
    } catch (e) {
      print("Error fetching task: $e");
      rethrow;
    }
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

  // Add a subtask to a task
  Future<void> addSubTask(String taskId, SubTask subTask) async {
    try {
      final taskRef = _db.collection(collectionPath).doc(taskId);
      final subTasksRef = taskRef.collection('subtasks');

      await subTasksRef.add(subTask.toMap());
      print("Subtask added successfully for Task ID: $taskId");
    } catch (e) {
      print("Error adding subtask: $e");
      rethrow;
    }
  }

  // Refresh the suggested paper for a task
  Future<void> refreshSuggestedPaper(String taskId) async {
    try {
      final taskRef = _db.collection(collectionPath).doc(taskId);
      final taskDoc = await taskRef.get();
      if (taskDoc.exists) {
        final taskData = taskDoc.data()!;
        final suggestedPaper = taskData['suggestedPaper'];
        final suggestedPaperUrl = taskData['suggestedPaperUrl'];

        // Simulate refreshing the suggested paper (e.g., by calling an API)
        print("Suggested paper refreshed: $suggestedPaperUrl");
      } else {
        print("Task not found while refreshing suggested paper.");
      }
    } catch (e) {
      print("Error refreshing suggested paper: $e");
      rethrow;
    }
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

        attachments.removeWhere((attachment) => attachment['id'] == attachmentId);

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

  // Method to delete repeating tasks
  Future<void> deleteRepeatingTasks(Task task, {required String option}) async {
    try {
      final taskRef = _db.collection(collectionPath).doc(task.id);

      if (option == "all") {
        // Delete all repeating tasks
        await taskRef.collection('repeatingTasks').get().then((querySnapshot) {
          for (var doc in querySnapshot.docs) {
            doc.reference.delete();
          }
        });
        print("All repeating tasks deleted for task ${task.id}");
      } else if (option == "this_and_following") {
        // Delete the current task and following repeating tasks
        await taskRef.collection('repeatingTasks').where('taskId', isEqualTo: task.id).get().then((querySnapshot) {
          for (var doc in querySnapshot.docs) {
            doc.reference.delete();
          }
        });
        print("Current and following repeating tasks deleted for task ${task.id}");
      } else if (option == "only_this") {
        // Delete only the current repeating task
        await taskRef.collection('repeatingTasks').doc(task.id).delete();
        print("Only the current repeating task deleted for task ${task.id}");
      }
    } catch (e) {
      print("Error deleting repeating tasks: $e");
      rethrow; // Propagate the error to be handled by the caller
    }
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
  Future<void> updateSubTaskStatus(String taskId, String subTaskId, SubtaskStatus status) async {
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

  // Add a subtask item to a subtask
  Future<void> addSubTaskItem(String taskId, String subTaskId, SubTaskItem item) async {
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
  Future<void> toggleSubTaskItemCompletion(String taskId, String subTaskId, String itemId) async {
    try {
      final taskRef = _db.collection(collectionPath).doc(taskId);
      final subTaskRef = taskRef.collection('subtasks').doc(subTaskId);
      final subTaskDoc = await subTaskRef.get();
      final subTaskData = subTaskDoc.data()!;
      final items = List<Map<String, dynamic>>.from(subTaskData['items']);
      final itemIndex = items.indexWhere((item) => item['id'] == itemId);

      if (itemIndex != -1) {
        final item = items[itemIndex];
        item['isCompleted'] = !item['isCompleted'];  // Toggle completion status

        await subTaskRef.update({'items': items});
        print("Subtask item completion status toggled for Item ID: $itemId");
      }
    } catch (e) {
      print("Error toggling subtask item completion: $e");
      rethrow;
    }
  }

  // Remove a subtask item from a subtask
  Future<void> removeSubTaskItem(String taskId, String subTaskId, String itemId) async {
    try {
      final taskRef = _db.collection(collectionPath).doc(taskId);
      final subTaskRef = taskRef.collection('subtasks').doc(subTaskId);
      final subTaskDoc = await subTaskRef.get();
      final subTaskData = subTaskDoc.data()!;
      final items = List<Map<String, dynamic>>.from(subTaskData['items']);
      final itemIndex = items.indexWhere((item) => item['id'] == itemId);

      if (itemIndex != -1) {
        items.removeAt(itemIndex);  // Remove the item
        await subTaskRef.update({'items': items});
        print("Subtask item removed successfully for Item ID: $itemId");
      }
    } catch (e) {
      print("Error removing subtask item: $e");
      rethrow;
    }
  }
}

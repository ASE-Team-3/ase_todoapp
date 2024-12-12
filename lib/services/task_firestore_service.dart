import 'dart:developer';

import 'package:app/helpers/task_helpers.dart';
import 'package:app/models/points_history.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/models/task.dart';
import 'package:app/models/subtask.dart';
import 'package:app/models/subtask_item.dart';
import 'package:app/models/attachment.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class TaskFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String collectionPath = 'tasks';
  final String pointsHistoryCollection = 'points_history';

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

  // Updated _generateRepeatingTasks to use batch writes and accept a limit parameter
  Future<void> generateRepeatingTasks(Task task, String? groupId,
      {DateTime? limit}) async {
    if (!task.isRepeating || task.repeatInterval == null) return;

    final WriteBatch batch =
        FirebaseFirestore.instance.batch(); // Create a batch
    final String collectionPath = 'tasks';

    final DateTime now = DateTime.now().toUtc();
    final DateTime defaultLimit =
        now.add(const Duration(days: 183)); // Default limit: ~6 months
    final DateTime generationLimit = limit ?? defaultLimit;

    DateTime? nextOccurrence = task.deadline ?? task.nextOccurrence;
    int tasksAdded = 0;

    while (nextOccurrence != null && nextOccurrence.isBefore(generationLimit)) {
      // Generate a unique ID for the new task
      final String newTaskId = const Uuid().v4();

      // Create a new task for each occurrence
      final newTask = task.copyWith(
        id: newTaskId,
        isCompleted: false, // Reset completion status
        deadline: nextOccurrence,
        repeatingGroupId: groupId, // Maintain consistent group ID
        nextOccurrence: null, // Only the original task has `nextOccurrence`
      );

      // Add the task to the batch
      final DocumentReference newTaskRef =
          FirebaseFirestore.instance.collection(collectionPath).doc(newTaskId);
      batch.set(newTaskRef, newTask.toMap());

      // Calculate the next occurrence
      nextOccurrence = calculateNextOccurrence(
        interval: task.repeatInterval,
        customDays: task.customRepeatDays,
        lastOccurrence: nextOccurrence,
      ).toUtc();

      tasksAdded++;
    }

    // Commit the batch operation
    if (tasksAdded > 0) {
      await batch.commit();
      log('Successfully added $tasksAdded repeating tasks for: ${task.title}');
    } else {
      log('No new tasks were generated for: ${task.title}');
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

  Future<void> updateRepeatingTasks(
    Task task, {
    required String option, // "all", "this_and_following", "only_this"
    required String title,
    required String description,
    DateTime? selectedDeadline, // New specific deadline
    String? flexibleDeadline, // New flexible deadline
    bool? isRepeating,
    String? repeatInterval,
    int? customRepeatDays,
    List<Attachment>? attachments,
    int? points,
    String? category, // Add category
    List<String>? keywords, // Add keywords
    String? alertFrequency,
    Map<String, dynamic>? customReminder,
    String? suggestedPaper,
    String? suggestedPaperAuthor,
    String? suggestedPaperPublishDate,
    String? suggestedPaperUrl,
  }) async {
    final WriteBatch batch = _db.batch();
    final String collectionPath = 'tasks';

    final groupId = task.repeatingGroupId;
    if (groupId == null) {
      log("Task does not have a repeatingGroupId");
      return;
    }

    final DateTime? utcSelectedDeadline = selectedDeadline?.toUtc();

    // "All" option: Update all tasks with the same groupId
    if (option == "all") {
      final querySnapshot = await _db
          .collection(collectionPath)
          .where('repeatingGroupId', isEqualTo: groupId)
          .get();

      for (var doc in querySnapshot.docs) {
        final taskRef = doc.reference;
        batch.update(taskRef, {
          'title': title,
          'description': description,
          'points': points,
          'category': category,
          'keywords': keywords,
          'attachments': attachments?.map((a) => a.toMap()).toList(),
          'deadline': utcSelectedDeadline ??
              calculateNextOccurrence(
                interval: repeatInterval ?? task.repeatInterval,
                customDays: customRepeatDays ?? task.customRepeatDays,
                lastOccurrence: (doc['deadline'] as Timestamp).toDate(),
              ),
          'repeatInterval': repeatInterval ?? task.repeatInterval,
          'customRepeatDays': customRepeatDays,
          'flexibleDeadline': flexibleDeadline,
          'alertFrequency': alertFrequency,
          'customReminder': customReminder,
          'suggestedPaper': suggestedPaper,
          'suggestedPaperAuthor': suggestedPaperAuthor,
          'suggestedPaperPublishDate': suggestedPaperPublishDate,
          'suggestedPaperUrl': suggestedPaperUrl,
        });
      }
    }
    // "This and following" option: Update current and subsequent tasks
    else if (option == "this_and_following") {
      final querySnapshot = await _db
          .collection(collectionPath)
          .where('repeatingGroupId', isEqualTo: groupId)
          .where('deadline', isGreaterThanOrEqualTo: task.deadline)
          .get();

      for (var doc in querySnapshot.docs) {
        final taskRef = doc.reference;
        batch.update(taskRef, {
          'title': title,
          'description': description,
          'points': points,
          'category': category,
          'keywords': keywords,
          'attachments': attachments?.map((a) => a.toMap()).toList(),
          'deadline': calculateNextOccurrence(
            interval: repeatInterval ?? task.repeatInterval,
            customDays: customRepeatDays ?? task.customRepeatDays,
            lastOccurrence: (doc['deadline'] as Timestamp).toDate(),
          ),
          'repeatInterval': repeatInterval ?? task.repeatInterval,
          'customRepeatDays': customRepeatDays,
          'flexibleDeadline': flexibleDeadline,
          'alertFrequency': alertFrequency,
          'customReminder': customReminder,
          'suggestedPaper': suggestedPaper,
          'suggestedPaperAuthor': suggestedPaperAuthor,
          'suggestedPaperPublishDate': suggestedPaperPublishDate,
          'suggestedPaperUrl': suggestedPaperUrl,
        });
      }
    }
    // "Only this" option: Update only the current task
    else if (option == "only_this") {
      final taskRef = _db.collection(collectionPath).doc(task.id);
      batch.update(taskRef, {
        'title': title,
        'description': description,
        'points': points,
        'category': category,
        'keywords': keywords,
        'attachments': attachments?.map((a) => a.toMap()).toList(),
        'deadline': utcSelectedDeadline ?? task.deadline,
        'repeatInterval': repeatInterval ?? task.repeatInterval,
        'customRepeatDays': customRepeatDays,
        'flexibleDeadline': flexibleDeadline,
        'alertFrequency': alertFrequency,
        'customReminder': customReminder,
        'suggestedPaper': suggestedPaper,
        'suggestedPaperAuthor': suggestedPaperAuthor,
        'suggestedPaperPublishDate': suggestedPaperPublishDate,
        'suggestedPaperUrl': suggestedPaperUrl,
      });
    }

    // Commit the batch operation
    await batch.commit();
    log("Successfully updated repeating tasks with option: $option");
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

  /// Toggle Task Completion: Ensures rules for subtasks/items are followed.
  Future<void> toggleTaskCompletion(Task task) async {
    final taskRef = _db.collection('tasks').doc(task.id);
    final subTasksRef = taskRef.collection('subtasks');

    try {
      // Step 1: Check if task has subtasks
      final subTasksSnapshot = await subTasksRef.get();
      final hasSubTasks = subTasksSnapshot.docs.isNotEmpty;

      bool canMarkCompleted = true;

      if (hasSubTasks) {
        // Step 2: Check if all subtasks are completed
        for (var subDoc in subTasksSnapshot.docs) {
          final subTask = SubTask.fromMap(subDoc.data());

          // If subtask has items, ensure all items are completed
          if (subTask.items.isNotEmpty) {
            final allItemsCompleted =
                subTask.items.every((item) => item.isCompleted);

            if (!allItemsCompleted) {
              canMarkCompleted = false;
              break; // Stop checking, subtask items are incomplete
            }
          }

          // If subtask itself is incomplete
          if (!subTask.isCompleted) {
            canMarkCompleted = false;
            break; // Stop checking, subtask incomplete
          }
        }
      }

      if (canMarkCompleted) {
        // Step 3: Toggle Task Completion
        final isNowCompleted = !task.isCompleted;

        // Step 4: Update task status in Firestore
        await taskRef.update({'isCompleted': isNowCompleted});

        // Step 5: Record Points History
        if (isNowCompleted) {
          await _addPointsHistory(task, task.points,
              reason: 'Task "${task.title}" completed');
          print('Task "${task.title}" marked as completed.');
        } else {
          await _addPointsHistory(task, -task.points,
              reason: 'Task "${task.title}" marked as incomplete');
          print('Task "${task.title}" marked as incomplete.');
        }
      } else {
        print(
            'Cannot mark task "${task.title}" as completed. Subtasks/items are incomplete.');
        throw Exception(
            'Task cannot be marked as completed. Complete all subtasks and their items first.');
      }
    } catch (e) {
      print('Error toggling task completion for "${task.title}": $e');
      rethrow;
    }
  }

  /// Toggle Subtask Completion: Ensures items rules are followed.
  /// If all subtasks of a task are completed, the task itself is marked as completed.
  Future<void> toggleSubTaskCompletion(String taskId, SubTask subTask) async {
    final taskRef = _db.collection('tasks').doc(taskId);
    final subTaskRef = taskRef.collection('subtasks').doc(subTask.id);

    try {
      // Step 1: Check if subtask has items
      final hasItems = subTask.items.isNotEmpty;
      bool canMarkCompleted = true;

      if (hasItems) {
        // Step 2: Ensure all items are marked as completed
        for (var item in subTask.items) {
          if (!item.isCompleted) {
            canMarkCompleted = false;
            break; // Stop checking, item incomplete
          }
        }
      }

      if (canMarkCompleted) {
        // Step 3: Log before updating subtask status
        print(
            'Attempting to update subtask: ${subTask.title} - Task ID: $taskId');
        final isNowCompleted = !subTask.isCompleted;

        // Step 4: Update the subtask status in Firestore
        await subTaskRef
            .update({'isCompleted': isNowCompleted}).catchError((e) {
          print('Error updating subtask status: $e');
          throw e; // Rethrow error for logging
        });
        print('Subtask "${subTask.title}" status updated to: $isNowCompleted');

        // Step 5: Fetch all subtasks to verify completion
        print('Fetching all subtasks for Task ID: $taskId');
        final subTasksSnapshot = await taskRef.collection('subtasks').get();

        for (var doc in subTasksSnapshot.docs) {
          final subTaskData = doc.data();
          print(
              'Subtask ID: ${doc.id}, Title: ${subTaskData['title']}, isCompleted: ${subTaskData['isCompleted']}');
        }

        // Step 6: Check if all subtasks are completed
        final allSubTasksCompleted = subTasksSnapshot.docs.every((doc) {
          final subTaskData = doc.data();
          return subTaskData['isCompleted'] == true;
        });

        // Step 7: Update the parent task's completion status if applicable
        if (allSubTasksCompleted) {
          await taskRef.update({'isCompleted': true});
          print('All subtasks are completed. Task marked as completed.');
        } else {
          await taskRef.update({'isCompleted': false});
          print('Some subtasks are incomplete. Task remains incomplete.');
        }
      } else {
        print(
            'Cannot mark subtask as completed. Some items are still incomplete.');
        throw Exception(
            'Subtask cannot be marked as completed. Complete all items first.');
      }
    } catch (e) {
      print('Error toggling subtask completion: $e');
      rethrow;
    }
  }

  /// Helper Method: Adds points history record
  Future<void> _addPointsHistory(Task task, int points,
      {required String reason}) async {
    try {
      final pointsHistoryRef = _db.collection('points_history').doc();
      await pointsHistoryRef.set({
        'taskId': task.id,
        'action': points > 0 ? 'Awarded' : 'Deducted',
        'points': points.abs(),
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error recording points history: $e');
      rethrow;
    }
  }

  /// Fetch points history from Firestore
  Stream<List<PointsHistory>> getPointsHistory() {
    return _db
        .collection(pointsHistoryCollection)
        .orderBy('timestamp', descending: true) // Order by latest
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return PointsHistory.fromMap(doc.data());
            }).toList());
  }

  Stream<int> getTotalPoints() {
    return FirebaseFirestore.instance
        .collection(
            pointsHistoryCollection) // Replace with the actual collection path
        .snapshots()
        .map((snapshot) {
      int totalPoints = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Ensure safe access to 'action' and 'points'
        final action =
            data['action']?.toString() ?? ''; // Default to empty string
        final points = data['points'] is int ? data['points'] as int : 0;

        // Accumulate points based on the action
        if (action == 'Awarded') {
          totalPoints += points;
        } else if (action == 'Deducted') {
          totalPoints -= points;
        }
      }

      return totalPoints;
    });
  }

  /// Deduct points for tasks not completed before their deadline
  Future<void> deductPointsForOverdueTasks() async {
    try {
      final now = DateTime.now();
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        log("No logged-in user. Cannot process overdue tasks.");
        return;
      }

      final userId = currentUser.uid;

      // Fetch tasks where deadline has passed, is not completed,
      // and either createdBy or assignedTo matches the current user
      final querySnapshot = await _db
          .collection(collectionPath)
          .where('isCompleted', isEqualTo: false)
          .where('deadline', isLessThan: now)
          .where(Filter.or(
            Filter('createdBy', isEqualTo: userId),
            Filter('assignedTo', isEqualTo: userId),
          ))
          .get();

      WriteBatch batch = _db.batch();

      for (var doc in querySnapshot.docs) {
        final task = doc.data();
        final int points = task['points'] ?? 0;

        if (points > 0) {
          final taskId = doc.id;
          final taskTitle = task['title'] ?? 'Unnamed Task';

          // Check if this task already has a deduction in points history
          final existingDeduction = await _db
              .collection(pointsHistoryCollection)
              .where('taskId', isEqualTo: taskId)
              .where('action', isEqualTo: 'Deducted')
              .get();

          if (existingDeduction.docs.isNotEmpty) {
            log('Points already deducted for task "$taskTitle". Skipping.');
            continue; // Skip tasks that already have deductions
          }

          log('Deducting $points points for overdue task: $taskTitle');

          // Update task status (optional: flag as overdue)
          batch.update(doc.reference, {'isOverdue': true});

          // Record points deduction in points history
          final pointsHistoryRef =
              _db.collection(pointsHistoryCollection).doc();
          batch.set(pointsHistoryRef, {
            'action': 'Deducted',
            'points': points,
            'reason': 'Task "$taskTitle" not completed before deadline',
            'timestamp': FieldValue.serverTimestamp(),
            'taskId': taskId,
            'userId': userId,
          });
        }
      }

      // Commit batch if there are any updates
      if (querySnapshot.docs.isNotEmpty) {
        await batch.commit();
        log("Overdue tasks processed and points deducted successfully.");
      } else {
        log("No overdue tasks found for user $userId.");
      }
    } catch (e) {
      log("Error deducting points for overdue tasks: $e");
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

  /// Toggle the completion status of a subtask item
  Future<void> toggleSubTaskItemCompletion(
      String taskId, String subTaskId, String itemId) async {
    try {
      final taskRef = _db.collection(collectionPath).doc(taskId);
      final subTaskRef = taskRef.collection('subtasks').doc(subTaskId);

      // Step 1: Fetch the current subtask data
      final subTaskDoc = await subTaskRef.get();
      if (!subTaskDoc.exists) {
        throw Exception("Subtask not found");
      }

      final subTaskData = subTaskDoc.data()!;
      final items = List<Map<String, dynamic>>.from(subTaskData['items']);
      final itemIndex = items.indexWhere((item) => item['id'] == itemId);

      if (itemIndex == -1) {
        throw Exception("Item not found in subtask");
      }

      // Step 2: Toggle the item's completion status
      final item = items[itemIndex];
      item['isCompleted'] = !(item['isCompleted'] ?? false);
      items[itemIndex] = item;

      // Step 3: Check if all items are completed
      final allItemsCompleted =
          items.every((element) => element['isCompleted'] == true);

      // Step 4: Update the subtask's completion status
      final isSubTaskCompleted = allItemsCompleted;

      await subTaskRef.update({
        'items': items,
        'isCompleted': isSubTaskCompleted,
      });

      print(
          "Subtask item completion status toggled for Item ID: $itemId. Subtask completion status: $isSubTaskCompleted");

      // Step 5: Check if all subtasks under the task are completed
      if (isSubTaskCompleted) {
        final subTasksSnapshot =
            await taskRef.collection('subtasks').get(); // Fetch all subtasks
        final allSubTasksCompleted = subTasksSnapshot.docs.every((subDoc) {
          final subData = subDoc.data();
          return subData['isCompleted'] == true;
        });

        if (allSubTasksCompleted) {
          await taskRef.update({'isCompleted': true});
          print("All subtasks are completed. Task marked as completed.");
        }
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

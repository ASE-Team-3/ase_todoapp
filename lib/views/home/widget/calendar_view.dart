// views/home/widget/calendar_view.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:app/models/task.dart';
import 'package:app/views/tasks/task_detail_view.dart';

class CalendarView extends StatefulWidget {
  final List<Task> tasks;

  CalendarView({required this.tasks});

  @override
  _CalendarViewState createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<Task> get _tasksForSelectedDay {
    return widget.tasks
        .where((task) => isSameDay(task.deadline, _selectedDay))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 10, 16),
          lastDay: DateTime.utc(2030, 3, 14),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          eventLoader: (day) => widget.tasks
              .where((task) => isSameDay(task.deadline, day))
              .toList(),
          calendarStyle: CalendarStyle(
            markerDecoration: BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _tasksForSelectedDay.isNotEmpty
              ? ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _tasksForSelectedDay.length,
                  itemBuilder: (context, index) {
                    final task = _tasksForSelectedDay[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                TaskDetailView(taskId: task.id),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: task.isCompleted
                                ? Colors.green
                                : Theme.of(context).primaryColor,
                            child: Icon(
                              task.isCompleted ? Icons.check : Icons.event_note,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            task.title,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                          ),
                          subtitle: Text(
                            "Due: ${_formatDate(task.deadline!)}",
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                          ),
                          trailing: task.isCompleted
                              ? Icon(Icons.check_circle, color: Colors.green)
                              : null,
                        ),
                      ),
                    );
                  },
                )
              : Center(
                  child: Text(
                    "No tasks for the selected day",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}

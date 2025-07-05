import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hydrogoal/services/firestore_service.dart';
import 'package:hydrogoal/utils/colors.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String _userId = FirebaseAuth.instance.currentUser!.uid;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hydration History',
            style: TextStyle(
                color: AppColors.darkText,
                fontWeight: FontWeight.bold,
                fontSize: 28)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _firestoreService.getHydrationHistoryForMonth(_userId, _focusedDay),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = _getEventsFromSnapshot(snapshot.data!);
          final averageIntake = _calculateAverage(events);

          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: CalendarFormat.month,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
                headerStyle: const HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isNotEmpty) {
                      return Positioned(
                        bottom: 1,
                        child: Text(
                          '${events.first}ml', // Display the intake amount
                          style: TextStyle(
                            color: AppColors.primaryBlue.withOpacity(0.8),
                            fontSize: 10,
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
                eventLoader: (day) {
                  // The event loader uses the amount as the event
                  final dayWithoutTime =
                      DateTime.utc(day.year, day.month, day.day);
                  return events[dayWithoutTime] != null
                      ? [events[dayWithoutTime]]
                      : [];
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Average for ${DateFormat.yMMMM().format(_focusedDay)}',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText),
              ),
              Text(
                '${averageIntake.toStringAsFixed(0)} ml / day',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue),
              ),
              const Spacer(),
            ],
          );
        },
      ),
    );
  }

  Map<DateTime, int> _getEventsFromSnapshot(QuerySnapshot snapshot) {
    final Map<DateTime, int> events = {};
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      final amount = data['amount'] as int;
      // Normalize the date to midnight UTC to avoid time zone issues
      final dayWithoutTime = DateTime.utc(date.year, date.month, date.day);
      events[dayWithoutTime] = amount;
    }
    return events;
  }

  double _calculateAverage(Map<DateTime, int> events) {
    if (events.isEmpty) return 0;
    final totalIntake = events.values.reduce((sum, item) => sum + item);
    return totalIntake / events.length;
  }
}

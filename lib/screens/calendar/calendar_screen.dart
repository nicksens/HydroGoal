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
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

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
      body: _userId == null
          ? const Center(child: Text('Please log in to see your history.'))
          : StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getHydrationHistoryForMonth(
                  _userId!, _focusedDay),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Get daily totals for the calendar markers
                final dailyTotals = _getDailyTotalsFromSnapshot(snapshot.data);

                return Column(
                  children: [
                    _buildThemedCalendar(dailyTotals),
                    const SizedBox(height: 16),
                    // NEW: Themed card to display monthly stats
                    _buildMonthlyStatsCard(dailyTotals),
                    const Divider(height: 32, indent: 16, endIndent: 16),
                    // List of logs for the selected day
                    Expanded(child: _buildDailyLogList()),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildThemedCalendar(Map<DateTime, int> dailyTotals) {
    return Card(
      elevation: 2,
      shadowColor: AppColors.primaryBlue.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.now().add(const Duration(days: 365)),
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
          titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        calendarStyle: const CalendarStyle(
          selectedDecoration: BoxDecoration(
              color: AppColors.primaryBlue, shape: BoxShape.circle),
          todayDecoration:
              BoxDecoration(color: AppColors.lightBlue, shape: BoxShape.circle),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isNotEmpty) {
              return Positioned(
                right: 5,
                bottom: 5,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: AppColors.accentAqua, shape: BoxShape.circle),
                ),
              );
            }
            return null;
          },
        ),
        eventLoader: (day) {
          final dayWithoutTime = DateTime.utc(day.year, day.month, day.day);
          return dailyTotals[dayWithoutTime] != null
              ? [dailyTotals[dayWithoutTime]]
              : [];
        },
      ),
    );
  }

  // NEW: A separate card for displaying the monthly stats
  Widget _buildMonthlyStatsCard(Map<DateTime, int> dailyTotals) {
    if (dailyTotals.isEmpty)
      return const SizedBox.shrink(); // Don't show if there's no data

    final totalIntake = dailyTotals.values.reduce((sum, item) => sum + item);
    final daysTracked = dailyTotals.length;
    final averageIntake = totalIntake / daysTracked;

    return Card(
      elevation: 2,
      shadowColor: AppColors.primaryBlue.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatColumn('Total Intake', '${totalIntake} ml'),
            _buildStatColumn('Days Tracked', daysTracked.toString()),
            _buildStatColumn(
                'Avg. Intake', '${averageIntake.toStringAsFixed(0)} ml'),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyLogList() {
    if (_selectedDay == null) {
      return const Center(child: Text('Select a day to see your logs.'));
    }
    return Column(
      children: [
        Text(
          'Logs for ${DateFormat.yMMMd().format(_selectedDay!)}',
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.lightText),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.getLogsForDay(_userId!, _selectedDay!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                    child: Text('No water logged on this day.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final amount = data['amount'] as int;
                  final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                  return Card(
                    elevation: 1,
                    shadowColor: AppColors.lightBlue,
                    child: ListTile(
                      leading: const Icon(Icons.water_drop,
                          color: AppColors.primaryBlue),
                      title: Text('+ $amount ml',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(timestamp != null
                          ? DateFormat.jm().format(timestamp)
                          : 'Time not available'),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Helper Widgets and Logic ---
  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.lightText, fontSize: 16)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: AppColors.darkText,
                fontSize: 20,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Map<DateTime, int> _getDailyTotalsFromSnapshot(QuerySnapshot? snapshot) {
    final Map<DateTime, int> events = {};
    if (snapshot == null) return events;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      final amount = data['amount'] as int;
      final dayWithoutTime = DateTime.utc(date.year, date.month, date.day);
      events[dayWithoutTime] = amount;
    }
    return events;
  }
}

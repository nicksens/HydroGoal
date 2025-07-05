import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hydrogoal/services/firestore_service.dart';
import 'package:hydrogoal/utils/colors.dart';
import 'package:hydrogoal/widgets/wave_clipper.dart';
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
        stream: _userId != null
            ? _firestoreService.getHydrationHistoryForMonth(
                _userId!, _focusedDay)
            : null,
        builder: (context, snapshot) {
          if (_userId == null) {
            return const Center(child: Text('Not logged in.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            // Handle case with no data for the month
            return _buildCalendarWithNoData();
          }

          final events = _getEventsFromSnapshot(snapshot.data!);
          final averageIntake = _calculateAverage(events);

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildThemedCalendar(events),
                const SizedBox(height: 24),
                _buildAverageCard(averageIntake),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Helper to build the calendar when there's no data ---
  Widget _buildCalendarWithNoData() {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          onPageChanged: (focusedDay) =>
              setState(() => _focusedDay = focusedDay),
          headerStyle: _headerStyle(),
          calendarStyle: _calendarStyle(),
        ),
        const SizedBox(height: 24),
        _buildAverageCard(0),
      ],
    );
  }

  // --- Main Calendar Widget ---
  Widget _buildThemedCalendar(Map<DateTime, int> events) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: CalendarFormat.month,
      eventLoader: (day) =>
          events[DateTime.utc(day.year, day.month, day.day)] != null
              ? [events[DateTime.utc(day.year, day.month, day.day)]]
              : [],
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) => setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      }),
      onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
      headerStyle: _headerStyle(),
      calendarStyle: _calendarStyle(),
      calendarBuilders: CalendarBuilders(
        // Custom builder to highlight days with intake
        defaultBuilder: (context, day, focusedDay) {
          final dayEvent = events[DateTime.utc(day.year, day.month, day.day)];
          if (dayEvent != null) {
            return Container(
              margin: const EdgeInsets.all(4.0),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.lightBlue,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${day.day}',
                style: const TextStyle(color: AppColors.primaryBlue),
              ),
            );
          }
          return null;
        },
        // Custom builder for today's date
        todayBuilder: (context, day, focusedDay) {
          return Container(
            margin: const EdgeInsets.all(4.0),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.accentAqua,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${day.day}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  // --- A separate card for displaying the average intake ---
  Widget _buildAverageCard(double averageIntake) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      elevation: 2,
      shadowColor: AppColors.primaryBlue.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Average for ${DateFormat.yMMMM().format(_focusedDay)}',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightText),
            ),
            const SizedBox(height: 8),
            Text(
              '${averageIntake.toStringAsFixed(0)} ml / day',
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue),
            ),
          ],
        ),
      ),
    );
  }

  // --- Styling Objects for the Calendar ---
  HeaderStyle _headerStyle() {
    return HeaderStyle(
      titleCentered: true,
      formatButtonVisible: false,
      titleTextStyle: GoogleFonts.poppins(
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
          color: AppColors.darkText),
      leftChevronIcon:
          const Icon(Icons.chevron_left, color: AppColors.primaryBlue),
      rightChevronIcon:
          const Icon(Icons.chevron_right, color: AppColors.primaryBlue),
    );
  }

  CalendarStyle _calendarStyle() {
    return CalendarStyle(
      defaultTextStyle: GoogleFonts.poppins(color: AppColors.darkText),
      weekendTextStyle: GoogleFonts.poppins(color: AppColors.primaryBlue),
      outsideTextStyle:
          GoogleFonts.poppins(color: AppColors.lightText.withOpacity(0.5)),
    );
  }

  // --- Data Processing Logic (Unchanged) ---
  Map<DateTime, int> _getEventsFromSnapshot(QuerySnapshot snapshot) {
    final Map<DateTime, int> events = {};
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      final amount = data['amount'] as int;
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

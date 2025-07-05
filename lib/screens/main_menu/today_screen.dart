import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydrogoal/screens/auth/auth_wrapper.dart';
import 'package:hydrogoal/screens/hydration/hydration_proof_screen.dart';
import 'package:hydrogoal/services/firebase_auth_service.dart';
import 'package:hydrogoal/services/firestore_service.dart';
import 'package:hydrogoal/services/notification_service.dart';
import 'package:hydrogoal/utils/colors.dart';
import 'package:hydrogoal/widgets/wave_clipper.dart'; // <-- Import the new clipper
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  int _goal = 2000;
  int _currentIntake = 0;
  int _reminderInterval = 60;
  bool _remindersActive = false;

  final NotificationService _notificationService = NotificationService();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _goalInputController = TextEditingController();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadData();
    _notificationService.initialize();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _goal = prefs.getInt('goal') ?? 2000;
    _reminderInterval = prefs.getInt('reminderInterval') ?? 60;
    _remindersActive = prefs.getBool('remindersActive') ?? false;

    if (_userId != null) {
      final todayIntake = await _firestoreService.getTodaysIntake(_userId!);
      if (mounted) {
        setState(() {
          _currentIntake = todayIntake;
        });
      }
    } else {
      if (mounted) setState(() {});
    }
  }

  Future<void> _updateGoal(int newGoal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('goal', newGoal);
    setState(() => _goal = newGoal);
  }

  Future<void> _updateReminderSettings(int interval, bool isActive) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminderInterval', interval);
    await prefs.setBool('remindersActive', isActive);
    setState(() {
      _reminderInterval = interval;
      _remindersActive = isActive;
    });
  }

  void _showGoalSettingsDialog() {
    _goalInputController.text = _goal.toString();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Daily Goal'),
        content: TextFormField(
          controller: _goalInputController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Goal (ml)'),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        actions: [
          TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop()),
          ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                final newGoal =
                    int.tryParse(_goalInputController.text) ?? _goal;
                _updateGoal(newGoal);
                Navigator.of(ctx).pop();
              }),
        ],
      ),
    );
  }

  void _showReminderSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        int tempInterval = _reminderInterval;
        bool tempRemindersActive = _remindersActive;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reminder Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: tempInterval,
                    items: const [
                      DropdownMenuItem(value: 30, child: Text('30 minutes')),
                      DropdownMenuItem(value: 60, child: Text('1 hour')),
                      DropdownMenuItem(value: 90, child: Text('1.5 hours')),
                      DropdownMenuItem(value: 120, child: Text('2 hours')),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => tempInterval = value ?? 60),
                    decoration: const InputDecoration(labelText: 'Interval'),
                  ),
                  SwitchListTile(
                    title: const Text('Enable Reminders'),
                    value: tempRemindersActive,
                    onChanged: (value) =>
                        setDialogState(() => tempRemindersActive = value),
                    activeColor: AppColors.primaryBlue,
                  ),
                ],
              ),
              actions: [
                TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(ctx).pop()),
                ElevatedButton(
                    child: const Text('Save'),
                    onPressed: () {
                      _toggleReminders(tempInterval, tempRemindersActive);
                      Navigator.of(ctx).pop();
                    }),
              ],
            );
          },
        );
      },
    );
  }

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.flag_outlined, color: AppColors.primaryBlue),
              title: const Text('Set Daily Goal'),
              onTap: () {
                Navigator.of(ctx).pop();
                _showGoalSettingsDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined,
                  color: AppColors.primaryBlue),
              title: const Text('Reminder Settings'),
              onTap: () {
                Navigator.of(ctx).pop();
                _showReminderSettingsDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleReminders(int interval, bool start) async {
    if (start) {
      await _notificationService.scheduleRepeatingNotification(
          intervalMinutes: interval,
          title: '💧 Time to Hydrate!',
          body: "Don't forget to drink water and log your progress!");
    } else {
      await _notificationService.cancelAllNotifications();
    }
    await _updateReminderSettings(interval, start);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Reminders ${start ? 'updated and on' : 'are off'}.')),
      );
    }
  }

  Future<void> _logWaterWithProof() async {
    if (_userId == null) return;
    final amount = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (context) => const HydrationProofScreen()),
    );
    if (amount != null && amount > 0) {
      await _firestoreService.logWaterIntake(_userId!, amount);
      setState(() {
        _currentIntake += amount;
      });
    }
  }

  @override
  void dispose() {
    _goalInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = FirebaseAuthService();
    final double percent = _goal > 0 ? (_currentIntake / _goal) : 0;
    final int remaining =
        _goal - _currentIntake > 0 ? _goal - _currentIntake : 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Today',
            style: TextStyle(
                color: AppColors.darkText,
                fontWeight: FontWeight.bold,
                fontSize: 28)),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.settings_outlined, color: AppColors.darkText),
            onPressed: _showSettingsBottomSheet,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.darkText),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted)
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const AuthWrapper()),
                    (r) => false);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          ClipPath(
            clipper: WaveClipper(),
            child: Container(
              height: 250,
              color: AppColors.lightBlue.withOpacity(0.3),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                CircularPercentIndicator(
                  radius: 125.0,
                  lineWidth: 24.0,
                  percent: percent > 1.0 ? 1.0 : percent,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.water_drop,
                          size: 40, color: AppColors.primaryBlue),
                      const SizedBox(height: 8),
                      Text('${_currentIntake}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 48,
                              color: AppColors.darkText)),
                      Text('/ ${_goal} ml',
                          style: const TextStyle(
                              fontSize: 16, color: AppColors.lightText)),
                    ],
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                  progressColor: AppColors.primaryBlue,
                  animation: true,
                ),
                const Spacer(flex: 3),
                Card(
                  elevation: 2,
                  shadowColor: AppColors.primaryBlue.withOpacity(0.2),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn('Current', '${_currentIntake} ml'),
                        _buildStatColumn('Goal', '${_goal} ml'),
                        _buildStatColumn('Remaining', '${remaining} ml'),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _logWaterWithProof,
        icon: const Icon(Icons.camera_alt_outlined),
        label: const Text('Add Proof'),
        backgroundColor: AppColors.primaryBlue,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
}

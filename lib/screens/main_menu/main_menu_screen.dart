import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydrogoal/screens/auth/auth_wrapper.dart';
import 'package:hydrogoal/screens/hydration/hydration_proof_screen.dart'; // Import the new screen
import 'package:hydrogoal/services/firebase_auth_service.dart';
import 'package:hydrogoal/services/notification_service.dart';
import 'package:hydrogoal/utils/colors.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

// You can move this clipper to its own file in `lib/widgets` to avoid repetition
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 50);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);
    var secondControlPoint = Offset(size.width * 3 / 4, size.height - 100);
    var secondEndPoint = Offset(size.width, size.height - 50);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  // --- State Variables ---
  int _goal = 2000;
  int _currentIntake = 0;
  int _reminderInterval = 60;
  bool _remindersActive = false;

  final NotificationService _notificationService = NotificationService();
  final TextEditingController _goalInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _notificationService.initialize();
  }

  // --- Data Persistence ---
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _goal = prefs.getInt('goal') ?? 2000;
      _currentIntake = prefs.getInt('intake') ?? 0;
      _reminderInterval = prefs.getInt('reminderInterval') ?? 60;
      _remindersActive = prefs.getBool('remindersActive') ?? false;
    });
  }

  Future<void> _saveIntake() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('intake', _currentIntake);
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

  // --- Dialogs and Bottom Sheets ---

  // This function is now called from the settings bottom sheet
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

  // This function is also called from the settings bottom sheet
  void _showReminderSettingsDialog() {
    // Using a StatefulBuilder to manage the dialog's internal state
    showDialog(
      context: context,
      builder: (ctx) {
        // Temporary variables to hold changes within the dialog
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

  // --- Main Actions ---

  // Updated toggle reminders logic
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

  // This function now launches the HydrationProofScreen and waits for a result
  Future<void> _logWaterWithProof() async {
    final amount = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (context) => const HydrationProofScreen()),
    );

    if (amount != null && amount > 0) {
      setState(() {
        _currentIntake += amount;
      });
      _saveIntake();
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
                        _buildStatColumn('Remaining',
                            '${_goal - _currentIntake > 0 ? _goal - _currentIntake : 0} ml'),
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
        onPressed: _logWaterWithProof, // Updated to call the new function
        icon: const Icon(Icons.camera_alt_outlined),
        label: const Text('Start Hydrating'),
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

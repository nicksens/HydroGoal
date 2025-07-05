import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydrogoal/models/bottle_model.dart';
import 'package:hydrogoal/screens/hydration/hydration_proof_screen.dart';
import 'package:hydrogoal/screens/inventory/bottle_inventory_screen.dart';
import 'package:hydrogoal/screens/profile/profile_screen.dart';
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

  Bottle? _selectedBottle;

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
                      DropdownMenuItem(value: 1, child: Text('1 minute')),
                      DropdownMenuItem(value: 5, child: Text('5 minutes')),
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
                // vvvvvv THE CHANGES ARE HERE vvvvvv
                onPressed: () async { // 1. Make the function async
                  // 2. Request permissions first
                  final bool permissionsGranted =
                      await _notificationService.requestPermissions();

                  // 3. Check if the user granted permissions
                  if (permissionsGranted) {
                    // If yes, schedule the notifications and close the dialog
                      _toggleReminders(tempInterval, tempRemindersActive);
                    if (mounted) Navigator.of(ctx).pop();
                  } else {
                    // If no, show a message and don't close the dialog
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Permissions are required to set reminders.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                },
                // ^^^^^^ END OF CHANGES ^^^^^^
              ),
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
      final bool hasPermission =
          await _notificationService.requestPermissions();
      if (!hasPermission && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Permissions are required to set reminders.')),
        );
        return; // Stop if permissions are not granted
      }

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
    if (_selectedBottle == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a bottle first.'),
        backgroundColor: Colors.orangeAccent,
      ));
      return;
    }

    final amount = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (context) => HydrationProofScreen(
          totalBottleCapacity: _selectedBottle!.capacity,
        ),
      ),
    );

    if (_userId != null && amount != null && amount > 0) {
      await _firestoreService.logWaterIntake(_userId!, amount);
      _loadData(); // Reload data to update the UI
    }
  }

  @override
  void dispose() {
    _goalInputController.dispose();
    super.dispose();
  }

  // In lib/screens/main_menu/today_screen.dart

  @override
  Widget build(BuildContext context) {
    // This part remains the same
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
            icon: const Icon(Icons.account_circle_outlined,
                color: AppColors.darkText),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      // The FloatingActionButton is removed, as requested.
      body: SingleChildScrollView(
        // <-- FIX for the overflow error
        child: Stack(
          children: [
            ClipPath(
              clipper: WaveClipper(),
              child: Container(
                height: 250,
                color: AppColors.lightBlue.withOpacity(0.3),
              ),
            ),
            // We use Padding to ensure content isn't under the phone's status bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                children: [
                  // We use SizedBox for predictable spacing instead of Spacers
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 40),

                  // 1. The Stats Card
                  Card(
                    elevation: 2,
                    shadowColor: AppColors.primaryBlue.withOpacity(0.2),
                    // The Card's margin is now handled by the parent Padding
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
                  const SizedBox(height: 24),

                  // 2. The Bottle Selector (caravan)
                  _buildBottleSelector(),

                  const SizedBox(height: 24),

                  // 3. The "Add Proof" button with natural size
                  ElevatedButton.icon(
                    onPressed: _logWaterWithProof,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Add Proof'),
                    style: ElevatedButton.styleFrom(
                        // You can adjust padding to make it look just right
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                  const SizedBox(height: 40), // Extra space at the bottom
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottleSelector() {
    if (_userId == null) return const SizedBox.shrink();

    // The main Column now has padding to match the Card's margin
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const BottleInventoryScreen())),
            child: const Text('Manage My Bottles'),
          ),
          const SizedBox(height: 8),

          // This SizedBox constrains the height of the scrollable area
          SizedBox(
            height: 80,
            child: StreamBuilder<List<Bottle>>(
              stream: _firestoreService.getBottles(_userId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) =>
                                  const BottleInventoryScreen())),
                      child: const Text('Add Your First Bottle'),
                    ),
                  );
                }
                final bottles = snapshot.data!;

                if (_selectedBottle == null ||
                    !bottles.contains(_selectedBottle)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _selectedBottle = bottles.first;
                      });
                    }
                  });
                }

                // We use a SingleChildScrollView with a Row to achieve centering
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  // The Row's properties allow for centering
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: bottles.map((bottle) {
                      final isSelected = bottle.id == _selectedBottle?.id;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedBottle = bottle;
                          });
                        },
                        child: Container(
                          width: 120,
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryBlue.withOpacity(0.1)
                                : Colors.white,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(bottle.name,
                                  overflow: TextOverflow.ellipsis),
                              Text('${bottle.capacity} ml',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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

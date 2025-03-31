import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../helpers/theme.dart';

class SettingScreen extends StatefulWidget {
  final VoidCallback onClose;
  const SettingScreen({Key? key, required this.onClose}) : super(key: key);

  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool darkMode = false;
  int gridCount = 1;
  late TextEditingController _nameController;
  String? selectedColor = 'zinc'; // Default color
  final List<Map<String, dynamic>> colors = [
    {'name': 'zinc', 'color': Colors.grey[600]},
    {'name': 'blue', 'color': Colors.blue},
    {'name': 'green', 'color': Colors.green},
    {'name': 'orange', 'color': Colors.orange},
    {'name': 'red', 'color': Colors.red},
    {'name': 'rose', 'color': Colors.pink},
    {'name': 'violet', 'color': Colors.purple},
    {'name': 'yellow', 'color': Colors.yellow},
    {'name': 'gray', 'color': Colors.grey},
    {'name': 'neutral', 'color': Colors.brown},
    {'name': 'slate', 'color': Colors.blueGrey},
    {'name': 'stone', 'color': Colors.brown[300]},
  ];

  int pomodoroTime = 25; // Default Pomodoro time in minutes
  int breakTime = 5; // Default break time in minutes
  int longBreakTime = 15; // Default long break time in minutes

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadName();
    _loadThemeColor();
    _loadDarkMode(); // Load dark mode preference
    _loadPomodoroSettings(); // Load Pomodoro settings
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('entered_value') ?? '';
    });
  }

  Future<void> _saveName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('entered_value', _nameController.text);
  }

  Future<void> _loadThemeColor() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedColor = prefs.getString('theme_color') ?? 'zinc';
    });
  }

  Future<void> _saveThemeColor(String color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_color', color);
  }

  Future<void> _loadDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      darkMode = prefs.getBool('dark_mode') ?? false;
    });
  }

  Future<void> _saveDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
  }

  Future<void> _loadPomodoroSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      pomodoroTime = prefs.getInt('pomodoro_time') ?? 25;
      breakTime = prefs.getInt('break_time') ?? 5;
      longBreakTime = prefs.getInt('long_break_time') ?? 15;
    });
  }

  Future<void> _savePomodoroSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pomodoro_time', pomodoroTime);
    await prefs.setInt('break_time', breakTime);
    await prefs.setInt('long_break_time', longBreakTime);
  }

  Future<void> _deleteAllTasks() async {
    // Logic to delete all tasks
    // For example, clear tasks from a database or shared preferences
    // await TaskDatabase.instance.deleteAllTasks();
    print("All tasks deleted");
  }

  List<Widget> getThemeOptions(ShadThemeData theme) {
    return colors.map((color) {
      return ShadOption(
        value: color['name'],
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color['color'],
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8),
            Text(color['name']),
          ],
        ),
      );
    }).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.colorScheme.background,
          leading: IconButton(
            icon: Icon(LucideIcons.x),
            color: theme.colorScheme.mutedForeground,
            onPressed: widget.onClose,
          ),
          title: Text('Settings', style: theme.textTheme.h4),
        ),
        body: Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 16),
            children: [
              // General Settings Section
              Text("General Settings", style: theme.textTheme.p),
              SizedBox(height: 8),
              ShadCard(
                height: 56,
                rowCrossAxisAlignment: CrossAxisAlignment.center,
                columnMainAxisAlignment: MainAxisAlignment.start,
                width: double.infinity,
                padding: EdgeInsets.all(8),
                child: Text("Your Name", style: theme.textTheme.muted),
                trailing: Container(
                  width: 120,
                  child: ShadInput(
                    controller: _nameController,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.p,
                    decoration: ShadDecoration(
                      color: theme.colorScheme.card,
                      focusedBorder: ShadBorder.none,
                      border: ShadBorder.none,
                      secondaryBorder: ShadBorder.none,
                      disableSecondaryBorder: true,
                    ),
                    onEditingComplete: () async {
                      await _saveName();
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ),
              ),
              SizedBox(height: 16),
              ShadCard(
                height: 56,
                rowCrossAxisAlignment: CrossAxisAlignment.center,
                columnMainAxisAlignment: MainAxisAlignment.center,
                width: double.infinity,
                padding: EdgeInsets.all(8),
                child: Text("Dark Mode", style: theme.textTheme.muted),
                trailing: GestureDetector(
                  onTap: () =>
                      Provider.of<ThemeNotifier>(context, listen: false)
                          .toggleTheme(),
                  child: Container(
                    width: 70,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.border,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      color: theme.colorScheme.background,
                    ),
                    child: Row(
                      mainAxisAlignment:
                          Provider.of<ThemeNotifier>(context).isDarkTheme
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.muted,
                          ),
                          child: Provider.of<ThemeNotifier>(context).isDarkTheme
                              ? Icon(
                                  LucideIcons.moon,
                                  size: 20,
                                  color: theme.colorScheme.foreground,
                                )
                              : Icon(
                                  LucideIcons.sun,
                                  size: 20,
                                  color: theme.colorScheme.foreground,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Theme Settings Section
              Text("Theme Settings", style: theme.textTheme.p),
              SizedBox(height: 8),
              ShadCard(
                height: 64,
                rowCrossAxisAlignment: CrossAxisAlignment.center,
                columnMainAxisAlignment: MainAxisAlignment.center,
                width: double.infinity,
                padding: EdgeInsets.all(8),
                child: Text("Theme", style: theme.textTheme.muted),
                trailing: ShadSelect<String>(
                  placeholder: const Text('Select a theme'),
                  options: getThemeOptions(theme),
                  initialValue: selectedColor,
                  onChanged: (value) {
                    setState(() {
                      selectedColor = value;
                      Provider.of<ThemeNotifier>(context, listen: false)
                          .setThemeColor(value!);
                      _saveThemeColor(value);
                    });
                  },
                  selectedOptionBuilder: (context, value) {
                    final selectedTheme = colors.firstWhere(
                      (color) => color['name'] == value,
                      orElse: () => {'name': 'zinc', 'color': Colors.grey},
                    );
                    return Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: selectedTheme['color'],
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(selectedTheme['name']),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(height: 24),

              // Pomodoro Settings Section
              Text("Pomodoro Settings", style: theme.textTheme.p),
              SizedBox(height: 8),
              ShadCard(
                height: 64,
                rowCrossAxisAlignment: CrossAxisAlignment.center,
                columnMainAxisAlignment: MainAxisAlignment.center,
                width: double.infinity,
                padding: EdgeInsets.all(8),
                child: Text("Pomodoro Time", style: theme.textTheme.muted),
                trailing: ShadSelect<int>(
                  placeholder: const Text('Select time'),
                  options: List.generate(
                    12,
                    (index) => ShadOption(
                      value: (index + 1) * 5,
                      child: Text('${(index + 1) * 5} mins'),
                    ),
                  ),
                  initialValue: pomodoroTime,
                  onChanged: (value) {
                    setState(() {
                      pomodoroTime = value!;
                      _savePomodoroSettings();
                    });
                  },
                  selectedOptionBuilder: (context, value) {
                    return Text('$value mins');
                  },
                ),
              ),
              SizedBox(height: 16),
              ShadCard(
                height: 64,
                rowCrossAxisAlignment: CrossAxisAlignment.center,
                columnMainAxisAlignment: MainAxisAlignment.center,
                width: double.infinity,
                padding: EdgeInsets.all(8),
                child: Text("Break Time", style: theme.textTheme.muted),
                trailing: ShadSelect<int>(
                  placeholder: const Text('Select time'),
                  options: List.generate(
                    12,
                    (index) => ShadOption(
                      value: (index + 1) * 5,
                      child: Text('${(index + 1) * 5} mins'),
                    ),
                  ),
                  initialValue: breakTime,
                  onChanged: (value) {
                    setState(() {
                      breakTime = value!;
                      _savePomodoroSettings();
                    });
                  },
                  selectedOptionBuilder: (context, value) {
                    return Text('$value mins');
                  },
                ),
              ),
              SizedBox(height: 16),
              ShadCard(
                height: 64,
                rowCrossAxisAlignment: CrossAxisAlignment.center,
                columnMainAxisAlignment: MainAxisAlignment.center,
                width: double.infinity,
                padding: EdgeInsets.all(8),
                child: Text("Long Break Time", style: theme.textTheme.muted),
                trailing: ShadSelect<int>(
                  placeholder: const Text('Select time'),
                  options: List.generate(
                    12,
                    (index) => ShadOption(
                      value: (index + 1) * 5,
                      child: Text('${(index + 1) * 5} mins'),
                    ),
                  ),
                  initialValue: longBreakTime,
                  onChanged: (value) {
                    setState(() {
                      longBreakTime = value!;
                      _savePomodoroSettings();
                    });
                  },
                  selectedOptionBuilder: (context, value) {
                    return Text('$value mins');
                  },
                ),
              ),

              // Task Management Section
              SizedBox(height: 24),
              // Text("Task Management", style: theme.textTheme.h4),
              // SizedBox(height: 8),
              // ShadCard(
              //   height: 56,
              //   rowCrossAxisAlignment: CrossAxisAlignment.center,
              //   columnMainAxisAlignment: MainAxisAlignment.center,
              //   width: double.infinity,
              //   padding: EdgeInsets.all(8),
              //   child: Text("Delete All Tasks", style: theme.textTheme.muted),
              //   trailing: ShadButton.destructive(
              //     onPressed: () async {
              //       final confirm = await showDialog<bool>(
              //         context: context,
              //         builder: (context) => AlertDialog(
              //           title: Text("Confirm Deletion"),
              //           content: Text("Are you sure you want to delete all tasks? This action cannot be undone."),
              //           actions: [
              //             TextButton(
              //               onPressed: () => Navigator.of(context).pop(false),
              //               child: Text("Cancel"),
              //             ),
              //             TextButton(
              //               onPressed: () => Navigator.of(context).pop(true),
              //               child: Text("Delete"),
              //             ),
              //           ],
              //         ),
              //       );
              //       if (confirm == true) {
              //         await _deleteAllTasks();
              //       }
              //     },
              //     child: Text("Delete"),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../helpers/theme.dart';
import 'account_settings.dart';
import 'package:forui/forui.dart';
import 'package:forui/assets.dart';

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

  Widget sectionTitle(String text) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: theme.textTheme.h4?.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Divider(thickness: 1, color: theme.colorScheme.border),
        ],
      ),
    );
  }

  Widget settingRow({
    required String title,
    String? subtitle,
    required Widget trailing,
    bool showDivider = true,
  }) {
    final theme = ShadTheme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: subtitle != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.p?.copyWith(fontWeight: FontWeight.w500)),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle,
                          style: theme.textTheme.muted?.copyWith(fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, color: theme.colorScheme.border),
      ],
    );
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
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.background,
          elevation: 0,
          leading: IconButton(
            icon: Icon(LucideIcons.x),
            color: theme.colorScheme.mutedForeground,
            onPressed: widget.onClose,
          ),
          title: Text('Settings', style: theme.textTheme.h4),
        ),
        body: Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, bottom: MediaQuery.of(context).viewInsets.bottom),
          child: ListView(
            children: [
              sectionTitle("Preferences"),
              settingRow(
                title: "Appearance",
                subtitle: "Switch between light and dark mode.",
                trailing: Switch(
                  value: Provider.of<ThemeNotifier>(context).isDarkTheme,
                  onChanged: (value) {
                    Provider.of<ThemeNotifier>(context, listen: false).toggleTheme();
                  },
                ),
              ),
              settingRow(
                title: "Theme Color",
                subtitle: "Change the accent color of the app.",
                trailing: ShadSelect<String>(
                  placeholder: const Text('Select a color'),
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
              sectionTitle("Pomodoro"),
              settingRow(
                title: "Pomodoro Time",
                subtitle: "Set the duration for each Pomodoro session.",
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
                  selectedOptionBuilder: (context, value) => Text('$value mins'),
                ),
              ),
              settingRow(
                title: "Break Time",
                subtitle: "Set the duration for short breaks.",
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
                  selectedOptionBuilder: (context, value) => Text('$value mins'),
                ),
              ),
              settingRow(
                title: "Long Break Time",
                subtitle: "Set the duration for long breaks.",
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
                  selectedOptionBuilder: (context, value) => Text('$value mins'),
                ),
              ),
              sectionTitle("Account"),
              settingRow(
                title: "Your Name",
                subtitle: "Tap to edit your name.",
                trailing: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => Container(
                        height: MediaQuery.of(context).size.height * 0.9,
                        child: AccountSettingsScreen(
                          onClose: () => Navigator.pop(context),
                        ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 120,
                        child: ShadInput(
                          controller: _nameController,
                          textAlign: TextAlign.end,
                          style: theme.textTheme.p,
                          enabled: false,
                          decoration: ShadDecoration(
                            color: theme.colorScheme.card,
                            focusedBorder: ShadBorder.none,
                            border: ShadBorder.none,
                            secondaryBorder: ShadBorder.none,
                            disableSecondaryBorder: true,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.muted),
                    ],
                  ),
                ),
                showDivider: false,
              ),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

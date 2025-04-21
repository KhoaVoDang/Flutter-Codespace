import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '/models/todo.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'addtodo.dart';
import 'settings.dart';
import 'edittodo.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'pomodoro.dart';
import '/services/pomodoro_service.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);
  static const id = 'home_screen';

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String _enteredName = '';
  List<Todo> todos = [];
  String _selectedTag = 'All';
  int _selectedGrid = 1;
  bool _showInfo = false; // Controls the flipped state of the header card
  int _currentHeaderIndex = 0; // Tracks the current header card index
  final PomodoroService _pomodoroService = PomodoroService();
  late StreamSubscription<Duration> _timerSubscription;
  Duration _remainingTime = Duration.zero;

  static final _shortDateFormatter = DateFormat('EEE');
  static final _monthDayFormatter = DateFormat('MMM d');
  static final _fullmonthDayFormatter = DateFormat('d');
  static final _yearFormatter = DateFormat('y');

  Future<void> _loadInitialData() async {
    await Future.wait([_loadName(), _loadTodos()]);
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _timerSubscription = _pomodoroService.timerStream.listen((time) {
      setState(() {
        _remainingTime = time;
      });
    });
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enteredName = prefs.getString('entered_value') ?? '';
      if (_enteredName.isNotEmpty) {
        _enteredName = _enteredName.replaceFirst(
          _enteredName[0],
          _enteredName[0].toUpperCase(),
        );
      }
    });
  }

  void _showAddTodoBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: AddTodoScreen(onAdd: _loadTodos),
          ),
        );
      },
    );
  }

  void _showTodoOptions(Todo todo) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todo.text,
                  style: ShadTheme.of(context).textTheme.h4,
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis,
                ),
                Spacer(),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: ShadButton.outline(
                        height: 56,
                        padding: EdgeInsets.all(4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(todo.isPinned
                                ? Icons.push_pin
                                : Icons.push_pin_outlined),
                            SizedBox(height: 4),
                            Text(todo.isPinned ? "Unpin" : "Pin"),
                          ],
                        ),
                        onPressed: () {
                          setState(() {
                            todo.isPinned = !todo.isPinned;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: ShadButton.outline(
                        onPressed: () {
                          Navigator.pop(context); // Close options first
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16.0)),
                            ),
                            builder: (BuildContext context) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom:
                                      MediaQuery.of(context).viewInsets.bottom,
                                ),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight:
                                        MediaQuery.of(context).size.height *
                                            0.5,
                                  ),
                                  child: EditTodoScreen(
                                    todo: todo,
                                    onEdit: _loadTodos,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        height: 56,
                        padding: EdgeInsets.all(4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit),
                            SizedBox(height: 4),
                            Text("Edit"),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: ShadButton.destructive(
                        height: 56,
                        padding: EdgeInsets.all(4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete),
                            SizedBox(height: 4),
                            Text("Delete"),
                          ],
                        ),
                        onPressed: () async {
                          // Show confirmation dialog.
                          final result = await showShadDialog(
                            context: context,
                            builder: (context) => ShadDialog.alert(
                              title: const Text('Are you absolutely sure?'),
                              description: const Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'This action cannot be undone.',
                                ),
                              ),
                              actions: [
                                ShadButton.outline(
                                  foregroundColor: ShadTheme.of(context)
                                      .colorScheme
                                      .cardForeground,
                                  child: const Text('Cancel'),
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                ),
                                ShadButton.destructive(
                                  child: const Text('Continue'),
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                ),
                              ],
                            ),
                          );
                          if (result == true) {
                            await _deleteTodo(todo);
                            ShadToaster.of(context).show(
                              const ShadToast.destructive(
                                description: Text('Task deleted'),
                              ),
                            );
                            Navigator.pop(
                                context); // Close the options bottom sheet.
                          }
                        },
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: ShadButton.outline(
                        height: 56,
                        padding: EdgeInsets.all(4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.timer),
                            SizedBox(height: 4),
                            Text("Pomodoro"),
                          ],
                        ),
                        onPressed: () {
                          Navigator.pop(context); // Close the options sheet
                          _showPomodoroScreen(todo);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Deletes the given todo from Supabase and reloads the list.
  Future<void> _deleteTodo(Todo todo) async {
    final supabase = Supabase.instance.client;
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        throw 'No user logged in';
      }

      final response = await supabase
          .from('notes')
          .delete()
          .eq('id', todo.id)
          .eq('user_id', currentUser.id);

      if (response.error != null) {
        throw response.error!;
      }

      _loadTodos();
    } catch (e) {
      print('Error deleting todo: $e');
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text('Failed to delete task: $e'),
        ),
      );
    }
  }

  void _toggleTodoCompletion(Todo todo) async {
    final supabase = Supabase.instance.client;
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        throw 'No user logged in';
      }

      await supabase
          .from('notes')
          .update({'is_done': !todo.isDone})
          .match({'id': todo.id, 'user_id': currentUser.id});

      setState(() {
        todo.isDone = !todo.isDone;
      });
    } catch (e) {
      print('Error toggling completion: $e');
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            description: Text('Failed to update task: $e'),
          ),
        );
      }
    }
  }

  Future<void> _loadTodos() async {
    final supabase = Supabase.instance.client;
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        throw 'No user logged in';
      }

      final response = await supabase
          .from('notes')
          .select('*')
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false); // Optional: order by creation date

      if (response is! List) {
        throw 'Invalid response format';
      }

      setState(() {
        todos = response.map((item) {
          final data = {
            'id': item['id'].toString(),
            'created_at': item['created_at'],
            'text': item['text'] ?? '',
            'is_done': item['is_done'] ?? false,
            'is_pinned': item['is_pinned'] ?? false,
            'tag': item['tag'] ?? '',
          };
          return Todo.fromJson(data);
        }).toList();
      });
    } catch (e) {
      print('Error loading todos: $e');
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            description: Text('Failed to load tasks: $e'),
          ),
        );
      }
    }
  }

  List<Todo> get pinnedTodos => todos.where((todo) => todo.isPinned).toList();
  List<Todo> get unpinnedTodos =>
      todos.where((todo) => !todo.isPinned).toList();

  Widget _buildDateDisplay(DateTime today) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _monthDayFormatter.format(today),
          style: ShadTheme.of(context).textTheme.small,
        ),
        Text(
          _yearFormatter.format(today),
          style: ShadTheme.of(context).textTheme.muted,
        ),
      ],
    );
  }

  void _showPomodoroScreen(Todo todo) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PomodoroScreen(
          todo: todo,
          initialMinutes: _remainingTime.inMinutes,
          initialSeconds: _remainingTime.inSeconds.remainder(60),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final List<Widget> headerCards = [
      // Hello card
      ShadCard(
        key: ValueKey('hello_card_${DateTime.now().millisecondsSinceEpoch}'),
        padding: EdgeInsets.all(16),
        height: 88,
        width: double.infinity,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello $_enteredName',
                  style: ShadTheme.of(context).textTheme.h3,
                ),
                RichText(
                  text: TextSpan(
                    style: ShadTheme.of(context).textTheme.muted,
                    children: [
                      const TextSpan(text: 'You have '),
                      TextSpan(
                        text: '${todos.where((todo) => !todo.isDone).length} task(s)',
                        style: TextStyle(
                          color: ShadTheme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: ' to complete'),
                    ],
                  ),
                ),
              ],
            ),
            // Spacer(),
            // ShadButton.outline(
            //   child: Icon(LucideIcons.settings2),
            //   onPressed: () {
            //     showModalBottomSheet(
            //       context: context,
            //       isScrollControlled: true,
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
            //       ),
            //       builder: (context) => ConstrainedBox(
            //         constraints: BoxConstraints(
            //           maxHeight: MediaQuery.of(context).size.height * 0.9,
            //         ),
            //         child: SettingScreen(
            //           onClose: () {
            //             _loadInitialData();
            //             Navigator.pop(context);
            //           },
            //         ),
            //       ),
            //     );
            //   },
            // ),
          ],
        ),
      ),
      // Date card
      ShadCard(
        key: ValueKey('date_card_${DateTime.now().millisecondsSinceEpoch}'),
        padding: EdgeInsets.all(16),
        height: 88,
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Text(
                  _shortDateFormatter.format(DateTime.now()),
                  style: ShadTheme.of(context).textTheme.h3,
                ),
                const SizedBox(width: 8),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ShadTheme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            _buildDateDisplay(DateTime.now()),
            // ShadButton.outline(
            //   child: Icon(LucideIcons.settings2),
            //   onPressed: () {
            //     showModalBottomSheet(
            //       context: context,
            //       isScrollControlled: true,
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
            //       ),
            //       builder: (context) => ConstrainedBox(
            //         constraints: BoxConstraints(
            //           maxHeight: MediaQuery.of(context).size.height * 0.9,
            //         ),
            //         child: SettingScreen(onClose: () {
            //           Navigator.pop(context);
            //         }),
            //       ),
            //     );
            //   },
            // ),
          ],
        ),
      ),
      // Pomodoro card
      if (_pomodoroService.isRunning)
        GestureDetector(
          onTap: () {
            // Open the Pomodoro screen with the current timer
            _showPomodoroScreen(
              todos.firstWhere((todo) => todo.isPinned, orElse: () => todos.first),
            );
          },
          child: ShadCard(
            key: ValueKey('pomodoro_card_${DateTime.now().millisecondsSinceEpoch}'),
            padding: EdgeInsets.all(16),
            height: 88,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pomodoro Timer',
                  style: ShadTheme.of(context).textTheme.h3,
                ),
                Text(
                  '${_remainingTime.inMinutes}:${(_remainingTime.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: ShadTheme.of(context).textTheme.h3,
                ),
              ],
            ),
          ),
        ),
    ];

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          if (details.primaryDelta! < 0) {
            // Swipe up
            _currentHeaderIndex = (_currentHeaderIndex + 1) % headerCards.length;
          } else if (details.primaryDelta! > 0) {
            // Swipe down
            _currentHeaderIndex =
                (_currentHeaderIndex - 1 + headerCards.length) % headerCards.length;
          }
        });
      },
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        child: headerCards[_currentHeaderIndex],
      ),
    );
  }

  int _selectedIndex = 0;

  Widget _buildNavItem(int index, IconData icon, {required bool isCenter}) {
    final double size = isCenter ? 60 : 48;
    final double iconSize = isCenter ? 24 : 20;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;

          if (index == 1) {
            _showAddTodoBottomSheet();
          } else if (index == 2) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
              ),
              builder: (context) => ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                child: SettingScreen(
                  onClose: () {
                    _loadInitialData();
                    Navigator.pop(context);
                  },
                ),
              ),
            );
          }
        });
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: ShadTheme.of(context).colorScheme.border,
            width: 1,
          ),
          color: _selectedIndex == index
              ? ShadTheme.of(context).colorScheme.card
              : ShadTheme.of(context).colorScheme.card,
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: ShadTheme.of(context).colorScheme.foreground,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timerSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              SizedBox(height: 16),
              pinnedTodos.isNotEmpty
                  ? Text('Pinned Task', style: ShadTheme.of(context).textTheme.muted)
                  : SizedBox(height: 8),
              if (pinnedTodos.isNotEmpty)
                StaggeredGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: List.generate(
                    pinnedTodos.length,
                    (index) {
                      final todo = pinnedTodos[index];
                      return GestureDetector(
                        onTap: () => _showTodoOptions(todo),
                        child: ShadCard(
                          padding: EdgeInsets.all(8.0),
                          rowMainAxisAlignment: MainAxisAlignment.start,
                          columnMainAxisAlignment: MainAxisAlignment.start,
                          leading: ShadCheckbox(
                            value: todo.isDone,
                            onChanged: (bool? value) async {
                              _toggleTodoCompletion(todo);
                            },
                          ),
                          child: Text(
                            todo.text,
                            style: ShadTheme.of(context).textTheme.h4.copyWith(
                                  decoration: todo.isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: todo.isDone
                                      ? ShadTheme.of(context)
                                          .colorScheme
                                          .mutedForeground
                                      : null,
                                ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              else if (unpinnedTodos.isNotEmpty && pinnedTodos.isEmpty)
                Center(
                  child: Text(
                    "You can pin a task to keep it at the top for quick access.",
                    style: ShadTheme.of(context).textTheme.muted,
                  ),
                ),
              SizedBox(height: 16),
              if (unpinnedTodos.isNotEmpty)
                Text('Task', style: ShadTheme.of(context).textTheme.muted),
              SizedBox(height: 8),
              if (unpinnedTodos.isNotEmpty)
                StaggeredGrid.count(
                  crossAxisCount: 1,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: List.generate(
                    unpinnedTodos.length,
                    (index) {
                      final todo = unpinnedTodos[index];
                      return Wrap(
                        direction: Axis.horizontal,
                        children: [
                          GestureDetector(
                            onTap: () => _showTodoOptions(todo),
                            child: ShadCard(
                              width: double.infinity,
                              rowMainAxisAlignment: MainAxisAlignment.start,
                              columnMainAxisAlignment: MainAxisAlignment.start,
                              padding: const EdgeInsets.all(8.0),
                              leading: ShadCheckbox(
                                value: todo.isDone,
                                onChanged: (bool? value) async {
                                  _toggleTodoCompletion(todo);
                                },
                              ),
                              child: Text(
                                todo.text,
                                style: ShadTheme.of(context)
                                    .textTheme
                                    .list
                                    .copyWith(
                                      decoration: todo.isDone
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: todo.isDone
                                          ? ShadTheme.of(context)
                                              .colorScheme
                                              .mutedForeground
                                          : null,
                                    ),
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
                ),
              if (unpinnedTodos.isEmpty && pinnedTodos.isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Oh no!!! 👽🛸 Alien here to kidnap a lazy person. Please escape by:",
                        textAlign: TextAlign.center,
                        style: ShadTheme.of(context).textTheme.muted,
                      ),
                      SizedBox(height: 16),
                      ShadButton(
                        onPressed: _showAddTodoBottomSheet,
                        child: Text("Add Task"),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
       
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(0, Icons.collections, isCenter: false),
              _buildNavItem(1, Icons.add_circle_outline, isCenter: true),
              _buildNavItem(2, LucideIcons.settings2, isCenter: false),
            ],
          ),
        ),
      ),
    );
  }
}

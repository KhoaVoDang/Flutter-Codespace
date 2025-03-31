import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '/models/todo.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'addtodo.dart';
import 'settings.dart';
import 'edittodo.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'pomodoro.dart';

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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PomodoroScreen(todo: todo),
                            ),
                          );
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

  /// Deletes the given todo from SharedPreferences and reloads the list.
  Future<void> _deleteTodo(Todo todo) async {
    final prefs = await SharedPreferences.getInstance();
    final todoStrings = prefs.getStringList('todos') ?? [];
    // Remove the todo by matching the id.
    todoStrings.removeWhere((todoString) {
      final Map<String, dynamic> todoMap = json.decode(todoString);
      return todoMap['id'] == todo.id;
    });
    await prefs.setStringList('todos', todoStrings);
    _loadTodos();
  }

  void _toggleTodoCompletion(Todo todo) async {
    setState(() {
      todo.isDone = !todo.isDone;
    });
    final prefs = await SharedPreferences.getInstance();
    final updatedTodos = todos.map((t) => json.encode(t.toJson())).toList();
    await prefs.setStringList('todos', updatedTodos);
  }

  Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final todoStrings = prefs.getStringList('todos') ?? [];
    setState(() {
      todos = todoStrings.map((todoString) {
        final todoMap = Map<String, dynamic>.from(json.decode(todoString));
        return Todo.fromJson(todoMap);
      }).toList();
    });
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

  @override
  Widget build(BuildContext context) {
    // Calculate incomplete tasks count.
    final int incompleteTasks = todos.where((todo) => !todo.isDone).length;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card with flip functionality.
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showInfo = !_showInfo;
                  });
                },
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 600),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    final rotate =
                        Tween(begin: pi, end: 0.0).animate(animation);
                    return AnimatedBuilder(
                      animation: rotate,
                      child: child,
                      builder: (context, child) {
                        // Determine if the widget is the backside by checking its key.
                        bool isBack = child!.key == ValueKey('back');
                        // Reverse rotation for backside to create a flip effect.
                        double rotationValue =
                            isBack ? -rotate.value : rotate.value;
                        return Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001) // add perspective
                            ..rotateX(rotationValue),
                          alignment: Alignment.center,
                          child: child,
                        );
                      },
                    );
                  },
                  child: _showInfo
                      ? ShadCard(
                          key: ValueKey('back'),
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
                                        style: ShadTheme.of(context)
                                            .textTheme
                                            .muted,
                                        children: [
                                          const TextSpan(text: 'You have '),
                                          TextSpan(
                                            text: '$incompleteTasks task(s)',
                                            style: TextStyle(
                                              color: ShadTheme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const TextSpan(text: ' to complete'),
                                        ],
                                      ),
                                    )
                                  ]),
                              Spacer(),
                              ShadButton.outline(
                                child: Icon(LucideIcons.settings2),
                                onPressed: () {
                                  showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(16.0)),
                                      ),
                                      builder: (context) => ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxHeight: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.9,
                                            ),
                                            child: SettingScreen(
                                              onClose: () {
                                                _loadInitialData();
                                                Navigator.pop(context);
                                              },
                                            ),
                                          ));
                                },
                              )
                            ],
                          ),
                        )
                      : ShadCard(
                          key: ValueKey('front'),
                          padding: EdgeInsets.all(16),
                          height: 88,
                          width: double.infinity,
                          child: Container(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _shortDateFormatter
                                          .format(DateTime.now()),
                                      style: ShadTheme.of(context).textTheme.h3,
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: ShadTheme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                _buildDateDisplay(DateTime.now()),
                                ShadButton.outline(
                                    child: Icon(LucideIcons.settings2),
                                    onPressed: () {
                                      showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(
                                                top: Radius.circular(16.0)),
                                          ),
                                          builder: (context) => ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  maxHeight:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .height *
                                                          0.9,
                                                ),
                                                child:
                                                    SettingScreen(onClose: () {
                                                  Navigator.pop(context);
                                                }),
                                              ));
                                    })
                              ],
                            ),
                          ),
                        ),
                ),
              ),
              SizedBox(height: 16),
              Text('Pinned Task', style: ShadTheme.of(context).textTheme.muted),
              SizedBox(height: 8),
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
                            onChanged: (value) {
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
                ),
              SizedBox(height: 16),
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
                                onChanged: (value) {
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
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTodoBottomSheet,
        child: Icon(Icons.add),
      ),
    );
  }
}

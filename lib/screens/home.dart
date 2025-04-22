import 'dart:async';
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
import 'package:flip_card_swiper/flip_card_swiper.dart';
import '../widgets/collection_card.dart';
import '../widgets/todo_row.dart';
import '../widgets/pomodoro_flip_timer.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);
  static const id = 'home_screen';

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String newcollectionname = '';
  List<Todo> todos = [];
  String _selectedTag = 'All';
  int _selectedGrid = 1;
  bool _showInfo = false; // Controls the flipped state of the header card
  int _currentHeaderIndex = 0; // Tracks the current header card index
  final PomodoroService _pomodoroService = PomodoroService();
  late StreamSubscription<Duration> _timerSubscription;
  Duration _remainingTime = Duration.zero;
  bool _minimizedPomodoro = false;
  final ValueNotifier<Duration> _minimizedPomodoroTimeNotifier = ValueNotifier(Duration.zero);
  Todo? _minimizedPomodoroTodo;
  Timer? _minimizedPomodoroTimer;
  PomodoroMode _minimizedPomodoroMode = PomodoroMode.pomodoro;
  final TextEditingController _collectionNameController = TextEditingController();

  static final _shortDateFormatter = DateFormat('EEE');
  static final _monthDayFormatter = DateFormat('MMM d');
  static final _fullmonthDayFormatter = DateFormat('d');
  static final _yearFormatter = DateFormat('y');

  List<Map<String, dynamic>> collections = [];
  String? selectedCollectionId;
  String? selectedCollectionName;

  String? _userName;
  String? _userAvatarUrl;

  Future<void> _loadInitialData() async {
    await Future.wait([_loadUserProfile(), _loadTodos()]);
  }

  Future<void> _loadTodos() async {
    // Placeholder implementation for loading todos
    setState(() {
      todos = []; // Replace with actual logic to load todos
    });
  }

  Future<void> _loadUserProfile() async {
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;
    try {
      final response = await supabase
          .from('profiles')
          .select('preferred_name, avatar_url')
          .eq('id', currentUser.id)
          .single();
      if (response != null && response is Map) {
        setState(() {
          _userName = response['preferred_name'] ?? currentUser.email ?? 'User';
          _userAvatarUrl = response['avatar_url'];
        });
      } else {
        setState(() {
          _userName = currentUser.email ?? 'User';
          _userAvatarUrl = null;
        });
      }
    } catch (e) {
      setState(() {
        _userName = currentUser.email ?? 'User';
        _userAvatarUrl = null;
      });
    }
  }

  // Helper to get stats for a collection
  Future<Map<String, dynamic>> _getCollectionStats(String collectionId) async {
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return {'total': 0, 'done': 0};
    final notes = await supabase
        .from('notes')
        .select('is_done')
        .eq('user_id', currentUser.id)
        .eq('collection_id', collectionId);
    if (notes is! List) return {'total': 0, 'done': 0};
    final total = notes.length;
    final done = notes.where((n) => n['is_done'] == true).length;
    return {'total': total, 'done': done};
  }

  // Cache for collection stats to avoid repeated queries
  final Map<String, Map<String, dynamic>> _collectionStatsCache = {};

  Future<void> _refreshCollectionStats() async {
    _collectionStatsCache.clear();
    for (final c in collections) {
      final stats = await _getCollectionStats(c['id']);
      _collectionStatsCache[c['id']] = stats;
    }
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadCollections();
    _loadUserProfile(); // <-- load user profile from Supabase
  }

  Future<void> _loadCollections() async {
    final supabase = Supabase.instance.client;
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) throw 'No user logged in';

      final response = await supabase
          .from('collections')
          .select('*')
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false);

      if (response is! List) throw 'Invalid response format';

      setState(() {
        collections = List<Map<String, dynamic>>.from(response);
        selectedCollectionId = null;
      });

      await _refreshCollectionStats(); // <-- fetch stats after collections loaded
    } catch (e) {
      print('Error loading collections: $e');
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            description: Text('Failed to load collections: $e'),
          ),
        );
      }
    }
  }

  Future<void> _loadTodosForCollection(String collectionId) async {
    final supabase = Supabase.instance.client;
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) throw 'No user logged in';

      final response = await supabase
          .from('notes')
          .select('*')
          .eq('user_id', currentUser.id)
          .eq('collection_id', collectionId)
          .order('created_at', ascending: false);

      if (response is! List) throw 'Invalid response format';

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

  void _onCollectionTap(Map<String, dynamic> collection) async {
    setState(() {
      selectedCollectionId = collection['id'];
      selectedCollectionName = collection['name'];
    });
    await _loadTodosForCollection(collection['id']);
  }

  void _onBackToCollections() async {
    setState(() {
      selectedCollectionId = null;
      selectedCollectionName = null;
      todos = [];
    });
    await _loadCollections(); // <-- reload collections and stats
  }

  void _showAddTodoBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (BuildContext context) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: AddTodoScreen(
            onAdd: () => _loadTodosForCollection(selectedCollectionId!),
            collectionId: selectedCollectionId,
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
                        onPressed: () async {
                          await _toggleTodoPin(todo);
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
                                    onEdit: () =>
                                        _loadTodosForCollection(selectedCollectionId!),
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

      _loadTodosForCollection(selectedCollectionId!);
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

  Future<void> _toggleTodoPin(Todo todo) async {
    final supabase = Supabase.instance.client;
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        throw 'No user logged in';
      }

      await supabase
          .from('notes')
          .update({'is_pinned': !todo.isPinned})
          .match({'id': todo.id, 'user_id': currentUser.id});

      setState(() {
        todo.isPinned = !todo.isPinned;
      });
      _loadTodosForCollection(selectedCollectionId!);
    } catch (e) {
      print('Error toggling pin: $e');
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            description: Text('Failed to update pin: $e'),
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

  void _showPomodoroScreen(Todo todo, {Duration? initialTime, PomodoroMode? mode}) async {
    if (_minimizedPomodoro) {
      _minimizedPomodoroTimer?.cancel();
      setState(() {
        _minimizedPomodoro = false;
        _minimizedPomodoroTodo = null;
      });
      _minimizedPomodoroTimeNotifier.value = Duration.zero;
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PomodoroScreen(
          todo: todo,
          initialMinutes: initialTime?.inMinutes ?? _remainingTime.inMinutes,
          initialSeconds: initialTime?.inSeconds.remainder(60) ?? _remainingTime.inSeconds.remainder(60),
          initialMode: mode,
        ),
      ),
    );
    if (result is Map) {
      setState(() {
        _minimizedPomodoro = true;
        _minimizedPomodoroTodo = todo;
      });
      _minimizedPomodoroTimeNotifier.value = result['duration'] as Duration;
      _minimizedPomodoroMode = result['mode'] as PomodoroMode;
      _startMinimizedPomodoroTimer();
    }
  }

  void _startMinimizedPomodoroTimer() {
    _minimizedPomodoroTimer?.cancel();
    _minimizedPomodoroTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!_minimizedPomodoro) {
        timer.cancel();
        return;
      }
      if (_minimizedPomodoroTimeNotifier.value.inSeconds > 0) {
        _minimizedPomodoroTimeNotifier.value =
            _minimizedPomodoroTimeNotifier.value - Duration(seconds: 1);
      } else {
        timer.cancel();
        setState(() {
          _minimizedPomodoro = false;
          _minimizedPomodoroTodo = null;
        });
        _minimizedPomodoroTimeNotifier.value = Duration.zero;
      }
    });
  }

  List<Map<String, dynamic>> get headerCardsData {
    final List<Map<String, dynamic>> cards = [
      {
        'type': 'hello',
        'widget': ShadCard(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          height: 72,
          width: double.infinity,
          child: Row(
            children: [
              if (_userAvatarUrl != null && _userAvatarUrl!.isNotEmpty)
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(_userAvatarUrl!),
                  backgroundColor: Colors.transparent,
                )
              else
                CircleAvatar(
                  radius: 24,
                  child: Icon(Icons.person),
                ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Hello ${_userName ?? ''}',
                    style: ShadTheme.of(context).textTheme.h3,
                  ),
                  RichText(
                    text: TextSpan(
                      style: ShadTheme.of(context).textTheme.muted,
                      children: [
                        const TextSpan(text: 'You have '),
                        TextSpan(
                          text:
                              '${todos.where((todo) => !todo.isDone).length} task(s)',
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
            ],
          ),
        ),
      },
      {
        'type': 'date',
        'widget': ShadCard(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          height: 72,
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
            ],
          ),
        ),
      },
    ];

    if (!_minimizedPomodoro && !_pomodoroService.isRunning) {
      cards.add({
        'type': 'focus',
        'widget': GestureDetector(
          onTap: () async {
            final selectedTodo = await showModalBottomSheet<Todo>(
              context: context,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
              ),
              builder: (context) {
                final availableTodos = todos.where((t) => !t.isDone).toList();
                if (availableTodos.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        "No tasks available to focus on.",
                        style: ShadTheme.of(context).textTheme.muted,
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Select a task to focus on",
                        style: ShadTheme.of(context).textTheme.h4,
                      ),
                      SizedBox(height: 16),
                      ...availableTodos.map((todo) => ListTile(
                            title: Text(todo.text, maxLines: 2, overflow: TextOverflow.ellipsis),
                            onTap: () {
                              Navigator.pop(context, todo);
                            },
                          )),
                    ],
                  ),
                );
              },
            );
            if (selectedTodo != null) {
              _showPomodoroScreen(selectedTodo);
            }
          },
          child: ShadCard(
           padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
           height: 72,
            width: double.infinity,
            child: 
            Center(child: 
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bolt, color: ShadTheme.of(context).colorScheme.primary),
                SizedBox(width: 12),
                Text(
                  "Start focusing now",
                  style: ShadTheme.of(context).textTheme.h3,
                ),
              ],)
            ),
          ),
        ),
      });
    }

    if (_minimizedPomodoro && _minimizedPomodoroTodo != null) {
      cards.add({
        'type': 'pomodoro_minimized',
        'widget': GestureDetector(
          onTap: () {
            _showPomodoroScreen(
              _minimizedPomodoroTodo!,
              initialTime: _minimizedPomodoroTimeNotifier.value,
              mode: _minimizedPomodoroMode,
            );
          },
          child: ShadCard(
           padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 72,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ValueListenableBuilder<Duration>(
                  valueListenable: _minimizedPomodoroTimeNotifier,
                  builder: (context, value, _) => PomodoroFlipTimer(
                    duration: value,
                    label: _getModeLabel(_minimizedPomodoroMode),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _minimizedPomodoroTodo?.text ?? "",
                    style: ShadTheme.of(context).textTheme.h4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      });
    } else if (_pomodoroService.isRunning) {
      cards.add({
        'type': 'pomodoro',
        'widget': GestureDetector(
          onTap: () {
            _showPomodoroScreen(
              todos.firstWhere((todo) => todo.isPinned, orElse: () => todos.first),
            );
          },
          child: ShadCard(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 72,
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
      });
    }
    return cards;
  }

  String _getModeLabel(PomodoroMode mode) {
    switch (mode) {
      case PomodoroMode.pomodoro:
        return "Pomodoro";
      case PomodoroMode.breakMode:
        return "Break";
      case PomodoroMode.longBreak:
        return "Long Break";
      default:
        return "";
    }
  }

  Widget _buildHeaderCard() {
    final cards = headerCardsData;
    if (cards.isEmpty) return SizedBox.shrink();
    
    return FlipCardSwiper(
      cardData: cards,
      onCardChange: (newIndex) {
        // Optionally handle card change
      },
      cardBuilder: (context, index, visibleIndex) {
        return cards[index]['widget'];
      }, onCardCollectionAnimationComplete: (bool value) {  },
    );
  }

  int _selectedIndex = 0;

  Widget _buildNavItem(int index, IconData icon, {required bool isCenter}) {
    final double size = isCenter ? 48 : 40;
    final double iconSize = isCenter ? 24 : 16;

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

  Future<void> _addCollection() async {
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;
    final name = _collectionNameController.text.trim();
    if (currentUser == null || name.isEmpty) return;
    try {
      await supabase.from('collections').insert({
        'name': name,
        'user_id': currentUser.id,
        'created_at': DateTime.now().toIso8601String(),
      });
      _collectionNameController.clear();
      Navigator.pop(context);
      await _loadCollections(); // <-- this will also refresh stats
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(description: Text('Failed to add collection: $e')),
        );
      }
    }
  }

  void _showAddCollectionDialog() {
    showModalBottomSheet(
      context: context,
   //   isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add collection',
                  style: ShadTheme.of(context).textTheme.muted,
                ),
                SizedBox(height: 8),
                ShadInput(
                 onChanged: (value) => setState(() {
                newcollectionname= _collectionNameController.text;
                                },
                                ),
                  controller: _collectionNameController,
                  autofocus: true,
                  minLines: null,
                  maxLines: null,
                  expands: false,
                  style: ShadTheme.of(context).textTheme.h4.copyWith(fontSize: 20),
                                //    placeholder: Text('Collection name'),
                  decoration: ShadDecoration(
                    color: ShadTheme.of(context).colorScheme.background,
                    focusedBorder: ShadBorder.none,
                    border: ShadBorder.none,
                    secondaryBorder: ShadBorder.none,
                    disableSecondaryBorder: true,
                  ),
                ),
              
                Row(
                  children: [
                    Spacer(),
                    newcollectionname.isNotEmpty
                        ? ShadButton(
                            onPressed: _addCollection,
                            child: Text("Save"),
                          )
                        : SizedBox.shrink(),
                  ],
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editCollection(Map<String, dynamic> collection) async {
    final TextEditingController controller = TextEditingController(text: collection['name'] ?? '');
    await showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit collection',
                  style: ShadTheme.of(context).textTheme.muted,
                ),
                SizedBox(height: 8),
                ShadInput(
                  controller: controller,
                  autofocus: true,
                  minLines: null,
                  maxLines: null,
                  expands: false,
                  style: ShadTheme.of(context).textTheme.h4.copyWith(fontSize: 20),
                  decoration: ShadDecoration(
                    color: ShadTheme.of(context).colorScheme.background,
                    focusedBorder: ShadBorder.none,
                    border: ShadBorder.none,
                    secondaryBorder: ShadBorder.none,
                    disableSecondaryBorder: true,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Spacer(),
                    ShadButton(
                      onPressed: () async {
                        final newName = controller.text.trim();
                        if (newName.isNotEmpty) {
                          final supabase = Supabase.instance.client;
                          try {
                            await supabase
                                .from('collections')
                                .update({'name': newName})
                                .eq('id', collection['id']);
                            Navigator.pop(context);
                            await _loadCollections();
                          } catch (e) {
                            if (mounted) {
                              ShadToaster.of(context).show(
                                ShadToast.destructive(description: Text('Failed to update collection: $e')),
                              );
                            }
                          }
                        }
                      },
                      child: Text("Save"),
                    ),
                  ],
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteCollection(Map<String, dynamic> collection) async {
    final confirm = await showShadDialog(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: const Text('Delete collection?'),
        description: const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('This will delete the collection and all its tasks. This action cannot be undone.'),
        ),
        actions: [
          ShadButton.outline(
            foregroundColor: ShadTheme.of(context).colorScheme.cardForeground,
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ShadButton.destructive(
            child: const Text('Delete'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final supabase = Supabase.instance.client;
      try {
        // Optionally: delete all notes in this collection first
        await supabase.from('notes').delete().eq('collection_id', collection['id']);
        await supabase.from('collections').delete().eq('id', collection['id']);
        await _loadCollections();
        if (mounted) {
          ShadToaster.of(context).show(
            ShadToast.destructive(description: Text('Collection deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ShadToaster.of(context).show(
            ShadToast.destructive(description: Text('Failed to delete collection: $e')),
          );
        }
      }
    }
  }

  Widget _buildCollectionsList(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderCard(),
        
        SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: [
              Text('Collections', style: theme.textTheme.h3),
              Spacer(),
              ShadButton(
                leading: Icon(Icons.add, size: 18),
                child: Text('Add'),
                size: ShadButtonSize.sm,
                onPressed: _showAddCollectionDialog,
              ),
            ],
          ),
        ),
        Divider(thickness: 1, color: theme.colorScheme.border),
        SizedBox(height: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: collections.isEmpty
                ? Center(child: Text('No collections found', style: theme.textTheme.muted))
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1,
                    ),
                    itemCount: collections.length,
                    itemBuilder: (context, idx) {
                      final collection = collections[idx];
                      final stats = _collectionStatsCache[collection['id']] ?? {'total': 0, 'done': 0};
                      final total = stats['total'] ?? 0;
                      final done = stats['done'] ?? 0;
                      final percent = total == 0 ? 0 : ((done / total) * 100).round();
                      return CollectionCard(
                        collection: collection,
                        total: total,
                        done: done,
                        percent: percent,
                        theme: theme,
                        onTap: () => _onCollectionTap(collection),
                        onEdit: () => _editCollection(collection),
                        onDelete: () => _deleteCollection(collection),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesList(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
                onPressed: _onBackToCollections,
              ),
              SizedBox(width: 8),
              Text(selectedCollectionName ?? '', style: theme.textTheme.h3),
              Spacer(),
              ShadButton(
                leading: Icon(Icons.add, size: 18),
                child: Text('Add'),
                size: ShadButtonSize.sm,
                onPressed: _showAddTodoBottomSheet,
              ),
            ],
          ),
        ),
        Divider(thickness: 1, color: theme.colorScheme.border),
        SizedBox(height: 16),
        if (todos.isEmpty)
          Center(child: Text('No tasks in this collection', style: theme.textTheme.muted)),
        ...todos.map((todo) => TodoRow(
              todo: todo,
              isPinned: todo.isPinned,
              theme: theme,
              onTap: () => _showTodoOptions(todo),
              onToggle: () => _toggleTodoCompletion(todo),
            )),
      ],
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    // Remove the center add button for tasks screen
    return Container(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(0, LucideIcons.folder, isCenter: false),
            SizedBox(width: 48), // Always placeholder for center button
            _buildNavItem(2, LucideIcons.settings2, isCenter: false),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timerSubscription.cancel();
    _minimizedPomodoroTimer?.cancel();
    _minimizedPomodoroTimeNotifier.dispose();
    _collectionNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SafeArea(
          child: selectedCollectionId == null
              ? _buildCollectionsList(context)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(),
                    Expanded(child: _buildNotesList(context)),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }
}

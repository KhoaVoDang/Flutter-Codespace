import 'dart:async';

class PomodoroService {
  static final PomodoroService _instance = PomodoroService._internal();
  factory PomodoroService() => _instance;

  PomodoroService._internal();

  final Duration _pomodoroDuration = Duration(minutes: 25);
  final Duration _breakDuration = Duration(minutes: 5);
  final Duration _longBreakDuration = Duration(minutes: 30);

  Duration _remainingTime = Duration.zero;
  Timer? _timer;
  bool _isRunning = false;

  final StreamController<Duration> _timerStreamController = StreamController.broadcast();
  Stream<Duration> get timerStream => _timerStreamController.stream;

  bool get isRunning => _isRunning;

  void startPomodoro() {
    _startTimer(_pomodoroDuration);
  }

  void startBreak({bool isLongBreak = false}) {
    _startTimer(isLongBreak ? _longBreakDuration : _breakDuration);
  }

  void pause() {
    _timer?.cancel();
    _isRunning = false;
  }

  void reset() {
    _timer?.cancel();
    _remainingTime = Duration.zero;
    _isRunning = false;
    _timerStreamController.add(_remainingTime);
  }

  void _startTimer(Duration duration) {
    _timer?.cancel();
    _remainingTime = duration;
    _isRunning = true;

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        _remainingTime -= Duration(seconds: 1);
        _timerStreamController.add(_remainingTime);
      } else {
        _timer?.cancel();
        _isRunning = false;
        _timerStreamController.add(Duration.zero);
      }
    });
  }

  void dispose() {
    _timer?.cancel();
    _timerStreamController.close();
  }
}

import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/models/todo.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:audioplayers/audioplayers.dart';

//import 'soundsettings.dart';
// Define the modes
enum PomodoroMode { pomodoro, breakMode, longBreak }

class PomodoroScreen extends StatefulWidget {
  final Todo todo;

  PomodoroScreen({required this.todo});

  @override
  _PomodoroScreenState createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  Timer? _timer;
  PomodoroMode _currentMode = PomodoroMode.pomodoro;
  int _minutes = 5;
  int _seconds = 0;
  int _cyclesCompleted = 0;
  final int _maxCycles = 4; // Total cycles: work + break
  bool _isPaused = false;
  bool _isMuted = false;
  String _selectedsound = '';
  String _selectedalarm = 'cat';
  String _text = 'Pause';
  int _podoromotime = 25;
  int _breaktime = 5;
  int _longbreaktime = 30;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _alarmPlayer = AudioPlayer();
  @override
  void initState() {
    super.initState();
    loadPomodoroSettings();
    //  loadPomodoroSettings();
    if (widget.todo != null) {
      _startTimer();
      // _playRelaxingSound(); // Play sound when timer starts
    }
    _minutes = _podoromotime;
  }

  void _playRelaxingSound() async {
    try {
      if (_selectedsound == '') {
        setState(() {
          _selectedsound = 'rain';
        });
      }
      _audioPlayer.audioCache.prefix = 'lib/assets/audio/';
      _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      _audioPlayer.setReleaseMode(ReleaseMode.loop);
      _isMuted = false;
      _audioPlayer.play(AssetSource('$_selectedsound.mp3'),
          volume: 0.4, mode: PlayerMode.lowLatency);
      _audioPlayer.audioCache.clearAll();
      //  aait _audioPlayer.play(AssetSource("lib/assets/audio/coffeeshop.mp3"));
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  Future<void> loadPomodoroSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _podoromotime =
        prefs.getInt('pomodoro_time') ?? 25; // default to 25 if not set
    _breaktime = prefs.getInt('break_time') ?? 5; // default to 5 if not set
    _longbreaktime =
        prefs.getInt('long_break_time') ?? 30; // default to 30 if not set

    setState(() {
      _minutes =
          _podoromotime; // Set initial minutes based on loaded pomodoro time
    });
  }

  void _startTimer() {
    const oneSecond = Duration(seconds: 1);

    // Only play relaxing sound in Pomodoro work mode
    if (_currentMode == PomodoroMode.pomodoro) {
      _playRelaxingSound();
    }

    _timer = Timer.periodic(oneSecond, (timer) {
      if (!_isPaused) {
        setState(() {
          if (_seconds > 0) {
            _seconds--;
          } else {
            if (_minutes > 0) {
              _minutes--;
              _seconds = 59;
            } else {
              _nextCycle();
            }
          }
        });
      }
    });
  }

  void _startAlarm() {
    try {
      if (_selectedalarm == '') {
        setState(() {
          _selectedalarm = 'cat';
        });
      }
      _alarmPlayer.audioCache.prefix = 'lib/assets/audio/';
      _alarmPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      _alarmPlayer.setReleaseMode(ReleaseMode.loop);
      _isMuted = false;
      _alarmPlayer.play(AssetSource('$_selectedalarm.mp3'),
          volume: 0.4, mode: PlayerMode.lowLatency);

      Timer(Duration(seconds: 5), () {
        _alarmPlayer.stop();
      });
      _alarmPlayer.audioCache.clearAll();
      //  aait _audioPlayer.play(AssetSource("lib/assets/audio/coffeeshop.mp3"));
    } catch (e) {
      print('Error playing audio: $e');
    }
    //_nextCycle();
  }

  void _nextCycle() {
    setState(() {
      switch (_currentMode) {
        case PomodoroMode.pomodoro:
          _cyclesCompleted++;
          if (_isWorkTime()) {
            if (_cyclesCompleted >= _maxCycles) {
              _currentMode = PomodoroMode.longBreak;
              _timer?.cancel();
              _audioPlayer.pause(); // Pause the background sound
              _startAlarm();
              setState(() {
                _isPaused = true;
              }); // Start the alarm for the break period
              _minutes = _longbreaktime;
              setState(() {
                _text = 'Start';
              });
              // Set time for long break
              // _cyclesCompleted = 0; // Reset cycles after long break
            } else {
              _currentMode = PomodoroMode.breakMode;
              _timer?.cancel();
              _audioPlayer.pause(); // Pause the background sound
              _startAlarm();
              setState(() {
                _isPaused = true;
              }); // Start the alarm for the break period
              _minutes = _breaktime;
              setState(() {
                _text = 'Start';
              });
            }
            // Set time for break
          } else {
            _currentMode = PomodoroMode.pomodoro;
            _audioPlayer.resume(); // Resume the background sound
            _stopAlarm(); // Stop the alarm sound
            _minutes = _breaktime;
            setState(() {
              _text = 'Start';
            });
            // Set time for Pomodoro work period
          }

          break;
        case PomodoroMode.breakMode:
          _currentMode = PomodoroMode.pomodoro;
          _timer?.cancel();
          _audioPlayer.pause(); // Pause the background sound
          _startAlarm();
          setState(() {
            _isPaused = true;
          });
          //_audioPlayer.resume(); // Resume the background sound
          //_stopAlarm(); // Stop the alarm sound
          _minutes = _podoromotime;
          setState(() {
            _text = 'Start';
          });
          // Set time for Pomodoro work period
          break;
        case PomodoroMode.longBreak:
          _cyclesCompleted = 0;
          _currentMode = PomodoroMode.pomodoro;
          _timer?.cancel();
          _audioPlayer.pause(); // Pause the background sound
          _startAlarm();
          setState(() {
            _isPaused = true;
          });
          //_audioPlayer.resume(); // Resume the background sound
          //_stopAlarm(); // Stop the alarm sound
          _minutes = _podoromotime;
          setState(() {
            _text = 'Start';
          });
      }
      _seconds = 0;
    });
  }

  void _stopAlarm() {
    _alarmPlayer.stop(); // Stop the alarm sound
  }

  void _togglePauseResume() {
    setState(() {
      _isPaused = !_isPaused;
    });
    _text == 'Start'
        ? setState(() {
            _text = 'Pause';
          })
        : _text == 'Resume'
            ? setState(() {
                _text = 'Pause';
              })
            : _text == 'Pause'
                ? setState(() {
                    _text = 'Resume';
                  })
                : '';

    if (_isPaused) {
      _audioPlayer.pause(); // Pause sound when paused
      _timer?.cancel(); // Pause the timer
    } else {
      if (_currentMode == PomodoroMode.pomodoro) {
        // Resume sound when unpaused
        // Resum
        _audioPlayer.resume();
      }
      _startTimer(); // Resume the timer
    }
  }

  void toggleSettings(BuildContext context) async {
    showShadSheet(
      side: ShadSheetSide.bottom,
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return soundSetting(ctx, setState);
          },
        );
      },
    );
  }

  bool _isWorkTime() {
    return _currentMode == PomodoroMode.pomodoro && _minutes == 0;
  }

  void _switchMode(PomodoroMode mode) {
    setState(() {
      _currentMode = mode;
      _text = 'Pause';
      _isPaused =
          false; // Ensure that the timer is not paused when switching modes
      switch (mode) {
        case PomodoroMode.pomodoro:
          _timer?.cancel();
          _minutes = _podoromotime;
          _audioPlayer.resume();
          break;
        case PomodoroMode.breakMode:
          _timer?.cancel();
          _audioPlayer.pause(); // Pause the background sound
          //_startAlarm();
          _minutes = _breaktime;
          break;
        case PomodoroMode.longBreak:
          _timer?.cancel();
          _minutes = _longbreaktime;
          _audioPlayer.pause();
          // _startAlarm(); // Start alarm for the long break period
          break;
      }
      _seconds = 0;
    });

    // Start the timer automatically when switching modes
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(LucideIcons.circleX,color: ShadTheme.of(context).colorScheme.mutedForeground),

            onPressed: () => Navigator.of(context).pop(),
          ),
    //      title: Text('Pomodoro Timer'),
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Let's focusing on",
                      style: ShadTheme.of(context).textTheme.muted,
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.todo.text,
                      maxLines: 2,
                      overflow: TextOverflow.fade,
                      style: ShadTheme.of(context).textTheme.h4,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildModeButton(
                                  'Pomodoro', PomodoroMode.pomodoro),
                              SizedBox(height: 8),
                              Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Icon(
                                        _cyclesCompleted == 0
                                            ? LucideIcons.circle
                                            : Icons.circle,
                                        color: _cyclesCompleted >= 0
                                            ? ShadTheme.of(context)
                                                .colorScheme
                                                .primary
                                            : ShadTheme.of(context)
                                                .colorScheme
                                                .muted,
                                        size: 16),
                                    //   Icon(LucideIcons.circle, color: ShadTheme.of(context).colorScheme.primary, size: 10):
                                    //   Icon(Icons.circle, color: ShadTheme.of(context).colorScheme.primary, size: 10),
                                    // Text("•", style: TextStyle(
                                    //   fontSize: 40,
                                    //   color: _cyclesCompleted > 0? Colors.black : Colors.grey
                                    //   )),
                                    //  Icon(Icons.circle, color: ShadTheme.of(context).colorScheme.primary, size: 10),
                                    Icon(
                                        _cyclesCompleted == 1
                                            ? LucideIcons.circle
                                            : Icons.circle,
                                        color: _cyclesCompleted >= 1
                                            ? ShadTheme.of(context)
                                                .colorScheme
                                                .primary
                                            : ShadTheme.of(context)
                                                .colorScheme
                                                .muted,
                                        size: 16),
                                    Icon(
                                        _cyclesCompleted == 2
                                            ? LucideIcons.circle
                                            : Icons.circle,
                                        color: _cyclesCompleted >= 2
                                            ? ShadTheme.of(context)
                                                .colorScheme
                                                .primary
                                            : ShadTheme.of(context)
                                                .colorScheme
                                                .muted,
                                        size: 16),
                                    Icon(
                                        _cyclesCompleted == 3
                                            ? LucideIcons.circle
                                            : Icons.circle,
                                        color: _cyclesCompleted >= 3
                                            ? ShadTheme.of(context)
                                                .colorScheme
                                                .primary
                                            : ShadTheme.of(context)
                                                .colorScheme
                                                .muted,
                                        size: 16),
                                  ])
                            ]),
                        _buildModeButton('Break', PomodoroMode.breakMode),
                        _buildModeButton('Long Break', PomodoroMode.longBreak),
                      ],
                    ),
                    //    SizedBox(height: 16),
                    Text(
                      '$_minutes:${_seconds.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 80.0,
                        fontWeight: FontWeight.bold,
                        fontFamily:
                            ShadTheme.of(context).textTheme.h1.fontFamily,
                      ), // ShadTheme.of(context).textTheme.h1,
                    ),
                    SizedBox(height: 16),
                    ShadButton(
                      onPressed: _togglePauseResume,
                      child: Text(_text),

                      //  text: Text('Pause'),
                    ),
                    SizedBox(height: 42),
                    ShadButton.outline(
                      onPressed: () => toggleSettings(context),
                      icon: Icon(LucideIcons.music, size: 20),
                      //  text: Text('Pause'),
                    ),
                    // Text('$_cyclesCompleted')
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton(String text, PomodoroMode mode) {
    return ShadButton(
      onPressed: () => _switchMode(mode),
      size: ShadButtonSize.sm,
      backgroundColor: _currentMode == mode
          ? ShadTheme.of(context).colorScheme.primary
          : ShadTheme.of(context).colorScheme.muted,
      foregroundColor: _currentMode == mode
          ? ShadTheme.of(context).colorScheme.primaryForeground
          : ShadTheme.of(context).colorScheme.mutedForeground,
      child: Text(text),
    );
  }

  Widget soundSetting(BuildContext context, Function setState) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 350),
      child: ShadSheet(
        radius: BorderRadius.circular(16),
        closeIcon: SizedBox.shrink(),
        constraints: const BoxConstraints(maxWidth: 350),
        child: Container(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Alarm sound section
              Text("Alarm sound", style: ShadTheme.of(context).textTheme.muted),
              SizedBox(height: 8),
              Row(
                children: [
                  ShadButton(
                    backgroundColor: _selectedalarm == 'cat'
                        ? ShadTheme.of(context).colorScheme.primary
                        : ShadTheme.of(context).colorScheme.muted,
                    foregroundColor: _selectedalarm == 'cat'
                        ? ShadTheme.of(context).colorScheme.primaryForeground
                        : ShadTheme.of(context).colorScheme.mutedForeground,
                    onPressed: () {
                      setState(() {
                        _selectedalarm = 'cat';
                        _startAlarm();
                      });
                    },
                    icon: Icon(LucideIcons.cat, size: 20),
                  ),
                  ShadButton(
                    backgroundColor: _selectedalarm == 'bird'
                        ? ShadTheme.of(context).colorScheme.primary
                        : ShadTheme.of(context).colorScheme.muted,
                    foregroundColor: _selectedalarm == 'bird'
                        ? ShadTheme.of(context).colorScheme.primaryForeground
                        : ShadTheme.of(context).colorScheme.mutedForeground,
                    onPressed: () {
                      setState(() {
                        _selectedalarm = 'bird';
                        _startAlarm();
                      });
                    },
                    icon: Icon(LucideIcons.bird, size: 20),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Background sound section
              Text("Background sound",
                  style: ShadTheme.of(context).textTheme.muted),
              //   Text(_selectedsound, style: ShadTheme.of(context).textTheme.muted),
              SizedBox(height: 8),
              Row(
                children: [
                  ShadButton(
                    backgroundColor: _isMuted
                        ? ShadTheme.of(context).colorScheme.primary
                        : ShadTheme.of(context).colorScheme.muted,
                    foregroundColor: _isMuted
                        ? ShadTheme.of(context).colorScheme.primaryForeground
                        : ShadTheme.of(context).colorScheme.mutedForeground,
                    onPressed: () {
                      setState(() {
                        _isMuted = !_isMuted;
                        if (_isMuted) {
                          _audioPlayer.pause();
                        } else {
                          _audioPlayer.resume();
                        }
                      });
                    },
                    icon: Icon(LucideIcons.volumeX, size: 20),
                  ),
                  ShadButton(
                    backgroundColor: _selectedsound == 'coffeeshop'
                        ? ShadTheme.of(context).colorScheme.primary
                        : ShadTheme.of(context).colorScheme.muted,
                    foregroundColor: _selectedsound == 'coffeeshop'
                        ? ShadTheme.of(context).colorScheme.primaryForeground
                        : ShadTheme.of(context).colorScheme.mutedForeground,
                    onPressed: () {
                      setState(() {
                        _selectedsound = 'coffeeshop';
                        _playRelaxingSound();
                      });
                    },
                    icon: Icon(LucideIcons.coffee, size: 20),
                  ),
                  ShadButton.outline(
                    backgroundColor: _selectedsound == 'rain'
                        ? ShadTheme.of(context).colorScheme.primary
                        : ShadTheme.of(context).colorScheme.muted,
                    foregroundColor: _selectedsound == 'rain'
                        ? ShadTheme.of(context).colorScheme.primaryForeground
                        : ShadTheme.of(context).colorScheme.mutedForeground,
                    icon: Icon(LucideIcons.cloudRain, size: 20),
                    onPressed: () {
                      setState(() {
                        _selectedsound = 'rain';
                        _playRelaxingSound();
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  ProgressPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw background circle (full circle)
    canvas.drawCircle(size.center(Offset.zero), size.width / 2, paint);

    // Draw arc (semi-circle) representing progress
    canvas.drawArc(
      Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2),
      -pi / 2, // Start angle (top)
      pi * progress, // Sweep angle based on progress
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

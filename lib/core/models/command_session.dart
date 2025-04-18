import 'package:devkick/core/models/command.dart';

class CommandSession {
  final String id;
  final Command command;
  final String output;
  final String error;
  final int exitCode;
  final bool isRunning;
  final DateTime startTime;

  CommandSession({
    required this.id,
    required this.command,
    this.output = '',
    this.error = '',
    this.exitCode = 0,
    this.isRunning = true,
    DateTime? startTime,
  }) : startTime = startTime ?? DateTime.now();

  CommandSession copyWith({
    String? id,
    Command? command,
    String? output,
    String? error,
    int? exitCode,
    bool? isRunning,
    DateTime? startTime,
  }) {
    return CommandSession(
      id: id ?? this.id,
      command: command ?? this.command,
      output: output ?? this.output,
      error: error ?? this.error,
      exitCode: exitCode ?? this.exitCode,
      isRunning: isRunning ?? this.isRunning,
      startTime: startTime ?? this.startTime,
    );
  }
} 
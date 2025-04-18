import 'package:flutter/material.dart';
import 'package:devkick/core/models/command.dart';
import 'package:uuid/uuid.dart';

class Routine {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final List<Command> commands;
  final bool runInParallel;

  Routine({
    String? id,
    required this.name,
    required this.description,
    required this.icon,
    required this.commands,
    this.runInParallel = false,
  }) : id = id ?? const Uuid().v4();

  factory Routine.fromJson(Map<String, dynamic> json) {
    final commandsJson = json['commands'] as List<dynamic>;
    final commands = commandsJson.map((commandJson) => 
      Command.fromJson(commandJson)).toList();
      
    return Routine(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: IconData(
        json['iconCodePoint'] as int,
        fontFamily: json['iconFontFamily'] as String?,
        fontPackage: json['iconFontPackage'] as String?,
      ),
      commands: commands,
      runInParallel: json['runInParallel'] as bool? ?? json['parallelExecution'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'runInParallel': runInParallel,
      'commands': commands.map((command) => command.toJson()).toList(),
    };
  }

  Routine copyWith({
    String? id,
    String? name,
    String? description,
    IconData? icon,
    List<Command>? commands,
    bool? runInParallel,
  }) {
    return Routine(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      commands: commands ?? this.commands,
      runInParallel: runInParallel ?? this.runInParallel,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Routine && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 
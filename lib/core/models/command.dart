import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Terminal type for command execution
enum TerminalType {
  prompt,
  bash,
  powershell,
}

/// Unified Command model that combines all properties from previous CommandItem and CommandListItem
class Command {
  final String id;
  final String label;
  final String command;
  final String category;
  final IconData icon;
  final bool showTerminalOutput;
  final TerminalType terminalType;

  Command({
    String? id,
    required this.label,
    required this.command,
    required this.category,
    required this.icon,
    this.showTerminalOutput = true,
    this.terminalType = TerminalType.prompt,
  }) : id = id ?? const Uuid().v4();

  /// Create a command from JSON data
  factory Command.fromJson(Map<String, dynamic> json) {
    return Command(
      id: json['id'] as String? ?? const Uuid().v4(),
      label: json['label'] as String,
      command: json['command'] as String? ?? json['commandInput'] as String,
      category: json['category'] as String? ?? 'General',
      icon: IconData(
        json['iconCodePoint'] as int? ?? json['icon'] as int,
        fontFamily: json['iconFontFamily'] as String?,
        fontPackage: json['iconFontPackage'] as String?,
      ),
      showTerminalOutput: json['showTerminalOutput'] as bool? ?? json['showTerminal'] as bool? ?? true,
      terminalType: json['terminalType'] != null 
          ? TerminalType.values[json['terminalType'] as int] 
          : TerminalType.prompt,
    );
  }

  /// Create a copy of Command with optional property changes 
  Command copyWith({
    String? label,
    String? command,
    String? category,
    IconData? icon,
    bool? showTerminalOutput,
    TerminalType? terminalType,
  }) {
    return Command(
      id: id,
      label: label ?? this.label,
      command: command ?? this.command,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      showTerminalOutput: showTerminalOutput ?? this.showTerminalOutput,
      terminalType: terminalType ?? this.terminalType,
    );
  }

  /// Convert Command to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'command': command,
      'category': category,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'showTerminalOutput': showTerminalOutput,
      'terminalType': terminalType.index,
    };
  }

  /// Convert from old CommandItem
  factory Command.fromCommandItem(dynamic item) {
    if (item is Command) return item;
    
    return Command(
      id: item.id,
      label: item.label,
      command: item.commandInput ?? item.command,
      category: item.category,
      icon: item.icon,
      showTerminalOutput: item.showTerminalOutput ?? item.showTerminal ?? true,
      terminalType: item.terminalType ?? TerminalType.prompt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Command && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devkick/core/models/command.dart';

class SettingsService {
  // Keys for SharedPreferences
  static const String _promptPathKey = 'promptPath';
  static const String _bashPathKey = 'bashPath';
  static const String _powershellPathKey = 'powershellPath';

  // Default paths for terminals
  static const String _defaultPromptPath = 'cmd.exe';
  static const String _defaultBashPath = 'C:\\Program Files\\Git\\bin\\bash.exe';
  static const String _defaultPowershellPath = 'powershell.exe';

  // In-memory cache of settings
  static String? _promptPath;
  static String? _bashPath;
  static String? _powershellPath;

  // Initialize settings from SharedPreferences
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    _promptPath = prefs.getString(_promptPathKey) ?? _defaultPromptPath;
    _bashPath = prefs.getString(_bashPathKey) ?? _defaultBashPath;
    _powershellPath = prefs.getString(_powershellPathKey) ?? _defaultPowershellPath;
    
    debugPrint('Settings initialized: prompt=$_promptPath, bash=$_bashPath, powershell=$_powershellPath');
  }

  // Get terminal path based on type
  static Future<String> getTerminalPath(TerminalType type) async {
    // Make sure settings are initialized
    if (_promptPath == null) {
      await init();
    }
    
    switch (type) {
      case TerminalType.prompt:
        return _promptPath!;
      case TerminalType.bash:
        return _bashPath!;
      case TerminalType.powershell:
        return _powershellPath!;
    }
  }

  // Save a terminal path
  static Future<bool> saveTerminalPath(TerminalType type, String path) async {
    final prefs = await SharedPreferences.getInstance();
    
    switch (type) {
      case TerminalType.prompt:
        _promptPath = path;
        return prefs.setString(_promptPathKey, path);
      case TerminalType.bash:
        _bashPath = path;
        return prefs.setString(_bashPathKey, path);
      case TerminalType.powershell:
        _powershellPath = path;
        return prefs.setString(_powershellPathKey, path);
    }
  }

  // Reset terminal paths to default values
  static Future<bool> resetTerminalPaths() async {
    final prefs = await SharedPreferences.getInstance();
    
    _promptPath = _defaultPromptPath;
    _bashPath = _defaultBashPath;
    _powershellPath = _defaultPowershellPath;
    
    return await prefs.setString(_promptPathKey, _defaultPromptPath) &&
           await prefs.setString(_bashPathKey, _defaultBashPath) &&
           await prefs.setString(_powershellPathKey, _defaultPowershellPath);
  }
  
  // Get current path of a terminal type
  static String getCurrentPath(TerminalType type) {
    // Make sure settings are initialized (synchronous version)
    if (_promptPath == null) {
      return _getDefaultPath(type);
    }
    
    switch (type) {
      case TerminalType.prompt:
        return _promptPath!;
      case TerminalType.bash:
        return _bashPath!;
      case TerminalType.powershell:
        return _powershellPath!;
    }
  }
  
  // Get default path of a terminal type
  static String _getDefaultPath(TerminalType type) {
    switch (type) {
      case TerminalType.prompt:
        return _defaultPromptPath;
      case TerminalType.bash:
        return _defaultBashPath;
      case TerminalType.powershell:
        return _defaultPowershellPath;
    }
  }
  
  // Get terminal type name for display
  static String getTerminalTypeName(TerminalType type) {
    switch (type) {
      case TerminalType.prompt:
        return 'Command Prompt';
      case TerminalType.bash:
        return 'Bash';
      case TerminalType.powershell:
        return 'PowerShell';
    }
  }
} 
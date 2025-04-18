import 'package:flutter/material.dart';
import 'package:devkick/core/constants/app_constants.dart';
import 'package:devkick/core/models/command.dart';
import 'package:devkick/core/services/settings_service.dart';
import 'package:devkick/core/services/backup_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _promptPathController = TextEditingController();
  final _bashPathController = TextEditingController();
  final _powershellPathController = TextEditingController();
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    // Initialize settings if needed
    await SettingsService.init();
    
    // Load current settings
    _promptPathController.text = SettingsService.getCurrentPath(TerminalType.prompt);
    _bashPathController.text = SettingsService.getCurrentPath(TerminalType.bash);
    _powershellPathController.text = SettingsService.getCurrentPath(TerminalType.powershell);
    
    setState(() {
      _isLoading = false;
    });
  }
  
  @override
  void dispose() {
    _promptPathController.dispose();
    _bashPathController.dispose();
    _powershellPathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Reset to defaults',
            onPressed: _confirmReset,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Terminal Paths Section
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Terminal Paths',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              
              // Prompt Path
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.terminal),
                          const SizedBox(width: 8),
                          Text(
                            'Command Prompt',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _promptPathController,
                        decoration: const InputDecoration(
                          labelText: 'Path to cmd.exe',
                          hintText: 'e.g., cmd.exe',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.folder_open),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a path';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              // Bash Path
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.code),
                          const SizedBox(width: 8),
                          Text(
                            'Bash',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bashPathController,
                        decoration: const InputDecoration(
                          labelText: 'Path to bash.exe',
                          hintText: 'e.g., C:\\Program Files\\Git\\bin\\bash.exe',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.folder_open),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a path';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              // PowerShell Path
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.window),
                          const SizedBox(width: 8),
                          Text(
                            'PowerShell',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _powershellPathController,
                        decoration: const InputDecoration(
                          labelText: 'Path to powershell.exe',
                          hintText: 'e.g., powershell.exe',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.folder_open),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a path';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              // Data Backup Section
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Data Backup',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.backup),
                          const SizedBox(width: 8),
                          Text(
                            'Backup & Restore',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Export your commands and routines for backup or import previously saved data.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.file_download),
                              label: const Text('Export Data'),
                              onPressed: _exportData,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.file_upload),
                              label: const Text('Import Data'),
                              onPressed: _importData,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _saveSettings,
                  child: const Text('Save Settings'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      // Save terminal paths
      await SettingsService.saveTerminalPath(
        TerminalType.prompt, 
        _promptPathController.text.trim()
      );
      
      await SettingsService.saveTerminalPath(
        TerminalType.bash, 
        _bashPathController.text.trim()
      );
      
      await SettingsService.saveTerminalPath(
        TerminalType.powershell, 
        _powershellPathController.text.trim()
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    }
  }
  
  void _confirmReset() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Terminal Paths'),
        content: const Text('Are you sure you want to reset all terminal paths to their default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetToDefaults();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _resetToDefaults() async {
    setState(() {
      _isLoading = true;
    });
    
    await SettingsService.resetTerminalPaths();
    await _loadSettings();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings reset to defaults')),
      );
    }
  }
  
  Future<void> _exportData() async {
    setState(() {
      _isLoading = true;
    });
    
    final filePath = await BackupService.exportData();
    
    setState(() {
      _isLoading = false;
    });
    
    if (mounted) {
      if (filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data exported to: $filePath')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export cancelled or failed')),
        );
      }
    }
  }
  
  Future<void> _importData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text(
          'Importing will add the commands and routines from the backup file to your current data. '
          'Existing items will be updated if they have the same ID. '
          'Continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    final success = await BackupService.importData();
    
    setState(() {
      _isLoading = false;
    });
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data imported successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Import cancelled or failed')),
        );
      }
    }
  }
} 
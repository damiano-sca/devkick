import 'package:flutter/material.dart';
import 'package:devkick/core/constants/app_constants.dart';
import 'package:devkick/core/constants/command_constants.dart';
import 'package:devkick/core/models/command.dart';
import 'package:devkick/core/services/settings_service.dart';
import 'package:devkick/core/services/toast_service.dart';

class AddCommandDialog extends StatefulWidget {
  const AddCommandDialog({super.key});

  @override
  State<AddCommandDialog> createState() => _AddCommandDialogState();
}

class _AddCommandDialogState extends State<AddCommandDialog> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _commandController = TextEditingController();
  final _categoryController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showTerminal = true;
  IconData _selectedIcon = Icons.code;
  String _selectedCategory = 'General';
  TerminalType _selectedTerminalType = TerminalType.prompt;

  @override
  void initState() {
    super.initState();
    _categoryController.text = _selectedCategory;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _commandController.dispose();
    _categoryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: MouseRegion(
        child: Container(
          width: 600,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fixed header
                Padding(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Row(
                    children: [
                      Icon(Icons.add, color: theme.colorScheme.primary),
                      const SizedBox(width: AppConstants.smallPadding),
                      Text(
                        'Add New Command',
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                
                // Scrollable content
                Flexible(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Command Label
                        TextFormField(
                          controller: _labelController,
                          decoration: const InputDecoration(
                            labelText: 'Label',
                            hintText: 'Enter a descriptive name for the command',
                            prefixIcon: Icon(Icons.label),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a label';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24), // Increased vertical spacing
                        
                        // Command
                        TextFormField(
                          controller: _commandController,
                          decoration: const InputDecoration(
                            labelText: 'Command',
                            hintText: 'Enter the command to execute',
                            prefixIcon: Icon(Icons.terminal),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a command';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24), // Increased vertical spacing
                        
                        // Terminal Type Selection
                        DropdownButtonFormField<TerminalType>(
                          value: _selectedTerminalType,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down),
                          menuMaxHeight: 350,
                          dropdownColor: theme.colorScheme.surface,
                          decoration: InputDecoration(
                            labelText: 'Terminal Type',
                            hintText: 'Select a terminal to run this command',
                            prefixIcon: Icon(
                              _getTerminalIcon(_selectedTerminalType),
                              color: theme.colorScheme.primary,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                            border: const OutlineInputBorder(),
                          ),
                          selectedItemBuilder: (BuildContext context) {
                            return TerminalType.values.map<Widget>((TerminalType terminalType) {
                              return Container(
                                alignment: Alignment.centerLeft,
                                constraints: const BoxConstraints(minHeight: 48),
                                child: Row(
                                  children: [
                                    Text(
                                      SettingsService.getTerminalTypeName(terminalType),
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              );
                            }).toList();
                          },
                          items: TerminalType.values.map((terminalType) {
                            final terminalName = SettingsService.getTerminalTypeName(terminalType);
                            
                            return DropdownMenuItem<TerminalType>(
                              value: terminalType,
                              child: Container(
                                constraints: const BoxConstraints(minHeight: 48),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 32,
                                      alignment: Alignment.center,
                                      child: Icon(_getTerminalIcon(terminalType), size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      terminalName,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedTerminalType = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 24), // Increased vertical spacing
                        
                        // Category Selection
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          dropdownColor: theme.colorScheme.surface,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            hintText: 'Select a category',
                            prefixIcon: Icon(Icons.category),
                            contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                            border: OutlineInputBorder(),
                          ),
                          selectedItemBuilder: (BuildContext context) {
                            return CommandConstants.predefinedCategories.map<Widget>((String category) {
                              return Container(
                                alignment: Alignment.centerLeft,
                                constraints: const BoxConstraints(minHeight: 48),
                                child: Text(category),
                              );
                            }).toList();
                          },
                          items: CommandConstants.predefinedCategories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Container(
                                constraints: const BoxConstraints(minHeight: 48),
                                child: Text(category),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedCategory = value;
                                _categoryController.text = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Custom Category Input
                        TextFormField(
                          controller: _categoryController,
                          decoration: const InputDecoration(
                            labelText: 'Custom Category (Optional)',
                            hintText: 'Or enter a custom category',
                            prefixIcon: Icon(Icons.edit),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            } else {
                              setState(() {
                                _selectedCategory = 'General';
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 24), // Increased vertical spacing
                        
                        // Icon Selection
                        Text(
                          'Select Icon',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppConstants.smallPadding),
                        Container(
                          height: 150, // Increased height to accommodate more icons
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: GridView.builder(
                            padding: const EdgeInsets.all(AppConstants.smallPadding),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 10,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                            ),
                            itemCount: CommandConstants.availableIcons.length,
                            itemBuilder: (context, index) {
                              final icon = CommandConstants.availableIcons[index];
                              final isSelected = icon == _selectedIcon;
                              
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedIcon = icon;
                                  });
                                },
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                      ? theme.colorScheme.primaryContainer 
                                      : null,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(
                                    icon,
                                    color: isSelected 
                                      ? theme.colorScheme.onPrimaryContainer 
                                      : theme.colorScheme.onSurface,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24), // Increased vertical spacing
                        
                        // Show Terminal Toggle
                        SwitchListTile(
                          title: const Text('Show Terminal'),
                          subtitle: const Text('Show the terminal output after running'),
                          value: _showTerminal,
                          onChanged: (value) {
                            setState(() {
                              _showTerminal = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Fixed footer
                Padding(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16, // Increased button height
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: AppConstants.smallPadding),
                      FilledButton(
                        onPressed: _saveCommand,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16, // Increased button height
                          ),
                        ),
                        child: const Text('Save Command'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getTerminalIcon(TerminalType terminalType) {
    switch (terminalType) {
      case TerminalType.prompt:
        return Icons.terminal;
      case TerminalType.bash:
        return Icons.code;
      case TerminalType.powershell:
        return Icons.window;
    }
  }

  void _saveCommand() {
    if (_formKey.currentState!.validate()) {
      String finalCategory = _categoryController.text.isNotEmpty 
          ? _categoryController.text.trim() 
          : _selectedCategory;
      
      final newCommand = Command(
        label: _labelController.text.trim(),
        command: _commandController.text.trim(),
        icon: _selectedIcon,
        showTerminalOutput: _showTerminal,
        category: finalCategory,
        terminalType: _selectedTerminalType,
      );
      
      Navigator.of(context).pop(newCommand);
    } else {
      // Show validation error message as toast
      ToastService.showError(context, 'Please fix the validation errors');
    }
  }
} 
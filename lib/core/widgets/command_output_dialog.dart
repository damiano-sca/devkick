import 'package:flutter/material.dart';
import 'package:devkick/core/constants/app_constants.dart';
import 'package:devkick/core/models/command.dart';
import 'package:devkick/core/services/settings_service.dart';

class CommandOutputDialog extends StatelessWidget {
  final String command;
  final String output;
  final String error;
  final int exitCode;
  final TerminalType terminalType;

  const CommandOutputDialog({
    super.key,
    required this.command,
    required this.output,
    required this.error,
    required this.exitCode,
    this.terminalType = TerminalType.prompt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = error.isNotEmpty;
    final terminalName = SettingsService.getTerminalTypeName(terminalType);
    
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasError ? Icons.error_outline : Icons.check_circle_outline,
                  color: hasError ? theme.colorScheme.error : theme.colorScheme.primary,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  'Command Output',
                  style: theme.textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: AppConstants.smallPadding),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppConstants.smallPadding),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '> $command',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _getTerminalIcon(terminalType), 
                  size: 16,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Terminal: $terminalName',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const Spacer(),
                Text(
                  'Exit code: $exitCode',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: exitCode == 0 ? theme.colorScheme.primary : theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppConstants.smallPadding),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (output.isNotEmpty) ...[
                        Text(
                          'Output:',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppConstants.smallPadding),
                        SelectableText(
                          output,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                      if (hasError) ...[
                        const SizedBox(height: AppConstants.defaultPadding),
                        Text(
                          'Error:',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: AppConstants.smallPadding),
                        SelectableText(
                          error,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
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
} 
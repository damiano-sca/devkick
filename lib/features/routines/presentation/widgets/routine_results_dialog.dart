import 'package:flutter/material.dart';
import 'package:devkick/core/constants/app_constants.dart';
import 'package:devkick/core/models/routine.dart';
import 'package:devkick/core/models/command.dart';
import 'package:devkick/core/models/process_result.dart';

class RoutineResultsDialog extends StatelessWidget {
  final Routine routine;
  final List<Map<Command, ProcessResult>> results;

  const RoutineResultsDialog({
    super.key,
    required this.routine,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(routine.icon, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Results: ${routine.name}',
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Command execution results:',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final resultEntry = results[index];
                    final command = resultEntry.keys.first;
                    final result = resultEntry.values.first;
                    
                    final bool hasError = result.exitCode != 0 || result.stderr.toString().isNotEmpty;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        leading: Icon(
                          command.icon,
                          color: hasError ? theme.colorScheme.error : null,
                        ),
                        title: Text(command.label),
                        subtitle: Text(
                          'Exit code: ${result.exitCode}${hasError ? ' (Error)' : ''}',
                          style: TextStyle(
                            color: hasError ? theme.colorScheme.error : null,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Command:',
                                  style: theme.textTheme.titleSmall,
                                ),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8),
                                  margin: const EdgeInsets.only(bottom: 8, top: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    command.command,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                if (result.stdout.toString().isNotEmpty) ...[
                                  Text(
                                    'Output:',
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    margin: const EdgeInsets.only(bottom: 8, top: 4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    constraints: const BoxConstraints(maxHeight: 200),
                                    child: SingleChildScrollView(
                                      child: Text(
                                        result.stdout.toString(),
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                if (result.stderr.toString().isNotEmpty) ...[
                                  Text(
                                    'Error:',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    margin: const EdgeInsets.only(top: 4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.errorContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    constraints: const BoxConstraints(maxHeight: 200),
                                    child: SingleChildScrollView(
                                      child: Text(
                                        result.stderr.toString(),
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontFamily: 'monospace',
                                          color: theme.colorScheme.onErrorContainer,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
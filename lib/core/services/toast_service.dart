import 'package:flutter/material.dart';

/// Service to display toast notifications in the app
class ToastService {
  /// Shows a toast message in the center of the screen
  static void show(
    BuildContext context, 
    String message, {
    Duration duration = const Duration(seconds: 2),
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
  }) {
    // Remove any existing toast
    _removeToast();
    
    // Create an overlay entry
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHighest,
        textColor: textColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
        icon: icon,
      ),
    );
    
    // Show the overlay and remove after duration
    _currentToast = overlayEntry;
    overlay.insert(overlayEntry);
    
    Future.delayed(duration, () {
      _removeToast();
    });
  }
  
  /// Shows a success toast
  static void showSuccess(BuildContext context, String message) {
    show(
      context, 
      message,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      textColor: Theme.of(context).colorScheme.onPrimaryContainer,
      icon: Icons.check_circle,
    );
  }
  
  /// Shows an error toast
  static void showError(BuildContext context, String message) {
    show(
      context, 
      message,
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
      textColor: Theme.of(context).colorScheme.onErrorContainer,
      icon: Icons.error,
    );
  }
  
  /// Shows an info toast
  static void showInfo(BuildContext context, String message) {
    show(
      context, 
      message,
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      textColor: Theme.of(context).colorScheme.onSecondaryContainer,
      icon: Icons.info,
    );
  }
  
  /// Current toast entry, if any
  static OverlayEntry? _currentToast;
  
  /// Remove the current toast if it exists
  static void _removeToast() {
    _currentToast?.remove();
    _currentToast = null;
  }
}

/// Widget that shows the toast message
class _ToastWidget extends StatelessWidget {
  final String message;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;
  
  const _ToastWidget({
    required this.message,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.1,
      width: MediaQuery.of(context).size.width,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: textColor),
                  const SizedBox(width: 12),
                ],
                Flexible(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 
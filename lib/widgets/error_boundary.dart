import 'package:flutter/material.dart';
import 'package:findora/services/analytics_service.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget Function(BuildContext context) builder;
  final String screenName;

  const ErrorBoundary({
    super.key,
    required this.builder,
    required this.screenName,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildFallback(context);
    }

    try {
      return widget.builder(context);
    } catch (error, stackTrace) {
      _reportError(error, stackTrace);
      return _buildFallback(context);
    }
  }

  void _reportError(Object error, StackTrace stackTrace) {
    _error = error;
    AnalyticsService.logAction('error_${widget.screenName.toLowerCase()}');
    debugPrint(
      'ErrorBoundary caught error in ${widget.screenName}: $error\n$stackTrace',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Widget _buildFallback(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text(widget.screenName),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 72,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 20),
              const Text(
                'Something went wrong.',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Please try again or return to the previous screen.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _retry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                ),
                child: const Text('Retry'),
              ),
              const SizedBox(height: 12),
              Text(
                _error?.toString() ?? '',
                style: const TextStyle(fontSize: 12, color: Colors.black45),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _retry() {
    setState(() {
      _error = null;
    });
  }
}

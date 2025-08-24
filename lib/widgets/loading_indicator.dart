import 'package:flutter/material.dart';
import 'enhanced_loading_widget.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;

  const LoadingIndicator({
    super.key,
    this.message,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedLoadingWidget(
      message: message,
      size: size,
      color: color,
    );
  }
}

class FullScreenLoader extends StatelessWidget {
  final String? message;

  const FullScreenLoader({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: BlockchainLoadingWidget(
            message: message ?? 'Processing...',
            size: 60,
          ),
        ),
      ),
    );
  }
}

class CardLoader extends StatelessWidget {
  final double height;

  const CardLoader({
    super.key,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        height: height,
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: BlockchainLoadingWidget(
            message: 'Loading blockchain data...',
          ),
        ),
      ),
    );
  }
}
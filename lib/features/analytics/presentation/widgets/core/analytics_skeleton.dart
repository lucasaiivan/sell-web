import 'package:flutter/material.dart';
import 'shimmer_widget.dart';

/// Widget: Skeleton Loading para Analytics
///
/// **Responsabilidad:**
/// - Mostrar placeholder animado durante carga inicial
/// - Adaptar diseño según breakpoint (mobile/tablet/desktop)
class AnalyticsSkeleton extends StatelessWidget {
  const AnalyticsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        if (screenWidth < 600) {
          return _buildMobileSkeleton(context);
        } else if (screenWidth < 900) {
          return _buildTabletSkeleton(context);
        } else {
          return _buildDesktopSkeleton(context);
        }
      },
    );
  }

  Widget _buildMobileSkeleton(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final gap = (screenWidth * 0.025).clamp(8.0, 16.0);
    final primaryHeight = (screenWidth * 0.38).clamp(120.0, 180.0);
    final secondaryHeight = (screenWidth * 0.32).clamp(100.0, 150.0);
    final tertiaryHeight = (screenWidth * 0.42).clamp(130.0, 190.0);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SkeletonCard(height: primaryHeight),
          SizedBox(height: gap),
          Row(
            children: [
              Expanded(child: _SkeletonCard(height: secondaryHeight)),
              SizedBox(width: gap),
              Expanded(child: _SkeletonCard(height: secondaryHeight)),
            ],
          ),
          SizedBox(height: gap),
          Row(
            children: [
              Expanded(child: _SkeletonCard(height: tertiaryHeight)),
              SizedBox(width: gap),
              Expanded(child: _SkeletonCard(height: tertiaryHeight)),
            ],
          ),
          SizedBox(height: gap),
          _SkeletonCard(height: tertiaryHeight),
          SizedBox(height: gap),
          Row(
            children: [
              Expanded(child: _SkeletonCard(height: tertiaryHeight)),
              SizedBox(width: gap),
              Expanded(child: _SkeletonCard(height: tertiaryHeight)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabletSkeleton(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = (screenWidth - 32 - 36).clamp(0.0, 900.0 - 36);
    final cellSize = availableWidth / 4;
    final gap = (screenWidth * 0.015).clamp(8.0, 12.0);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _SkeletonCard(height: cellSize * 1.6),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _SkeletonCard(height: cellSize * 0.75),
                        SizedBox(height: gap),
                        Row(
                          children: [
                            Expanded(
                                child: _SkeletonCard(height: cellSize * 0.85)),
                            SizedBox(width: gap),
                            Expanded(
                                child: _SkeletonCard(height: cellSize * 0.85)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: gap),
              Row(
                children: [
                  Expanded(child: _SkeletonCard(height: cellSize * 0.85)),
                  SizedBox(width: gap),
                  Expanded(child: _SkeletonCard(height: cellSize * 0.85)),
                ],
              ),
              SizedBox(height: gap),
              Row(
                children: [
                  Expanded(child: _SkeletonCard(height: cellSize * 0.85)),
                  SizedBox(width: gap),
                  Expanded(child: _SkeletonCard(height: cellSize * 0.85)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopSkeleton(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = (screenWidth - 32 - 60).clamp(0.0, 1400.0 - 60);
    final cellSize = availableWidth / 6;
    final gap = (screenWidth * 0.01).clamp(10.0, 14.0);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _SkeletonCard(height: cellSize * 1.5),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _SkeletonCard(height: cellSize * 0.7),
                        SizedBox(height: gap),
                        _SkeletonCard(height: cellSize * 0.8),
                      ],
                    ),
                  ),
                  SizedBox(width: gap),
                  Expanded(child: _SkeletonCard(height: cellSize * 1.5)),
                  SizedBox(width: gap),
                  Expanded(child: _SkeletonCard(height: cellSize * 1.5)),
                ],
              ),
              SizedBox(height: gap),
              Row(
                children: [
                  Expanded(child: _SkeletonCard(height: cellSize * 0.8)),
                  SizedBox(width: gap),
                  Expanded(child: _SkeletonCard(height: cellSize * 0.8)),
                  SizedBox(width: gap),
                  Expanded(child: _SkeletonCard(height: cellSize * 0.8)),
                ],
              ),
              SizedBox(height: gap),
              Row(
                children: [
                  Expanded(child: _SkeletonCard(height: cellSize * 0.8)),
                  SizedBox(width: gap),
                  Expanded(child: _SkeletonCard(height: cellSize * 0.8)),
                  SizedBox(width: gap),
                  Expanded(child: _SkeletonCard(height: cellSize * 0.8)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card skeleton individual con shimmer
class _SkeletonCard extends StatelessWidget {
  final double height;

  const _SkeletonCard({required this.height});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ShimmerWidget(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 14,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 120,
              height: 28,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const Spacer(),
            Container(
              width: 60,
              height: 12,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

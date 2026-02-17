import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:sellweb/core/presentation/widgets/ui/avatar.dart';
import '../providers/catalogue_provider.dart';

class BrandStoriesList extends StatelessWidget {
  final List<BrandInfo> brands;
  final String? selectedBrandId;
  final Function(String brandId, String brandName) onBrandTap;

  const BrandStoriesList({
    super.key,
    required this.brands,
    this.selectedBrandId,
    required this.onBrandTap,
  });

  @override
  Widget build(BuildContext context) {
    if (brands.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 100,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          },
        ),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          scrollDirection: Axis.horizontal,
          itemCount: brands.length,
          separatorBuilder: (context, index) => const SizedBox(width: 16),
          itemBuilder: (context, index) {
            final brand = brands[index];
            final isSelected = brand.id == selectedBrandId;
            
            return _BrandStoryItem(
              brand: brand,
              isSelected: isSelected,
              onTap: () => onBrandTap(brand.id, brand.name),
            );
          },
        ),
      ),
    );
  }
}

class _BrandStoryItem extends StatelessWidget {
  final BrandInfo brand;
  final bool isSelected;
  final VoidCallback onTap;

  const _BrandStoryItem({
    required this.brand,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? colorScheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(2), // Espacio entre borde y avatar
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent, 
              ),
              child: AvatarItem(
                imageUrl: brand.image,
                name: brand.name,
                radius: 30, // Tamaño de historia parecido a Instagram
                backgroundColor: colorScheme.surfaceContainerHighest,
                textStyle: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 70, // Ancho limitado para texto
            child: Text(
              brand.name,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

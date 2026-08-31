import 'package:flutter/material.dart';
import 'package:wr_pmis_mobile/src/core/constants/app_assets.dart';

/// In-app Synergiz product mark (not client / railway org logos).
class ProductBrandIcon extends StatelessWidget {
  const ProductBrandIcon({
    super.key,
    this.size = 44,
    this.circular = false,
    this.borderRadius = 12,
  });

  final double size;
  final bool circular;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final Widget image = Image.asset(
      AppAssets.uiProductIcon,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Icon(
        Icons.dashboard_customize_outlined,
        size: size * 0.55,
        color: Theme.of(context).colorScheme.primary,
      ),
    );

    if (circular) {
      return ClipOval(child: image);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: image,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/brand_assets.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.height = 32,
    this.color,
  });

  final double? height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    const path = BrandAssets.logo;
    final isSvg = path.toLowerCase().endsWith('.svg');

    if (isSvg) {
      return SvgPicture.asset(
        path,
        height: height,
        colorFilter: color != null
            ? ColorFilter.mode(color!, BlendMode.srcIn)
            : null,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => SizedBox(
          height: height,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
        ),
      );
    }

    return Image.asset(
      path,
      height: height,
      color: color,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Text(
        'Artihcus',
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}


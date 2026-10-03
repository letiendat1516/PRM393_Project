import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

enum BrandVariant { dark, light }

/// components/ui/Brand.jsx — JobHub logo.
///
/// Uses the brand artwork supplied by the team (assets/icons/logo_jobhub.svg,
/// pre-rendered to PNG by docs/gen_logo_assets.py because the SVG relies on
/// masks/filters flutter_svg does not support):
/// - full logo (J mark + "JobHub." wordmark): `assets/images/logo_jobhub.png`
/// - light variant for the blue auth panel: `assets/images/logo_jobhub_white.png`
/// - compact mark only: `assets/images/logo_mark@4x.png`
///
/// [size] keeps the old API: the rendered height is `size + 14` (36 px in the
/// navbar), the wordmark aspect ratio comes from the asset itself.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.variant = BrandVariant.dark,
    this.compact = false,
    this.size = 22,
  });
  final BrandVariant variant;
  final bool compact;
  final double size;

  static const fullAsset = 'assets/images/logo_jobhub.png';
  static const fullAssetLight = 'assets/images/logo_jobhub_white.png';
  static const markAsset = 'assets/images/logo_mark@4x.png';

  @override
  Widget build(BuildContext context) {
    final isLight = variant == BrandVariant.light;
    final height = size + 14;

    if (compact) {
      return SizedBox(
        width: height,
        height: height,
        child: Image.asset(
          markAsset,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          color: isLight ? Colors.white : null,
          errorBuilder: (_, _, _) => _fallbackMark(isLight, height),
        ),
      );
    }

    return Image.asset(
      isLight ? fullAssetLight : fullAsset,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'JobHub',
      errorBuilder: (_, _, _) => _fallbackWordmark(isLight, height),
    );
  }

  Widget _fallbackWordmark(bool isLight, double h) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _fallbackMark(isLight, h),
          const SizedBox(width: 10),
          Text(
            'JobHub',
            style: GoogleFonts.plusJakartaSans(
              color: isLight ? Colors.white : AppColors.ink,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              fontSize: size + 2,
            ),
          ),
        ],
      );

  Widget _fallbackMark(bool isLight, double s) => Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          color: isLight ? Colors.white : AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          'J',
          style: GoogleFonts.plusJakartaSans(
            color: isLight ? AppColors.primary : Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: s * 0.6,
            height: 1,
          ),
        ),
      );
}

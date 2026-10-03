import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';

/// Initial-letter avatar coloured deterministically from the name
/// (jobMapper createCompanyDisplay palette).
class ChatAvatar extends StatelessWidget {
  const ChatAvatar({super.key, required this.name, this.size = 44});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final display = CompanyDisplay.of(name);
    final (bg, fg) = CompanyPalette.at(display.paletteIndex);
    final initial = name.trim().isEmpty ? 'U' : name.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: size * 0.4),
      ),
    );
  }
}

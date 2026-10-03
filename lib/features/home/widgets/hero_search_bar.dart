import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/data/demo_data.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/section.dart';

/// components/search/SearchBar.jsx — keyword + province pill form; submit
/// navigates to `/viec-lam?q=&location=`. Popular chips only fill the keyword
/// input (`onClick={() => setKeyword(term)}`) — the user still picks a
/// province and presses 'Tìm kiếm'.
class HeroSearchBar extends StatefulWidget {
  const HeroSearchBar({super.key});

  @override
  State<HeroSearchBar> createState() => _HeroSearchBarState();
}

class _HeroSearchBarState extends State<HeroSearchBar> {
  final _keyword = TextEditingController();
  String _location = '';

  @override
  void dispose() {
    _keyword.dispose();
    super.dispose();
  }

  void _submit([String? keyword]) {
    final q = (keyword ?? _keyword.text).trim();
    final params = <String, String>{
      if (q.isNotEmpty) 'q': q,
      if (_location.isNotEmpty) 'location': _location,
    };
    final uri = Uri(path: AppRoutes.jobs, queryParameters: params.isEmpty ? null : params);
    context.push(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 640;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(wide ? AppRadius.pill : AppRadius.x2l),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.elevated,
            ),
            child: wide ? _wideRow() : _narrowColumn(),
          ),
          const SizedBox(height: 16),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              const Text('Phổ biến:', style: TextStyle(color: AppColors.inkMuted, fontSize: 14)),
              for (final term in AppConfig.popularKeywords)
                AppChip(
                  label: term,
                  onTap: () => setState(() => _keyword.text = term),
                ),
            ],
          ),
        ],
      );
    });
  }

  Widget _wideRow() => Row(
        children: [
          Expanded(child: _keywordField()),
          Container(width: 1, height: 28, color: AppColors.border),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 240, maxWidth: 260),
            child: _locationField(),
          ),
          const SizedBox(width: 4),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: const StadiumBorder(),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search, size: 18),
                SizedBox(width: 8),
                Text('Tìm kiếm'),
              ],
            ),
          ),
        ],
      );

  Widget _narrowColumn() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _keywordField(),
          const Divider(height: 8),
          _locationField(),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Tìm kiếm'),
          ),
        ],
      );

  Widget _keywordField() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.search, size: 20, color: AppColors.inkMuted),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _keyword,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _submit(),
                style: const TextStyle(fontSize: 14, color: AppColors.ink),
                decoration: const InputDecoration(
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                  hintText: 'Tìm theo vị trí, kỹ năng hoặc tên công ty...',
                ),
              ),
            ),
          ],
        ),
      );

  Widget _locationField() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.place_outlined, size: 20, color: AppColors.inkMuted),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _location,
                  isExpanded: true,
                  menuMaxHeight: 360,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.inkMuted),
                  style: const TextStyle(fontSize: 14, color: AppColors.ink),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Tất cả địa điểm')),
                    for (final p in DemoData.provinces) DropdownMenuItem(value: p, child: Text(p)),
                  ],
                  onChanged: (v) => setState(() => _location = v ?? ''),
                ),
              ),
            ),
          ],
        ),
      );
}

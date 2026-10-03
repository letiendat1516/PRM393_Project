import 'package:flutter/material.dart';

import '../../../core/data/demo_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/job_model.dart';

/// "Địa điểm" — the web ResumePage uses a plain
/// `<input placeholder="VD: Hồ Chí Minh">` (any text ≤ 100 chars). This is
/// the same free-text input with province suggestions layered on top: typing
/// filters [DemoData.provinces], but whatever the user types is kept as-is.
class CityField extends StatefulWidget {
  const CityField({
    super.key,
    required this.controller,
    this.validator,
    this.onChanged,
    this.textInputAction = TextInputAction.next,
    this.enabled = true,
  });

  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final TextInputAction textInputAction;
  final bool enabled;

  static const hint = 'VD: Hồ Chí Minh';
  static const _maxOptions = 8;

  @override
  State<CityField> createState() => _CityFieldState();
}

class _CityFieldState extends State<CityField> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Iterable<String> _options(TextEditingValue v) {
    final q = JobModel.stripDiacritics(v.text.trim().toLowerCase());
    if (q.isEmpty) return const Iterable<String>.empty();
    return DemoData.provinces
        .where((p) => JobModel.stripDiacritics(p.toLowerCase()).contains(q))
        .where((p) => p != v.text.trim())
        .take(CityField._maxOptions);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final width = c.maxWidth.isFinite ? c.maxWidth : 480.0;
        return RawAutocomplete<String>(
          textEditingController: widget.controller,
          focusNode: _focus,
          optionsBuilder: _options,
          onSelected: (v) => widget.onChanged?.call(v),
          fieldViewBuilder: (context, textCtrl, focus, onSubmit) => TextFormField(
            controller: textCtrl,
            focusNode: focus,
            enabled: widget.enabled,
            validator: widget.validator,
            textInputAction: widget.textInputAction,
            onChanged: widget.onChanged,
            onFieldSubmitted: (_) => onSubmit(),
            decoration: const InputDecoration(hintText: CityField.hint),
          ),
          optionsViewBuilder: (context, onSelected, options) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 240, maxWidth: width),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = options.elementAt(i);
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.place_outlined,
                          size: 16, color: AppColors.inkMuted),
                      title: Text(p, style: const TextStyle(fontSize: 14)),
                      onTap: () => onSelected(p),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

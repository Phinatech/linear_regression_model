import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────
//  REUSABLE FORM WIDGETS
//  Used by PredictionPage to build the input
//  form in a consistent, DRY way.
// ─────────────────────────────────────────────

/// Info banner shown at the top of the form.
class InfoCard extends StatelessWidget {
  final String text;
  const InfoCard(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFFF9800), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

/// Labelled section divider with an optional icon.
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  const SectionHeader(this.title, [this.icon, Key? key]) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: const Color(0xFFFF9800)),
          const SizedBox(width: 6),
        ],
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Divider(color: Color(0xFFFFCC80), thickness: 1),
        ),
      ]),
    );
  }
}

/// Places two widgets side by side with a 10 px gap.
class TwoColumn extends StatelessWidget {
  final Widget left;
  final Widget right;
  const TwoColumn({required this.left, required this.right, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Expanded(child: left),
        const SizedBox(width: 10),
        Expanded(child: right),
      ]),
    );
  }
}

/// Numeric text field with min/max validation.
class NumField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int min;
  final int max;
  final String? hint;

  const NumField(
    this.controller,
    this.label, {
    required this.min,
    required this.max,
    this.hint,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Required';
          final n = int.tryParse(v);
          if (n == null) return 'Numbers only';
          if (n < min || n > max) return '$min–$max only';
          return null;
        },
      ),
    );
  }
}

/// Generic dropdown — always opens below using DropdownMenu.
class AppDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> options;
  final List<String>? labels;
  final void Function(String?) onChanged;

  const AppDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.labels,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FormField<String>(
        initialValue: value,
        validator: (v) =>
            (v == null || v.isEmpty) ? 'Please select an option' : null,
        builder: (field) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownMenu<String>(
                initialSelection: value,
                hintText: label,
                expandedInsets: EdgeInsets.zero,
                menuHeight: 220,
                textStyle:
                    const TextStyle(fontSize: 13, color: Colors.black87),
                inputDecorationTheme: InputDecorationTheme(
                  hintStyle: const TextStyle(
                      fontSize: 13, color: Colors.black38),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFFFCC80)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFFFCC80)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFFFF9800), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
                trailingIcon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFFFF9800)),
                selectedTrailingIcon: const Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: Color(0xFFFF9800)),
                dropdownMenuEntries: options.asMap().entries.map((e) {
                  final display =
                      labels != null ? labels![e.key] : e.value;
                  return DropdownMenuEntry<String>(
                    value: e.value,
                    label: display,
                    style: MenuItemButton.styleFrom(
                      foregroundColor: Colors.black87,
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),
                onSelected: (v) {
                  field.didChange(v);
                  onChanged(v);
                },
              ),
              if (field.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 12),
                  child: Text(
                    field.errorText!,
                    style: const TextStyle(
                        color: Color(0xFFB00020), fontSize: 12),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Convenience yes/no dropdown.
class YesNoDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final void Function(String?) onChanged;

  const YesNoDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppDropdown(
      label: label,
      value: value,
      options: const ['yes', 'no'],
      onChanged: onChanged,
    );
  }
}

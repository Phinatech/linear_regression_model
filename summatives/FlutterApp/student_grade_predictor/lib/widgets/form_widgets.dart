import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
 
// ─────────────────────────────────────────────
//  REUSABLE FORM WIDGETS
//  Used by PredictionPage to build the input
//  form in a consistent, DRY way.
// ─────────────────────────────────────────────
 
/// Blue info banner shown at the top of the form.
class InfoCard extends StatelessWidget {
  final String text;
  const InfoCard(this.text, {super.key});
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
            ),
          ),
        ],
      ),
    );
  }
}
 
/// Labelled section divider with an icon.
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const SectionHeader(this.title, this.icon, {super.key});
 
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, size: 18, color: const Color(0xFF2563EB)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E3A5F),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(color: Colors.blueGrey.shade100, thickness: 1),
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
          labelText: label,
          hintText: hint ?? '$min – $max',
          hintStyle: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1)),
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
 
/// Generic dropdown field.
class AppDropdown extends StatelessWidget {
  final String label;
  final String value;
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
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: options.asMap().entries.map((e) {
          final display = labels != null ? labels![e.key] : e.value;
          return DropdownMenuItem(
            value: e.value,
            child: Text(display, style: const TextStyle(fontSize: 13)),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (v) => v == null ? 'Required' : null,
      ),
    );
  }
}
 
/// Convenience yes/no dropdown.
class YesNoDropdown extends StatelessWidget {
  final String label;
  final String value;
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
 
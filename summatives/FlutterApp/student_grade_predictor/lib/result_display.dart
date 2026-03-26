import 'package:flutter/material.dart';
 
// ─────────────────────────────────────────────
//  RESULT DISPLAY WIDGET
//  Shows predicted grade, risk level, or error.
// ─────────────────────────────────────────────
 
class ResultDisplay extends StatelessWidget {
  final String? grade;
  final String? risk;
  final String? error;
  final bool loading;
 
  const ResultDisplay({
    this.grade,
    this.risk,
    this.error,
    required this.loading,
    super.key,
  });
 
  Color get _riskColor {
    if (risk == null) return Colors.transparent;
    if (risk!.contains('HIGH')) return const Color(0xFFDC2626);
    if (risk!.contains('MODERATE')) return const Color(0xFFD97706);
    return const Color(0xFF16A34A);
  }
 
  Color get _riskBg {
    if (risk == null) return Colors.transparent;
    if (risk!.contains('HIGH')) return const Color(0xFFFEF2F2);
    if (risk!.contains('MODERATE')) return const Color(0xFFFFFBEB);
    return const Color(0xFFF0FDF4);
  }
 
  IconData get _riskIcon {
    if (risk == null) return Icons.info_outline;
    if (risk!.contains('HIGH')) return Icons.warning_amber_rounded;
    if (risk!.contains('MODERATE')) return Icons.info_outline;
    return Icons.check_circle_outline;
  }
 
  @override
  Widget build(BuildContext context) {
    // Empty state — nothing submitted yet
    if (!loading && grade == null && error == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD4856A)),
        ),
        child: const Center(
          child: Text(
            'Your prediction result will appear here.',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ),
      );
    }
 
    // Error state
    if (error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline,
                color: Color(0xFFDC2626), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                error!,
                style: const TextStyle(
                  color: Color(0xFF991B1B),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }
 
    // Success state
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4856A)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Grade banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: const BoxDecoration(
              color: Color(0xFFC15F3C),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Column(
              children: [
                const Text(
                  'Predicted Final Grade (G3)',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  '$grade / 20',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
 
          // Risk level row
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _riskBg,
            child: Row(
              children: [
                Icon(_riskIcon, color: _riskColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Risk Assessment',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        risk ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _riskColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
 
          // Footer note
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Powered by RandomForestRegressor · UCI Student Performance Dataset',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }
}
 
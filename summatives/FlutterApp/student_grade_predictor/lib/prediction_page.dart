import 'package:flutter/material.dart';
import 'api_service.dart';
import 'result_display.dart';
import 'widgets/form_widgets.dart';
 
// ─────────────────────────────────────────────
//  PREDICTION PAGE
//  Single-page form with all 26 input fields,
//  a Predict button, and the result display.
// ─────────────────────────────────────────────
 
class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});
 
  @override
  State<PredictionPage> createState() => _PredictionPageState();
}
 
class _PredictionPageState extends State<PredictionPage> {
  final _formKey = GlobalKey<FormState>();
 
  // ── Numeric text controllers ─────────────────
  final _age        = TextEditingController();
  final _medu       = TextEditingController();
  final _fedu       = TextEditingController();
  final _traveltime = TextEditingController();
  final _studytime  = TextEditingController();
  final _failures   = TextEditingController();
  final _famrel     = TextEditingController();
  final _freetime   = TextEditingController();
  final _goout      = TextEditingController();
  final _dalc       = TextEditingController();
  final _walc       = TextEditingController();
  final _health     = TextEditingController();
  final _absences   = TextEditingController();
 
  // ── Dropdown values ──────────────────────────
  String? _sex;
  String? _address;
  String? _famsize;
  String? _pstatus;
  String? _mjob;
  String? _fjob;
  String? _guardian;
  String? _schoolsup;
  String? _famsup;
  String? _paid;
  String? _activities;
  String? _nursery;
  String? _higher;
  String? _internet;
  String? _romantic;
 
  // ── Result state ─────────────────────────────
  String? _resultGrade;
  String? _resultRisk;
  String? _errorMessage;
  bool    _loading = false;
 
  @override
  void dispose() {
    for (final c in [
      _age, _medu, _fedu, _traveltime, _studytime, _failures,
      _famrel, _freetime, _goout, _dalc, _walc, _health, _absences,
    ]) {
      c.dispose();
    }
    super.dispose();
  }
 
  // ── Build payload for API ────────────────────
  Map<String, dynamic> _buildPayload() => {
        'sex':        _sex!,
        'age':        int.parse(_age.text),
        'address':    _address!,
        'famsize':    _famsize!,
        'Pstatus':    _pstatus!,
        'Medu':       int.parse(_medu.text),
        'Fedu':       int.parse(_fedu.text),
        'Mjob':       _mjob!,
        'Fjob':       _fjob!,
        'guardian':   _guardian!,
        'traveltime': int.parse(_traveltime.text),
        'studytime':  int.parse(_studytime.text),
        'failures':   int.parse(_failures.text),
        'schoolsup':  _schoolsup!,
        'famsup':     _famsup!,
        'paid':       _paid!,
        'activities': _activities!,
        'nursery':    _nursery!,
        'higher':     _higher!,
        'internet':   _internet!,
        'romantic':   _romantic!,
        'famrel':     int.parse(_famrel.text),
        'freetime':   int.parse(_freetime.text),
        'goout':      int.parse(_goout.text),
        'Dalc':       int.parse(_dalc.text),
        'Walc':       int.parse(_walc.text),
        'health':     int.parse(_health.text),
        'absences':   int.parse(_absences.text),
      };
 
  // ── Submit handler ───────────────────────────
  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) return;
 
    setState(() {
      _loading      = true;
      _resultGrade  = null;
      _resultRisk   = null;
      _errorMessage = null;
    });
 
    try {
      final result = await ApiService.predict(_buildPayload());
      setState(() {
        _resultGrade = result.grade.toStringAsFixed(1);
        _resultRisk  = result.riskLevel;
      });
    } on String catch (e) {
      setState(() => _errorMessage = e);
    } finally {
      setState(() => _loading = false);
    }
  }
 
  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFC15F3C),
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student Grade Predictor',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            Text(
              'Early Intervention Tool',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Info banner ──
            const InfoCard(
              'Fill in all 26 student profile fields below, then tap Predict '
              'to get the estimated final grade (G3, 0–20) and a risk assessment.',
            ),
            const SizedBox(height: 12),
 
            // ── Section 1: Demographic ──
            const SectionHeader('Demographic'),
            TwoColumn(
              left: AppDropdown(
                label: 'Sex',
                value: _sex,
                options: const ['F', 'M'],
                labels: const ['Female (F)', 'Male (M)'],
                onChanged: (v) => setState(() => _sex = v!),
              ),
              right: NumField(_age, 'Age', min: 15, max: 22),
            ),
            TwoColumn(
              left: AppDropdown(
                label: 'Address',
                value: _address,
                options: const ['U', 'R'],
                labels: const ['Urban (U)', 'Rural (R)'],
                onChanged: (v) => setState(() => _address = v!),
              ),
              right: AppDropdown(
                label: 'Family size',
                value: _famsize,
                options: const ['LE3', 'GT3'],
                labels: const ['≤3 members', '>3 members'],
                onChanged: (v) => setState(() => _famsize = v!),
              ),
            ),
            AppDropdown(
              label: 'Parent status',
              value: _pstatus,
              options: const ['T', 'A'],
              labels: const ['Living together (T)', 'Apart (A)'],
              onChanged: (v) => setState(() => _pstatus = v!),
            ),
            const SizedBox(height: 4),
 
            // ── Section 2: Parental Background ──
            const SectionHeader('Parental Background'),
            TwoColumn(
              left: NumField(_medu, 'Mother edu (0–4)', min: 0, max: 4),
              right: NumField(_fedu, 'Father edu (0–4)', min: 0, max: 4),
            ),
            AppDropdown(
              label: "Mother's job",
              value: _mjob,
              options: const [
                'teacher', 'health', 'services', 'at_home', 'other'
              ],
              onChanged: (v) => setState(() => _mjob = v!),
            ),
            AppDropdown(
              label: "Father's job",
              value: _fjob,
              options: const [
                'teacher', 'health', 'services', 'at_home', 'other'
              ],
              onChanged: (v) => setState(() => _fjob = v!),
            ),
            AppDropdown(
              label: 'Guardian',
              value: _guardian,
              options: const ['mother', 'father', 'other'],
              onChanged: (v) => setState(() => _guardian = v!),
            ),
            const SizedBox(height: 4),
 
            // ── Section 3: School Behaviour ──
            const SectionHeader('School Behaviour'),
            TwoColumn(
              left: NumField(_traveltime, 'Travel time (1–4)', min: 1, max: 4, hint: '1=<15 min  4=>1h'),
              right: NumField(_studytime, 'Study time (1–4)', min: 1, max: 4, hint: '1=<2h  4=>10h'),
            ),
            NumField(_failures, 'Past failures (0–4)', min: 0, max: 4),
            TwoColumn(
              left: YesNoDropdown(
                label: 'School support',
                value: _schoolsup,
                onChanged: (v) => setState(() => _schoolsup = v!),
              ),
              right: YesNoDropdown(
                label: 'Family support',
                value: _famsup,
                onChanged: (v) => setState(() => _famsup = v!),
              ),
            ),
            TwoColumn(
              left: YesNoDropdown(
                label: 'Paid tutoring',
                value: _paid,
                onChanged: (v) => setState(() => _paid = v!),
              ),
              right: YesNoDropdown(
                label: 'Activities',
                value: _activities,
                onChanged: (v) => setState(() => _activities = v!),
              ),
            ),
            TwoColumn(
              left: YesNoDropdown(
                label: 'Nursery school',
                value: _nursery,
                onChanged: (v) => setState(() => _nursery = v!),
              ),
              right: YesNoDropdown(
                label: 'Higher education',
                value: _higher,
                onChanged: (v) => setState(() => _higher = v!),
              ),
            ),
            TwoColumn(
              left: YesNoDropdown(
                label: 'Internet at home',
                value: _internet,
                onChanged: (v) => setState(() => _internet = v!),
              ),
              right: YesNoDropdown(
                label: 'Romantic relation',
                value: _romantic,
                onChanged: (v) => setState(() => _romantic = v!),
              ),
            ),
            const SizedBox(height: 4),
 
            // ── Section 4: Social & Health ──
            const SectionHeader('Social & Health'),
            TwoColumn(
              left: NumField(_famrel, 'Family relation (1–5)', min: 1, max: 5, hint: '1=bad  5=excellent'),
              right: NumField(_freetime, 'Free time (1–5)', min: 1, max: 5),
            ),
            TwoColumn(
              left: NumField(_goout, 'Goes out (1–5)', min: 1, max: 5),
              right: NumField(_health, 'Health (1–5)', min: 1, max: 5, hint: '1=bad  5=good'),
            ),
            TwoColumn(
              left: NumField(_dalc, 'Weekday alcohol (0–5)', min: 0, max: 5),
              right: NumField(_walc, 'Weekend alcohol (0–5)', min: 0, max: 5),
            ),
            NumField(_absences, 'School absences (0–93)', min: 0, max: 93),
            const SizedBox(height: 24),
 
            // ── Predict button ──
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _predict,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC15F3C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Predict',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            const SizedBox(height: 20),
 
            // ── Result display area ──
            ResultDisplay(
              grade: _resultGrade,
              risk: _resultRisk,
              error: _errorMessage,
              loading: _loading,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
 
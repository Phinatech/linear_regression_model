import 'package:flutter/material.dart';
import 'prediction_page.dart';
 
void main() {
  runApp(const StudentPredictorApp());
}
 
class StudentPredictorApp extends StatelessWidget {
  const StudentPredictorApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Grade Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC15F3C),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: false,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFD4856A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFD4856A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFC15F3C), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFEF4444)),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          labelStyle: const TextStyle(color: Colors.black87, fontSize: 13),
        ),
      ),
      home: const PredictionPage(),
    );
  }
}
 
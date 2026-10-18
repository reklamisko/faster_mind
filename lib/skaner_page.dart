import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ai_tabela.dart';

class SkanerPage extends StatefulWidget {
  const SkanerPage({super.key});

  @override
  State<SkanerPage> createState() => _SkanerPageState();
}

class _SkanerPageState extends State<SkanerPage> {
  bool _isProcessing = false;
  String _status = 'Gotowy do skanowania';
  final TextEditingController _nazwaController = TextEditingController();

  Future<void> _zrobZdjecieIPrzeanalizuj() async {
    if (_nazwaController.text.trim().isEmpty) {
      setState(() => _status = 'Najpierw podaj nazwę tabelki!');
      return;
    }

    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (photo == null) return;

    setState(() {
      _isProcessing = true;
      _status = 'AI czyta tabelę. To potrwa kilka sekund...';
    });

    try {
      final bytes = await File(photo.path).readAsBytes();

      final model = GenerativeModel(
        model: 'gemini-3.1-flash-lite',
        apiKey: geminiApiKey, // Używa klucza wpisanego wcześniej[cite: 7]
      );

      ffinal prompt = TextPart(
        'Przeanalizuj to zdjęcie. Znajdź na nim tabelę z danymi, wzorami, pojęciami lub wartościami.\n'
        '1. Jeśli to tabela dwukolumnowa: lewa strona to "pytanie", prawa to "odpowiedz".\n'
        '2. Jeśli to macierz/siatka wielokolumnowa: w polu "pytanie" POŁĄCZ nagłówek wiersza i nagłówek kolumny, ROZDZIELAJĄC JE DOKŁADNIE SYMBOLEM " | " (pionowa kreska ze spacjami), np. "sin α | 30°", "ctg α | π/4".\n'
        '3. ZASADY DLA FORMUŁ MATEMATYCZNYCH:\n'
        '   - ZAWSZE BEZWZGLĘDNIE ujmuj CAŁY licznik i CAŁY mianownik w nawiasy wokół ukośnika "/", np. "(1) / (tg α)", "(a * b) / (c)".\n'
        '   - Nie rozdzielaj spacjami samych nazw funkcji (pisz poprawnie: "tg α", "ctg α", "sin α", "cos α").\n'
        '   - Całe wyrażenie pod pierwiastkiem zapisuj w nawiasie po sqrt, np. "sqrt(1 + tg² α)".\n'
        '   - Przykłady poprawnego zapisu odpowiedzi: "(1) / (tg α)", "(±tg α) / (sqrt(1 + tg² α))".\n'
        '4. Zwróć wynik WYŁĄCZNIE jako czysty kod JSON w formacie tablicy obiektów: [{"pytanie": "...", "odpowiedz": "..."}].\n'
        'Zignoruj tło i tekst poza tabelą. Nie dodawaj znaczników markdown (```json) ani tekstu wstępnego.'
      );
      
      final imagePart = DataPart('image/jpeg', bytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      String aiText = response.text ?? '[]';
      aiText = aiText.replaceAll('```json', '').replaceAll('```', '').trim();

      List<dynamic> wyciagnietePary = jsonDecode(aiText);
      String? userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId != null && wyciagnietePary.isNotEmpty) {
        // Zapis do Firebase z flagą 'skan', która przyda się dla TV
        await FirebaseFirestore.instance
            .collection('wlasne_tabliczki')
            .doc(userId)
            .collection('tabele')
            .add({
          'nazwa': _nazwaController.text.trim(),
          'dataDodania': DateTime.now(),
          'pary': wyciagnietePary,
          'typ': 'skan',
        });

        setState(() {
          _status = 'Zapisano! Znaleziono ${wyciagnietePary.length} par.';
          _nazwaController.clear();
        });
      } else {
        setState(() =>
            _status = 'Nie udało się przetworzyć danych lub brak logowania.');
      }
    } catch (e) {
      setState(() {
        _status = 'Błąd analizy: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    _nazwaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Skanuj nową tabelę')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _nazwaController,
                decoration: const InputDecoration(
                  labelText: 'Nazwa tabeli (np. Wzory Fizyka)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Text(_status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 30),
              if (_isProcessing) const CircularProgressIndicator(),
              if (!_isProcessing)
                ElevatedButton.icon(
                  onPressed: _zrobZdjecieIPrzeanalizuj,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Zrób zdjęcie',
                      style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

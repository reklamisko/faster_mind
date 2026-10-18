import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'twoje_tabliczki_page.dart';

class GeneratorPage extends StatefulWidget {
  const GeneratorPage({super.key});

  @override
  State<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends State<GeneratorPage> {
  // Zmienne przechowujące wybory użytkownika
  String _wybranyStyl = 'szkic';
  String _wybranyCel = 'tv'; // 'tv' lub 'pdf'

  final TextEditingController _poziomMinCtrl = TextEditingController(text: '1');
  final TextEditingController _poziomMaxCtrl =
      TextEditingController(text: '10');
  final TextEditingController _pionMinCtrl = TextEditingController(text: '1');
  final TextEditingController _pionMaxCtrl = TextEditingController(text: '10');

  @override
  void dispose() {
    _poziomMinCtrl.dispose();
    _poziomMaxCtrl.dispose();
    _pionMinCtrl.dispose();
    _pionMaxCtrl.dispose();
    super.dispose();
  }

  // Główna funkcja wywoływana po kliknięciu "Utwórz"
  Future<void> _utworz() async {
    int pMin = int.tryParse(_poziomMinCtrl.text) ?? 1;
    int pMax = int.tryParse(_poziomMaxCtrl.text) ?? 10;
    int piMin = int.tryParse(_pionMinCtrl.text) ?? 1;
    int piMax = int.tryParse(_pionMaxCtrl.text) ?? 10;

    if (pMin > pMax || piMin > piMax) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Wartości minimalne nie mogą być większe od maksymalnych!')),
      );
      return;
    }

    if (_wybranyCel == 'tv') {
      // 1. Akcja dla Telewizora
      String pin = (math.Random().nextInt(9000) + 1000).toString();
      try {
        await FirebaseFirestore.instance.collection('sesje_tv').doc(pin).set({
          'poziomMin': pMin,
          'poziomMax': pMax,
          'pionMin': piMin,
          'pionMax': piMax,
          'styl': _wybranyStyl,
          'utworzono': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title:
                const Text('Wyświetlanie na TV', textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    'Otwórz przeglądarkę na telewizorze i wejdź na stronę:'),
                const SizedBox(height: 8),
                const SelectableText(
                  'faster-mind-12a6f.web.app', // Twój docelowy adres URL!
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.blue),
                ),
                const SizedBox(height: 16),
                const Text('Następnie wpisz kod PIN:'),
                const SizedBox(height: 8),
                Text(
                  pin,
                  style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Zamknij'),
              ),
            ],
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Błąd wysyłania: $e')));
      }
    } else {
      // 2. Akcja dla Wydruku PDF
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Generowanie pliku PDF... (Do zrobienia w kolejnym etapie)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Utwórz tabliczkę mnożenia'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- SEKCJA POZIOMA ---
            const Text('POZIOMO',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('min:'),
                const SizedBox(width: 10),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: _poziomMinCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 20),
                const Text('max:'),
                const SizedBox(width: 10),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: _poziomMaxCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // --- SEKCJA PIONOWA ---
            const Text('PIONOWO',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('min:'),
                const SizedBox(width: 10),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: _pionMinCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 20),
                const Text('max:'),
                const SizedBox(width: 10),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: _pionMaxCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // --- SEKCJA STYLÓW ---
            const Text('Wybierz styl:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Radio<String>(
                  value: 'szkic',
                  groupValue: _wybranyStyl,
                  onChanged: (String? value) {
                    setState(() {
                      _wybranyStyl = value!;
                    });
                  },
                ),
                const Text('szkic'),
                Radio<String>(
                  value: 'mono',
                  groupValue: _wybranyStyl,
                  onChanged: (String? value) {
                    setState(() {
                      _wybranyStyl = value!;
                    });
                  },
                ),
                const Text('mono'),
                Radio<String>(
                  value: 'tecza',
                  groupValue: _wybranyStyl,
                  onChanged: (String? value) {
                    setState(() {
                      _wybranyStyl = value!;
                    });
                  },
                ),
                const Text('tęcza'),
              ],
            ),

            const SizedBox(height: 20),

            // --- SEKCJA CELU ---
            const Text('Gdzie wyświetlić?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Radio<String>(
                  value: 'tv',
                  groupValue: _wybranyCel,
                  onChanged: (String? value) {
                    setState(() {
                      _wybranyCel = value!;
                    });
                  },
                ),
                const Text('Telewizor'),
                const SizedBox(width: 20),
                Radio<String>(
                  value: 'pdf',
                  groupValue: _wybranyCel,
                  onChanged: (String? value) {
                    setState(() {
                      _wybranyCel = value!;
                    });
                  },
                ),
                const Text('Drukuj (PDF)'),
              ],
            ),

            const SizedBox(height: 30),

            // --- PRZYCISK UTWÓRZ ---
            ElevatedButton(
              onPressed: _utworz,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('UTWÓRZ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),

            // --- PRZYCISK AI (WŁASNE TABELE) ---
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => TwojeTabliczkiPage()),
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Wstaw własne tabliczki',
                  style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

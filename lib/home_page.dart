import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'game_page.dart';
import 'glos_game_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _predkoscTts = 0.85;
  double _przesuniecieMs = -100.0;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Faster Mind'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Faster Mind',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              // Wybór ZAKRESU
              const Text('Zakres:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8.0,
                children: ['10', '15', '20', '30', '40', '50'].map((String wartosc) {
                  return ChoiceChip(
                    label: Text(wartosc),
                    selected: appState.zakres == wartosc,
                    onSelected: (bool selected) {
                      if (selected) {
                        context.read<AppState>().ustawZakres(wartosc);
                      }
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 25),

              // Wybór LICZBY PYTAŃ
              const Text('Liczba pytań:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8.0,
                children: ['25', '50', '75', '100'].map((String wartosc) {
                  return ChoiceChip(
                    label: Text(wartosc),
                    selected: appState.liczbaPytan == wartosc,
                    onSelected: (bool selected) {
                      if (selected) {
                        context.read<AppState>().ustawLiczbePytan(wartosc);
                      }
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 25),
              const Divider(),
              const SizedBox(height: 10),

              // Parametry testowe dla gry głosowej
              const Text(
                'Parametry gry głosowej:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
              const SizedBox(height: 10),

              Text('Szybkość pytania (TTS): ${_predkoscTts.toStringAsFixed(2)}'),
              Slider(
                value: _predkoscTts,
                min: 0.4,
                max: 1.2,
                divisions: 16,
                label: _predkoscTts.toStringAsFixed(2),
                activeColor: Colors.deepPurple,
                onChanged: (val) {
                  setState(() => _predkoscTts = val);
                },
              ),

              Text('Przesunięcie nasłuchu: ${_przesuniecieMs.round()} ms'),
              Slider(
                value: _przesuniecieMs,
                min: -500.0,
                max: 500.0,
                divisions: 20,
                label: '${_przesuniecieMs.round()} ms',
                activeColor: Colors.deepPurple,
                onChanged: (val) {
                  setState(() => _przesuniecieMs = val);
                },
              ),

              const SizedBox(height: 30),

              // Przyciski gry
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 15.0,
                runSpacing: 15.0,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GamePage()),
                      );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('START', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GlosGamePage(
                            predkoscTts: _predkoscTts,
                            przesuniecieMs: _przesuniecieMs.round(),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.mic),
                    label: const Text('Zagraj głosowo', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
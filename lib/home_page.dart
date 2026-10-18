import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart'; // Pobiera dostęp do naszego globalnego stanu AppState

import 'game_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Podłączamy się do globalnego stanu, by móc zmieniać opcje gry
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Faster Mind'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Faster Mind',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            // Opcje wyboru ZAKRESU (zastępuje FlutterFlowChoiceChips)
            const Text('Zakres:', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8.0,
              children:
                  ['10', '15', '20', '30', '40', '50'].map((String wartosc) {
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

            const SizedBox(height: 30),

            // Opcje wyboru LICZBY PYTAŃ (zastępuje drugie FlutterFlowChoiceChips)
            const Text('Liczba pytań:', style: TextStyle(fontSize: 18)),
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

            const SizedBox(height: 50),

            // Przycisk START
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GamePage()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text('START', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
}

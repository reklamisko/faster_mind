import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'tabliczki_home_page.dart';
import 'statystyki_page.dart';

class TabliczkiResultPage extends StatelessWidget {
  const TabliczkiResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();

    int liczba = int.tryParse(appState.ostatniaLiczbaPytan) ?? 25;
    double sredniCzas = appState.ostatniCzas / liczba;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Koniec serii (AI)'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Koniec serii',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Text(
              'Czas całkowity: ${appState.ostatniCzas} s',
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 10),
            Text(
              'Średnio na pytanie: ${sredniCzas.toStringAsFixed(2)} s',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TabliczkiHomePage(),
                  ),
                  (Route<dynamic> route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text('Zagraj ponownie', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () async {
                await context.read<AppState>().pobierzRekordy();

                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const StatystykiPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text('STATYSTYKI',
                  style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
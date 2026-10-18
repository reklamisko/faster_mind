import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'functions.dart';
import 'result_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  List<DateTime> listaCzasow = [];
  List<String> historiaPytan = [];
  Map<String, dynamic> aktualnePytanie = {};
  Map<String, dynamic> kolejnePytanie = {};

  bool _trwaZapis = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rozpocznijGre();
    });
  }

  void _rozpocznijGre() {
    final appState = context.read<AppState>();
    listaCzasow = [DateTime.now()];
    historiaPytan = [];

    // Pierwsze losowania za pomocą nowego, adaptacyjnego algorytmu
    aktualnePytanie = losujDzialanie(
        appState.zakres, appState.profilTrudnosci, appState.parametrA);
    historiaPytan.add(aktualnePytanie['pytanie']);

    kolejnePytanie = losujDzialanie(
        appState.zakres, appState.profilTrudnosci, appState.parametrA);

    setState(() {});
  }

  Future<void> _nastepnePytanie() async {
    if (_trwaZapis) return;

    final appState = context.read<AppState>();
    int limitPytan = int.parse(appState.liczbaPytan);

    // Wyliczamy czas reakcji dla bieżącego pytania
    DateTime teraz = DateTime.now();
    double czasReakcji =
        teraz.difference(listaCzasow.last).inMilliseconds / 1000.0;

    // Natychmiastowa aktualizacja profilu w pamięci RAM (odrzucanie skrajności robi się samo w main.dart)
    appState.aktualizujProfil(aktualnePytanie['pytanie'], czasReakcji);

    // Dodajemy czas do ogólnej historii, by na koniec zliczyć czas całkowity
    listaCzasow.add(teraz);

    if (historiaPytan.length >= limitPytan) {
      setState(() => _trwaZapis = true);

      double calkowityCzas = obliczCzasCakowity(listaCzasow);
      appState.ostatniCzas = calkowityCzas;
      appState.ostatniaLiczbaPytan = appState.liczbaPytan;

      try {
        String? userId = FirebaseAuth.instance.currentUser?.uid;

        if (userId != null) {
          // 1. Zapis pełnej historii (do starych logów)
          await FirebaseFirestore.instance.collection('wyniki').add({
            'uid': userId,
            'zakres': appState.zakres,
            'iloscPytan': appState.liczbaPytan,
            'czasSekundy': calkowityCzas,
            'dataGry': DateTime.now(),
            'pytania': historiaPytan,
            'czasyReakcji': listaCzasow,
          });

          // 2. Aktualizacja najlepszego wyniku (Twój poprzedni kod)
          String kategoria = '${appState.zakres}_${appState.liczbaPytan}';
          DocumentReference rekordyRef = FirebaseFirestore.instance
              .collection('najlepsze_wyniki')
              .doc(userId);

          DocumentSnapshot docSnap = await rekordyRef.get();
          if (docSnap.exists) {
            Map<String, dynamic> dane = docSnap.data() as Map<String, dynamic>;
            if (!dane.containsKey(kategoria) ||
                calkowityCzas < dane[kategoria]) {
              await rekordyRef
                  .set({kategoria: calkowityCzas}, SetOptions(merge: true));
            }
          } else {
            await rekordyRef.set({kategoria: calkowityCzas});
          }

          // 3. NOWE: Zapis profilu trudności gracza do Firebase (z nadpisywaniem jednego pliku)
          await FirebaseFirestore.instance
              .collection('profile_trudnosci')
              .doc(userId)
              .set({'profil': appState.profilTrudnosci},
                  SetOptions(merge: true));
        }
      } catch (e) {
        // print usunięty
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ResultPage()),
      );
      return;
    }

    setState(() {
      aktualnePytanie = kolejnePytanie;
      historiaPytan.add(aktualnePytanie['pytanie']);
      // Losujemy kolejne pytanie w oparciu o profil, który przed sekundą zaktualizowaliśmy
      kolejnePytanie = losujDzialanie(
          appState.zakres, appState.profilTrudnosci, appState.parametrA);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gra'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: aktualnePytanie.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${historiaPytan.length} z ${appState.liczbaPytan}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    aktualnePytanie['pytanie'] ?? '',
                    style: const TextStyle(
                        fontSize: 40, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    aktualnePytanie['wynik']?.toString() ?? '',
                    style: const TextStyle(fontSize: 24, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    kolejnePytanie['pytanie'] ?? '',
                    style:
                        const TextStyle(fontSize: 24, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 50),
                  ElevatedButton(
                    onPressed: _nastepnePytanie,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 20),
                    ),
                    child: const Text('DALEJ', style: TextStyle(fontSize: 20)),
                  ),
                ],
              ),
            ),
    );
  }
}

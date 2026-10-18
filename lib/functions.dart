import 'dart:math' as math;

// 1. Inteligentna funkcja losująca (Wykładnicza Ruletka)
Map<String, dynamic> losujDzialanie(String zakres,
    Map<String, List<double>> profilTrudnosci, double parametrA) {
  int maxLiczba = 10;
  if (int.tryParse(zakres) != null) {
    maxLiczba = int.parse(zakres);
  }

  List<Map<String, dynamic>> wirtualnyWorek = [];
  double sumaWag = 0.0;

  // Krok 1: Wrzucamy do "worka" wszystkie możliwe działania i wyliczamy ich wagi
  for (int a = 1; a <= maxLiczba; a++) {
    for (int b = 1; b <= maxLiczba; b++) {
      String dzialanie = '$a x $b';

      // Odczyt z pamięci lub "zimny start" (przypisanie z góry 3 najgorszych czasów)
      List<double> czasy = profilTrudnosci[dzialanie] ?? [6.0, 6.0, 6.0];

      // Pobranie 3 czasów do wzoru
      double t1 = czasy.isNotEmpty ? czasy[0] : 6.0;
      double t2 = czasy.length > 1 ? czasy[1] : 6.0;
      double t3 = czasy.length > 2 ? czasy[2] : 6.0;

      // Twój wzór: Średnia ważona z priorytetem dla najświeższego czasu (t1)
      double tSr = ((2 * t1) + t2 + t3) / 4.0;

      // Twój wzór: Waga wykładnicza
      double waga = math.pow((tSr / 1.5), parametrA).toDouble();

      wirtualnyWorek.add({
        'a': a,
        'b': b,
        'dzialanie': dzialanie,
        'waga': waga,
      });

      sumaWag += waga;
    }
  }

  // Krok 2: Kręcimy ruletką (losowanie z prawdopodobieństwem zależnym od wagi)
  final random = math.Random();
  double los = random.nextDouble() * sumaWag;

  double akumulator = 0.0;
  for (var opcja in wirtualnyWorek) {
    akumulator += opcja['waga'];
    if (akumulator >= los) {
      return {
        'pytanie': opcja['dzialanie'],
        'wynik': (opcja['a'] * opcja['b']).toString(),
      };
    }
  }

  // Zabezpieczenie systemowe w razie błędów zaokrągleń
  return {
    'pytanie': '${wirtualnyWorek.last['a']} x ${wirtualnyWorek.last['b']}',
    'wynik': (wirtualnyWorek.last['a'] * wirtualnyWorek.last['b']).toString(),
  };
}

// 2. Funkcja obliczająca całkowity czas gry w sekundach
double obliczCzasCakowity(List<DateTime> lista) {
  if (lista.length < 2) return 0.0;
  int roznicaMs = lista.last.difference(lista.first).inMilliseconds;
  double sekundy = roznicaMs / 1000.0;
  return double.parse(sekundy.toStringAsFixed(2));
}

// 3. Listy do wyświetlania statystyk i ustawień
List<String> pobierzListeZakresow() {
  return ['10', '15', '20', '30', '40', '50'];
}

List<String> pobierzListePytan() {
  return ['25', '50', '75', '100'];
}

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'main.dart';
import 'functions.dart';
import 'result_page.dart';

class GlosGamePage extends StatefulWidget {
  final double predkoscTts;
  final int przesuniecieMs;

  const GlosGamePage({
    super.key,
    this.predkoscTts = 0.85,
    this.przesuniecieMs = -100,
  });

  @override
  State<GlosGamePage> createState() => _GlosGamePageState();
}

class _GlosGamePageState extends State<GlosGamePage> {
  final FlutterTts _flutterTts = FlutterTts();
  late stt.SpeechToText _speech;

  Timer? _zegarTimer;
  Timer? _sttWatchdogTimer;

  bool _isInitializing = true;
  bool _czyPytanieZaliczone = false;
  bool _czyIgnorowacMowe = true;
  bool _isDisposed = false;

  String _statusGlosu = 'Inicjalizacja...';
  String _buforTekstu = '';

  List<DateTime> listaCzasow = [];
  List<String> historiaPytan = [];
  Map<String, dynamic> aktualnePytanie = {};
  Map<String, dynamic> kolejnePytanie = {};

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _inicjalizujGlos();
    _startCykanieZegara();
    _startSttWatchdog();
  }

  void _startCykanieZegara() {
    _zegarTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isDisposed) {
        SystemSound.play(SystemSoundType.click);
      }
    });
  }

  void _startSttWatchdog() {
    _sttWatchdogTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (_isDisposed || _czyPytanieZaliczone || _czyIgnorowacMowe || _isInitializing) return;
      if (!_speech.isListening) {
        _wznowNasluch();
      }
    });
  }

  Future<void> _inicjalizujGlos() async {
    await _flutterTts.setLanguage('pl-PL');
    await _flutterTts.setSpeechRate(widget.predkoscTts);
    await _flutterTts.awaitSpeakCompletion(true);

    try {
      bool dostepny = await _speech.initialize(
        onError: (val) {
          if (mounted && !_czyPytanieZaliczone && !_isDisposed && !_czyIgnorowacMowe) {
            _wznowNasluch();
          }
        },
        onStatus: (val) {
          if ((val == 'notListening' || val == 'done') &&
              mounted &&
              !_czyPytanieZaliczone &&
              !_isInitializing &&
              !_isDisposed &&
              !_czyIgnorowacMowe) {
            _wznowNasluch();
          }
        },
      );

      if (_isDisposed) return;

      if (dostepny) {
        setState(() {
          _isInitializing = false;
          _statusGlosu = 'Gotowy!';
        });
        _rozpocznijGre();
      } else {
        setState(() {
          _isInitializing = false;
          _statusGlosu = 'Brak zgody na mikrofon / rozpoznawanie mowy.';
        });
      }
    } catch (e) {
      if (!_isDisposed) {
        setState(() {
          _isInitializing = false;
          _statusGlosu = 'Błąd inicjalizacji: $e';
        });
      }
    }
  }

  void _rozpocznijGre() {
    if (_isDisposed) return;

    final appState = context.read<AppState>();
    listaCzasow = [DateTime.now()];
    historiaPytan = [];

    aktualnePytanie = losujDzialanie(
        appState.zakres, appState.profilTrudnosci, appState.parametrA);
    historiaPytan.add(aktualnePytanie['pytanie']);
    kolejnePytanie = losujDzialanie(
        appState.zakres, appState.profilTrudnosci, appState.parametrA);

    _zadajPytanieGlosowo();
  }

  void _startSluchania() async {
    if (_isDisposed || _speech.isListening || _czyIgnorowacMowe) return;

    try {
      await _speech.listen(
        onResult: (result) {
          if (!mounted || _czyPytanieZaliczone || _czyIgnorowacMowe || _isDisposed) return;

          setState(() {
            _buforTekstu = result.recognizedWords;
          });

          _sprawdzOdpowiedz(_buforTekstu);
        },
        localeId: 'pl_PL',
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      );
    } catch (_) {}
  }

  void _wznowNasluch() {
    if (_czyPytanieZaliczone || !mounted || _isDisposed || _czyIgnorowacMowe) return;
    if (!_speech.isListening) {
      _startSluchania();
    }
  }

  Future<void> _zadajPytanieGlosowo() async {
    if (aktualnePytanie.isEmpty || _isDisposed) return;

    _czyPytanieZaliczone = false;
    _czyIgnorowacMowe = true;

    if (mounted) {
      setState(() {
        _buforTekstu = '';
        _statusGlosu = 'Mówię pytanie...';
      });
    }

    if (_speech.isListening) {
      await _speech.stop();
    }

    String pyt = aktualnePytanie['pytanie'] ?? '';
    String pytMowione = pyt.replaceAll('x', ' razy ');

    await _flutterTts.speak(pytMowione);

    if (_isDisposed || _czyPytanieZaliczone) return;

    _czyIgnorowacMowe = false;
    if (mounted) {
      setState(() => _statusGlosu = 'Słucham... 🎙️');
    }
    _startSluchania();
  }

  void _sprawdzOdpowiedz(String tekstBufora) {
    if (_czyPytanieZaliczone || _czyIgnorowacMowe || _isDisposed) return;

    int? oczekiwanyWynik = int.tryParse(aktualnePytanie['wynik']?.toString() ?? '');
    if (oczekiwanyWynik == null) return;

    int? rozpoznanaLiczba = _parsujBuforNaLiczbe(tekstBufora);

    if (rozpoznanaLiczba == oczekiwanyWynik) {
      _czyPytanieZaliczone = true;
      _czyIgnorowacMowe = true;

      _flutterTts.stop();
      _speech.stop();

      _nastepnePytanie();
    }
  }

  int? _parsujBuforNaLiczbe(String tekst) {
    if (tekst.isEmpty) return null;

    String t = tekst
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\sżółćęśąźń1234567890]'), '')
        .trim();

    if (int.tryParse(t) != null) return int.parse(t);

    if (t == 'to') return 100;

    t = t
        .replaceAll('siedem dziesiąt', 'siedemdziesiąt')
        .replaceAll('osiem dziesiąt', 'osiemdziesiąt')
        .replaceAll('sześć dziesiąt', 'sześćdziesiąt')
        .replaceAll('pięć dziesiąt', 'pięćdziesiąt')
        .replaceAll('czter dzieści', 'czterdzieści')
        .replaceAll('trzy dzieści', 'trzydzieści')
        .replaceAll('stówka', 'sto');

    final Map<String, int> slownik = {
      'zero': 0, 'jeden': 1, 'jedna': 1, 'dwa': 2, 'dwie': 2, 'trzy': 3, 'cztery': 4,
      'pięć': 5, 'sześć': 6, 'siedem': 7, 'osiem': 8, 'dziewięć': 9,
      'dziesięć': 10, 'jedenaście': 11, 'dwanaście': 12, 'trzynaście': 13,
      'czternaście': 14, 'piętnaście': 15, 'szesnaście': 16, 'siedemnaście': 17,
      'osiemnaście': 18, 'dziewięćnaście': 19, 'dwadzieścia': 20,
      'trzydzieści': 30, 'czterdzieści': 40, 'pięćdziesiąt': 50,
      'sześćdziesiąt': 60, 'siedemdziesiąt': 70, 'osiemdziesiąt': 80,
      'dziewięćdziesiąt': 90,
      'sto': 100, 'to': 100, 'dwieście': 200, 'trzyście': 300, 'czteryście': 400,
      'pięćset': 500, 'sześćset': 600, 'siedemset': 700, 'osiemset': 800,
      'dziewięćset': 900,
      'tysiąc': 1000, 'tysiące': 1000, 'tysięcy': 1000,
    };

    if (slownik.containsKey(t)) return slownik[t];

    List<String> czesci = t.split(RegExp(r'\s+'));
    int suma = 0;
    int ostatniaWartosc = 0;
    bool znalazlo = false;

    for (var czesc in czesci) {
      if (int.tryParse(czesc) != null) {
        int val = int.parse(czesc);
        suma += val;
        ostatniaWartosc = val;
        znalazlo = true;
      } else if (slownik.containsKey(czesc)) {
        int val = slownik[czesc]!;
        if ((czesc == 'tysiąc' || czesc == 'tysiące' || czesc == 'tysięcy') &&
            ostatniaWartosc > 0 &&
            ostatniaWartosc < 10) {
          suma = (suma - ostatniaWartosc) + (ostatniaWartosc * 1000);
        } else {
          suma += val;
        }
        ostatniaWartosc = val;
        znalazlo = true;
      }
    }

    return znalazlo ? suma : null;
  }

  void _nastepnePytanie() {
    if (_isDisposed) return;

    final appState = context.read<AppState>();
    int limitPytan = int.parse(appState.liczbaPytan);

    if (historiaPytan.length >= limitPytan) {
      _wyczyscZasoby();

      listaCzasow.add(DateTime.now());
      double calkowityCzas = obliczCzasCakowity(listaCzasow);

      appState.ostatniCzas = calkowityCzas;
      appState.ostatniaLiczbaPytan = appState.liczbaPytan;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ResultPage()),
      );
      return;
    }

    setState(() {
      listaCzasow.add(DateTime.now());
      aktualnePytanie = kolejnePytanie;
      historiaPytan.add(aktualnePytanie['pytanie']);
      kolejnePytanie = losujDzialanie(
          appState.zakres, appState.profilTrudnosci, appState.parametrA);
      _buforTekstu = '';
    });

    _zadajPytanieGlosowo();
  }

  void _wyczyscZasoby() {
    _isDisposed = true;
    _zegarTimer?.cancel();
    _sttWatchdogTimer?.cancel();
    _flutterTts.stop();
    _speech.stop();
    _speech.cancel();
  }

  @override
  void dispose() {
    _wyczyscZasoby();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _wyczyscZasoby();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gra Głosowa 🎤'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.power_settings_new, color: Colors.red),
              tooltip: 'Zamknij aplikację',
              onPressed: () => exit(0),
            ),
          ],
        ),
        body: _isInitializing
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text(_statusGlosu, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
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
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        _statusGlosu,
                        style: const TextStyle(
                            fontSize: 20,
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'Usłyszano: $_buforTekstu',
                        style: const TextStyle(fontSize: 22, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
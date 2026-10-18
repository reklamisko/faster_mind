import 'package:flutter/material.dart';
import 'skaner_page.dart';

class TwojeTabliczkiPage extends StatefulWidget {
  const TwojeTabliczkiPage({super.key});

  @override
  State<TwojeTabliczkiPage> createState() => _TwojeTabliczkiPageState();
}

class _TwojeTabliczkiPageState extends State<TwojeTabliczkiPage> {
  // Tymczasowa lista do testów wizualnych
  List<String> zapisaneTabliczki = ['Wzory fizyczne (test)', 'Pochodne (test)'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Twoje Tabliczki'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Wybierz tabliczki do odpytywania:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: zapisaneTabliczki.isEmpty
                ? const Center(child: Text('Brak zapisanych tabliczek.'))
                : ListView.builder(
                    itemCount: zapisaneTabliczki.length,
                    itemBuilder: (context, index) {
                      return CheckboxListTile(
                        title: Text(zapisaneTabliczki[index]),
                        value:
                            false, // W przyszłości podepniemy to pod stan gry
                        onChanged: (bool? value) {
                          // Logika zaznaczania
                        },
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton.icon(
              onPressed: () {
                // Przejście do procedury aparatu i AI
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SkanerPage()),
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Skanuj nową tabliczkę',
                  style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

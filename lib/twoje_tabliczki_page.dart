import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'skaner_page.dart';

class TwojeTabliczkiPage extends StatefulWidget {
  const TwojeTabliczkiPage({super.key});

  @override
  State<TwojeTabliczkiPage> createState() => _TwojeTabliczkiPageState();
}

class _TwojeTabliczkiPageState extends State<TwojeTabliczkiPage> {
  String? _wybranaTabelaId;
  Map<String, dynamic>? _wybranaTabelaDane;

  Future<void> _wyslijNaTv() async {
    if (_wybranaTabelaDane == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wybierz tabelę z listy!')),
      );
      return;
    }

    String pin = (math.Random().nextInt(9000) + 1000).toString();

    try {
      await FirebaseFirestore.instance.collection('sesje_tv').doc(pin).set({
        'typ': 'skan',
        'nazwa': _wybranaTabelaDane!['nazwa'] ?? 'Tabela',
        'pary': _wybranaTabelaDane!['pary'] ?? [],
        'utworzono': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Wyświetlanie na TV', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Otwórz przeglądarkę na telewizorze i wejdź na stronę:'),
              const SizedBox(height: 8),
              const SelectableText(
                'faster-mind-12a6f.web.app',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue),
              ),
              const SizedBox(height: 16),
              const Text('Następnie wpisz kod PIN:'),
              const SizedBox(height: 8),
              Text(
                pin,
                style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, letterSpacing: 6),
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd wysyłania: $e')),
      );
    }
  }

  Future<void> _usunTabliczke() async {
    if (_wybranaTabelaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zaznacz tabelę z listy, którą chcesz usunąć!')),
      );
      return;
    }

    bool? potwierdzenie = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Potwierdzenie usunięcia'),
        content: Text('Czy na pewno chcesz usunąć tabelę "${_wybranaTabelaDane?['nazwa'] ?? ''}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Usuń', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (potwierdzenie != true) return;

    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('wlasne_tabliczki')
          .doc(userId)
          .collection('tabele')
          .doc(_wybranaTabelaId)
          .delete();

      setState(() {
        _wybranaTabelaId = null;
        _wybranaTabelaDane = null;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tabela została usunięta z bazy.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd podczas usuwania: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteka Własnych Tabel'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Zaznacz tabelę, aby wysłać na TV lub usunąć:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: userId == null
                ? const Center(child: Text('Brak zalogowanego użytkownika.'))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('wlasne_tabliczki')
                        .doc(userId)
                        .collection('tabele')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text('Brak zapisanych tabel. Skanuj pierwszą tabelę poniżej!'),
                        );
                      }

                      var docs = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          var doc = docs[index];
                          var data = doc.data() as Map<String, dynamic>;
                          String nazwaTabeli = data['nazwa'] ?? 'Bez nazwy';
                          List pary = data['pary'] ?? [];

                          return RadioListTile<String>(
                            title: Text(nazwaTabeli, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Liczba par: ${pary.length}'),
                            value: doc.id,
                            groupValue: _wybranaTabelaId,
                            onChanged: (String? value) {
                              setState(() {
                                _wybranaTabelaId = value;
                                _wybranaTabelaDane = data;
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 10.0, bottom: 35.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _wyslijNaTv,
                    icon: const Icon(Icons.tv, size: 20),
                    label: const Text('Wyślij na TV', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _usunTabliczke,
                    icon: const Icon(Icons.delete, size: 20),
                    label: const Text('Usuń', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SkanerPage()),
                      );
                    },
                    icon: const Icon(Icons.camera_alt, size: 20),
                    label: const Text('Skanuj nową', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
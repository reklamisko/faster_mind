import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'functions.dart';
import 'home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StatystykiPage extends StatelessWidget {
  const StatystykiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final zakresy = pobierzListeZakresow();
    final pytania = pobierzListePytan();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statystyki'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 30.0,
                  horizontalMargin: 10.0,
                  headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
                  columns: [
                    const DataColumn(
                        label: Text('z/p',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    ...pytania.map((p) => DataColumn(
                        label: Text(p,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)))),
                  ],
                  rows: zakresy.map((zakres) {
                    return DataRow(
                      cells: [
                        DataCell(Text(zakres,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold))),
                        ...pytania.map((iloscPytan) {
                          String najlepszyCzas =
                              appState.sprawdzCzas(zakres, iloscPytan);
                          return DataCell(Text(najlepszyCzas));
                        }),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Potwierdzenie'),
                      content: const Text(
                          'Czy na pewno chcesz skasować statystyki?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Anuluj'),
                        ),
                        TextButton(
                          onPressed: () async {
                            String? userId =
                                FirebaseAuth.instance.currentUser?.uid;
                            if (userId != null) {
                              await FirebaseFirestore.instance
                                  .collection('najlepsze_wyniki')
                                  .doc(userId)
                                  .delete();
                              if (!context.mounted) return;
                              await context.read<AppState>().pobierzRekordy();
                            }
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                          },
                          child: const Text('Kasuj',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text('KASUJ STATYSTYKI',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text('DO GRY', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

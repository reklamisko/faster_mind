
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tabliczki_game_page.dart';

class TabliczkiHomePage extends StatefulWidget {
  const TabliczkiHomePage({super.key});

  @override
  State<TabliczkiHomePage> createState() => _TabliczkiHomePageState();
}

class _TabliczkiHomePageState extends State<TabliczkiHomePage> {
  final TextEditingController _iloscPytanCtrl = TextEditingController(text: '25');
  List<String> wybraneTabele = [];

  @override
  void dispose() {
    _iloscPytanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Twoje tabliczki'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Ilość pytań:', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 15),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _iloscPytanCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text('Wybierz tabele do odpytywania:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
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
                          return const Center(child: Text('Brak zapisanych tabel w chmurze.'));
                        }

                        var docs = snapshot.data!.docs;

                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            var data = docs[index].data() as Map<String, dynamic>;
                            String nazwaTabeli = data['nazwa'] ?? 'Bez nazwy';

                            return CheckboxListTile(
                              title: Text(nazwaTabeli),
                              value: wybraneTabele.contains(nazwaTabeli),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    wybraneTabele.add(nazwaTabeli);
                                  } else {
                                    wybraneTabele.remove(nazwaTabeli);
                                  }
                                });
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
            ElevatedButton(
              onPressed: () {
                if (wybraneTabele.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Wybierz przynajmniej jedną tabelę!')),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TabliczkiGamePage(
                      wybraneTabele: wybraneTabele,
                      iloscPytan: _iloscPytanCtrl.text,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text('START', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
}

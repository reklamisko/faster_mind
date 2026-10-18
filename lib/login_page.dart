import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'landing_page.dart'; // <--- DODAJ IMPORT HUB-A

// BRAMKA AUTORYZACYJNA
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        // Jeśli jest zalogowany -> wpuszcza do HUB-a
        if (snapshot.hasData) {
          return const LandingPage();
        }
        // Jeśli nie -> prosi o logowanie
        return const LoginPage();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _zalogujEmail() async {
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        UserCredential cred =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (cred.user != null && !cred.user!.emailVerified) {
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Konto nieaktywne! Sprawdź swoją skrzynkę e-mail i kliknij link weryfikacyjny.')),
          );
        }
      } else {
        UserCredential cred =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        await cred.user?.sendEmailVerification();
        await FirebaseAuth.instance.signOut();

        setState(() {
          _isLogin = true;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Konto utworzone! Wysłaliśmy link aktywacyjny na Twój adres. Kliknij go, a następnie zaloguj się.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd: ${e.toString()}')),
      );
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _zalogujGoogle() async {
    setState(() => _isLoading = true);
    try {
      if (kIsWeb) {
        // WERSJA DLA PRZEGLĄDAREK (TV / PC)
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        // WERSJA DLA ANDROIDA (Tablet / Telefon)
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser != null) {
          final GoogleSignInAuthentication googleAuth =
              await googleUser.authentication;
          final AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          await FirebaseAuth.instance.signInWithCredential(credential);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd Google: ${e.toString()}')),
      );
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(_isLogin ? 'Logowanie' : 'Rejestracja'),
          centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Faster Mind',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                    labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                    labelText: 'Hasło', border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _zalogujEmail,
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50)),
                      child: Text(_isLogin ? 'ZALOGUJ' : 'ZAREJESTRUJ',
                          style: const TextStyle(fontSize: 18)),
                    ),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(_isLogin
                    ? 'Nie masz konta? Zarejestruj się'
                    : 'Masz już konto? Zaloguj się'),
              ),

              const Divider(height: 40, thickness: 2),

              // --- SEKCJA LOGOWANIA GOOGLE (Zaktualizowana) ---
              _isLoading
                  ? const SizedBox.shrink()
                  : ElevatedButton.icon(
                      onPressed: _zalogujGoogle,
                      icon: const Icon(Icons.login),
                      label: const Text('Zaloguj przez Google',
                          style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

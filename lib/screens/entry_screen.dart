import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sajin/screens/login_screen.dart';
import 'package:sajin/screens/register_screen.dart';
import 'package:sajin/utils/app_constants.dart';

class EntryScreen extends StatelessWidget {
  const EntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo do aplicativo com estilo Pacifico
              Text(
                AppConstants.appName,
                style: GoogleFonts.pacifico(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor, // Usar a cor primária do tema
                ),
              ),
              const SizedBox(height: 32),
              // Descrição do aplicativo
              Text(
                'Capture e compartilhe os momentos do seu dia a dia com a comunidade Sajin.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 64),
              // Botão de Login
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  child: const Text('Login'),
                ),
              ),
              const SizedBox(height: 16),
              // Botão de Registrar
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterScreen()),
                    );
                  },
                  child: const Text('Registrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sajin/screens/entry_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Editar Perfil'),
            onTap: () {
              // Implementar edição de perfil
            },
          ),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('Mudar Tema'),
            onTap: () {
              // Implementar mudança de tema
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Sair'),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const EntryScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
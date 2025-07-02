import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sajin/services/auth_service.dart';
import 'package:sajin/utils/app_theme.dart';
import 'package:sajin/screens/entry_screen.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  // Exibe um diálogo de confirmação antes de sair
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sair do aplicativo?'),
          content: const Text('Tem certeza de que deseja sair da sua conta de administrador?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o diálogo
              },
            ),
            TextButton(
              child: const Text('Sair', style: TextStyle(color: Colors.red)),
              onPressed: () {
                final authService = Provider.of<AuthService>(context, listen: false);
                authService.logout(); // Desloga o usuário
                Navigator.of(context).pop(); // Fecha o diálogo
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const EntryScreen()),
                  (route) => false, // Remove todas as rotas anteriores
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = Provider.of<AppTheme>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Opção para mudar o tema
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0), // Padding interno para o Card
              child: ListTile(
                leading: Icon(appTheme.isDarkMode ? Icons.dark_mode : Icons.light_mode, color: Theme.of(context).primaryColor),
                title: const Text('Mudar Tema do Sistema'),
                trailing: DropdownButton<ThemeMode>(
                  value: appTheme.themeMode,
                  onChanged: (ThemeMode? newValue) {
                    if (newValue != null) {
                      appTheme.setThemeMode(newValue);
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('Sistema'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Claro'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Escuro'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Botão para sair do app
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout),
              label: const Text('Sair do App'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Cor de fundo do botão de sair
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

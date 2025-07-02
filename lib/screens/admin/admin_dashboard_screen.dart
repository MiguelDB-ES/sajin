import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import para SystemNavigator.pop
import 'package:provider/provider.dart';
import 'package:sajin/screens/admin/manage_content_screen.dart'; // Importação correta
import 'package:sajin/screens/admin/manage_profiles_screen.dart'; // Importação correta
import 'package:sajin/screens/admin/admin_settings_screen.dart';
import 'package:sajin/services/auth_service.dart';
import 'package:sajin/screens/entry_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0; // Índice da aba selecionada
  DateTime? _lastExitTime; // Para controlar o "dois cliques para sair"

  // Widgets para cada tela da navegação inferior
  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return const ManageContentScreen(); // Gerenciar Conteúdos
      case 1:
        return const ManageProfilesScreen(); // Gerenciar Perfis
      case 2:
        return const AdminSettingsScreen(); // Configurações do Admin
      default:
        return const Center(child: Text('Tela não encontrada'));
    }
  }

  // Altera a aba selecionada
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

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
    final authService = Provider.of<AuthService>(context);
    final adminUser = authService.currentUser;

    // Controla o comportamento do botão de retorno do celular
    return PopScope(
      canPop: false, // Impede o pop automático
      onPopInvoked: (didPop) async {
        if (didPop) {
          return;
        }
        final now = DateTime.now();
        // Se a última vez que o botão foi pressionado foi há menos de 2 segundos, sai do app
        if (_lastExitTime == null || now.difference(_lastExitTime!) > const Duration(seconds: 2)) {
          _lastExitTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pressione novamente para sair do app.')),
          );
        } else {
          SystemNavigator.pop(); // Sai do aplicativo
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Painel Administrativo'),
          centerTitle: true,
          automaticallyImplyLeading: false, // Remove o botão de retorno padrão
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _confirmLogout(context),
              tooltip: 'Sair',
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bem-vindo, ${adminUser?.username ?? 'Admin'}!',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gerencie o conteúdo e os usuários do Sajin.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _getScreen(_selectedIndex),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard),
              label: 'Conteúdo',
              backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.people),
              label: 'Perfis',
              backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings),
              label: 'Configurações',
              backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
          unselectedItemColor: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}

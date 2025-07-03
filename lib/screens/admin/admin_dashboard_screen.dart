import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sajin/screens/admin/manage_content_screen.dart';
import 'package:sajin/screens/admin/manage_profiles_screen.dart';
import 'package:sajin/screens/admin/admin_settings_screen.dart';
import 'package:sajin/services/auth_service.dart';
import 'package:sajin/screens/entry_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  DateTime? _lastExitTime;

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return const ManageContentScreen();
      case 1:
        return const ManageProfilesScreen();
      case 2:
        return const AdminSettingsScreen();
      default:
        return const Center(child: Text('Tela não encontrada'));
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

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
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Sair', style: TextStyle(color: Colors.red)),
              onPressed: () {
                final authService = Provider.of<AuthService>(context, listen: false);
                authService.logout();
                Navigator.of(context).pop();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const EntryScreen()),
                  (route) => false,
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
    final adminUser = authService.currentUser; // Mantido caso precise do usuário em outro lugar no futuro

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) {
          return;
        }
        final now = DateTime.now();
        if (_lastExitTime == null || now.difference(_lastExitTime!) > const Duration(seconds: 2)) {
          _lastExitTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pressione novamente para sair do app.')),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Painel Administrativo'),
          centerTitle: true,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => _confirmLogout(context),
              tooltip: 'Sair',
            ),
          ],
        ),
        body: Column(
          children: [
            // A mensagem de boas-vindas foi removida daqui para ser tratada como notificação ao logar.
            Expanded(
              child: _getScreen(_selectedIndex),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_rounded),
              label: 'Conteúdo',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.people_alt_rounded),
              label: 'Perfis',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_rounded),
              label: 'Configurações',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
          unselectedItemColor: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          elevation: Theme.of(context).bottomNavigationBarTheme.elevation,
        ),
      ),
    );
  }
}

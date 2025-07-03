import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sajin/services/auth_service.dart';
import 'package:sajin/utils/app_theme.dart';
import 'package:sajin/screens/entry_screen.dart';
import 'package:sajin/models/user.dart';
import 'package:sajin/utils/database_helper.dart';
import 'package:sajin/widgets/custom_text_field.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  User? _currentUser;
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  bool _isEditingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  void _loadCurrentUser() {
    final authService = Provider.of<AuthService>(context, listen: false);
    setState(() {
      _currentUser = authService.currentUser;
      if (_currentUser != null) {
        _fullNameController.text = _currentUser!.fullName;
        _usernameController.text = _currentUser!.username;
      }
    });
  }

  // Exibe um diálogo de confirmação antes de sair
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sair do aplicativo?'),
          content: const Text('Tem certeza de que deseja sair da sua conta?'),
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

  // Função para atualizar os dados do perfil
  Future<void> _updateProfile() async {
    if (_currentUser == null) return;

    if (_fullNameController.text.trim().isEmpty || _usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome completo e nome de usuário não podem ser vazios.')),
      );
      return;
    }

    try {
      final updatedUser = _currentUser!.copy(
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
      );
      await DatabaseHelper.instance.updateUser(updatedUser);
      Provider.of<AuthService>(context, listen: false).updateCurrentUser(updatedUser);
      setState(() {
        _currentUser = updatedUser;
        _isEditingProfile = false; // Sai do modo de edição após salvar
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados do perfil atualizados com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar perfil: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = Provider.of<AppTheme>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Opção para mudar o tema
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
            elevation: 4,
            color: Theme.of(context).cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modo do Tema',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildThemeButton(
                        context,
                        'Sistema',
                        ThemeMode.system,
                        appTheme,
                        Icons.brightness_auto_rounded,
                      ),
                      _buildThemeButton(
                        context,
                        'Claro',
                        ThemeMode.light,
                        appTheme,
                        Icons.light_mode_rounded,
                      ),
                      _buildThemeButton(
                        context,
                        'Escuro',
                        ThemeMode.dark,
                        appTheme,
                        Icons.dark_mode_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Seção para editar dados da conta
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
            elevation: 4,
            color: Theme.of(context).cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dados da Conta',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                      IconButton(
                        icon: Icon(_isEditingProfile ? Icons.check_rounded : Icons.edit_rounded, color: Theme.of(context).primaryColor),
                        onPressed: () {
                          if (_isEditingProfile) {
                            _updateProfile();
                          } else {
                            setState(() {
                              _isEditingProfile = true;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _fullNameController,
                    labelText: 'Nome Completo',
                    enabled: _isEditingProfile,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'O nome completo não pode ser vazio.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _usernameController,
                    labelText: 'Nome de Usuário',
                    enabled: _isEditingProfile,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'O nome de usuário não pode ser vazio.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Botão para sair do app
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sair do App'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
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

  // Helper para construir os botões de tema
  Widget _buildThemeButton(
    BuildContext context,
    String text,
    ThemeMode mode,
    AppTheme appTheme,
    IconData icon,
  ) {
    final bool isSelected = appTheme.themeMode == mode;
    final Color selectedColor = Theme.of(context).primaryColor;
    final Color unselectedColor = Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6) ?? Colors.grey;

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor.withOpacity(0.2) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected ? selectedColor : Colors.transparent,
            width: isSelected ? 2.0 : 0.0,
          ),
        ),
        child: InkWell(
          onTap: () => appTheme.setThemeMode(mode),
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 30,
                  color: isSelected ? selectedColor : unselectedColor,
                ),
                const SizedBox(height: 8),
                Text(
                  text,
                  style: GoogleFonts.inter(
                    color: isSelected ? selectedColor : unselectedColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

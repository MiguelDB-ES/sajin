import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sajin/services/auth_service.dart';
import 'package:sajin/utils/app_theme.dart';
import 'package:sajin/screens/entry_screen.dart';
import 'package:sajin/models/user.dart'; // Importar o modelo User
import 'package:sajin/utils/database_helper.dart'; // Importar o DatabaseHelper
import 'package:sajin/widgets/custom_text_field.dart'; // Importar CustomTextField

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

    return SingleChildScrollView( // Adicionado SingleChildScrollView para evitar overflow
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
                title: const Text('Mudar Tema do App'),
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
          // Seção para editar dados da conta
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            elevation: 2,
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
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                      IconButton(
                        icon: Icon(_isEditingProfile ? Icons.check : Icons.edit, color: Theme.of(context).primaryColor),
                        onPressed: () {
                          if (_isEditingProfile) {
                            _updateProfile(); // Salva as alterações
                          } else {
                            setState(() {
                              _isEditingProfile = true; // Entra no modo de edição
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
                    enabled: _isEditingProfile, // Usando o parâmetro 'enabled'
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
                    enabled: _isEditingProfile, // Usando o parâmetro 'enabled'
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'O nome de usuário não pode ser vazio.';
                      }
                      return null;
                    },
                  ),
                  // Você pode adicionar campos para email e senha aqui,
                  // mas a lógica de atualização seria mais complexa devido à unicidade e hash de senha.
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

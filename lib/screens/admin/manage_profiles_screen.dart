import 'package:flutter/material.dart';
import 'package:sajin/models/user.dart';
import 'package:sajin/utils/database_helper.dart';
import 'package:sajin/screens/profile_screen.dart'; // Para navegar para o perfil do usuário

class ManageProfilesScreen extends StatefulWidget {
  const ManageProfilesScreen({super.key});

  @override
  State<ManageProfilesScreen> createState() => _ManageProfilesScreenState();
}

class _ManageProfilesScreenState extends State<ManageProfilesScreen> {
  List<User> _allUsers = []; // Todos os usuários
  List<User> _filteredUsers = []; // Usuários filtrados
  bool _isLoading = true; // Estado de carregamento
  final TextEditingController _searchController = TextEditingController(); // Controlador para a busca

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  // Busca todos os usuários do banco de dados
  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final dbHelper = DatabaseHelper.instance;
      final users = await dbHelper.getAllUsers();
      setState(() {
        _allUsers = users;
        _filteredUsers = users; // Inicialmente, todos os usuários são exibidos
      });
    } catch (e) {
      print('Erro ao carregar usuários: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar perfis de usuários.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Filtra os usuários com base na query de busca
  void _filterUsers(String query) {
    final lowerCaseQuery = query.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final fullName = user.fullName.toLowerCase();
        final username = user.username.toLowerCase();
        final email = user.email.toLowerCase();
        return fullName.contains(lowerCaseQuery) ||
               username.contains(lowerCaseQuery) ||
               email.contains(lowerCaseQuery);
      }).toList();
    });
  }

  // Alterna o status de ativo/inativo de um usuário
  Future<void> _toggleUserStatus(User user) async {
    final dbHelper = DatabaseHelper.instance;
    final updatedUser = user.copy(isActive: !user.isActive);
    await dbHelper.updateUser(updatedUser);
    _fetchUsers(); // Recarrega a lista de usuários
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Status de ${user.username} atualizado para ${updatedUser.isActive ? 'Ativo' : 'Inativo'}.')),
    );
  }

  // Deleta um usuário
  void _confirmDeleteUser(User user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text('Tem certeza de que deseja excluir o usuário ${user.username}? Esta ação é irreversível e excluirá também todas as postagens e comentários do usuário.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                await DatabaseHelper.instance.deleteUser(user.id!);
                Navigator.of(context).pop();
                _fetchUsers(); // Recarrega a lista de usuários
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Usuário ${user.username} excluído com sucesso!')),
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar usuários por nome, email ou username...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).inputDecorationTheme.fillColor,
            ),
            onChanged: _filterUsers,
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum usuário encontrado.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: user.isActive ? Colors.blue : Colors.grey,
                              child: Text(
                                user.username[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(user.username),
                            subtitle: Text(user.email),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(user.isActive ? Icons.toggle_on : Icons.toggle_off,
                                      color: user.isActive ? Colors.green : Colors.red),
                                  onPressed: () => _toggleUserStatus(user),
                                  tooltip: user.isActive ? 'Desativar Usuário' : 'Ativar Usuário',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmDeleteUser(user),
                                  tooltip: 'Excluir Usuário',
                                ),
                              ],
                            ),
                            onTap: () {
                              // Navegar para a tela de perfil do usuário (somente visualização)
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfileScreen(userId: user.id),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

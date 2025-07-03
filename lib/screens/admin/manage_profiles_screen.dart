import 'package:flutter/material.dart';
import 'package:sajin/models/user.dart';
import 'package:sajin/utils/database_helper.dart';
import 'package:sajin/screens/profile_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageProfilesScreen extends StatefulWidget {
  const ManageProfilesScreen({super.key});

  @override
  State<ManageProfilesScreen> createState() => _ManageProfilesScreenState();
}

class _ManageProfilesScreenState extends State<ManageProfilesScreen> {
  List<User> _allUsers = [];
  List<User> _filteredUsers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final dbHelper = DatabaseHelper.instance;
      final users = await dbHelper.getAllUsers();
      setState(() {
        _allUsers = users;
        _filteredUsers = users;
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

  Future<void> _toggleUserStatus(User user) async {
    final dbHelper = DatabaseHelper.instance;
    final updatedUser = user.copy(isActive: !user.isActive);
    await dbHelper.updateUser(updatedUser);
    _fetchUsers();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Status de ${user.username} atualizado para ${updatedUser.isActive ? 'Ativo' : 'Inativo'}.')),
    );
  }

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
                _fetchUsers();
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
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).inputDecorationTheme.fillColor,
              hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
            ),
            style: GoogleFonts.inter(color: Theme.of(context).textTheme.bodyLarge?.color),
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
                          Icon(Icons.person_off_rounded, size: 80, color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.4)),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum usuário encontrado.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6)),
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
                          color: Theme.of(context).cardColor,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: user.isActive ? Theme.of(context).primaryColor : Colors.grey.withOpacity(0.5),
                              child: Text(
                                user.username[0].toUpperCase(),
                                style: GoogleFonts.inter(color: Theme.of(context).cardColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(user.username, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                            subtitle: Text(user.email, style: GoogleFonts.inter(color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7))),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(user.isActive ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                                      color: user.isActive ? Colors.green : Colors.red),
                                  onPressed: () => _toggleUserStatus(user),
                                  tooltip: user.isActive ? 'Desativar Usuário' : 'Ativar Usuário',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                                  onPressed: () => _confirmDeleteUser(user),
                                  tooltip: 'Excluir Usuário',
                                ),
                              ],
                            ),
                            onTap: () {
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

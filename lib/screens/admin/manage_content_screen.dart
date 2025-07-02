import 'package:flutter/material.dart';
import 'package:sajin/models/post.dart'; // Importação correta do modelo Post
import 'package:sajin/models/user.dart';
import 'package:sajin/utils/database_helper.dart';
import 'package:sajin/widgets/post_card.dart'; // Importação correta do widget PostCard
import 'package:intl/intl.dart';

class ManageContentScreen extends StatefulWidget {
  const ManageContentScreen({super.key});

  @override
  State<ManageContentScreen> createState() => _ManageContentScreenState();
}

class _ManageContentScreenState extends State<ManageContentScreen> {
  List<Post> _allPosts = []; // Todos os posts
  List<Post> _filteredPosts = []; // Posts filtrados
  bool _isLoading = true; // Estado de carregamento
  final TextEditingController _searchController = TextEditingController(); // Controlador para a busca

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  // Busca todos os posts e seus usuários
  Future<void> _fetchPosts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final dbHelper = DatabaseHelper.instance;
      final posts = await dbHelper.getAllPosts();
      final users = await dbHelper.getAllUsers(); // Busca todos os usuários para mapear

      List<Post> postsWithUsers = [];
      for (var post in posts) {
        final user = users.firstWhere(
          (u) => u.id == post.userId,
          orElse: () => const User(
            id: -1,
            fullName: 'Desconhecido',
            email: '',
            password: '',
            dateOfBirth: '',
            username: 'Desconhecido',
          ),
        );
        postsWithUsers.add(post.copy(
          username: user.username,
          userProfilePicture: user.profilePicture,
        ));
      }
      setState(() {
        _allPosts = postsWithUsers;
        _filteredPosts = postsWithUsers; // Inicialmente, todos os posts são exibidos
      });
    } catch (e) {
      print('Erro ao carregar posts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar postagens para gerenciamento.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Filtra os posts com base na query de busca
  void _filterPosts(String query) {
    final lowerCaseQuery = query.toLowerCase();
    setState(() {
      _filteredPosts = _allPosts.where((post) {
        final description = post.description?.toLowerCase() ?? '';
        final username = post.username?.toLowerCase() ?? '';
        return description.contains(lowerCaseQuery) || username.contains(lowerCaseQuery);
      }).toList();
    });
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
              hintText: 'Buscar posts por descrição ou usuário...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).inputDecorationTheme.fillColor,
            ),
            onChanged: _filterPosts,
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredPosts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.feed_outlined, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhuma postagem para gerenciar ou nenhum resultado encontrado.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredPosts.length,
                      itemBuilder: (context, index) {
                        final post = _filteredPosts[index];
                        return PostCard(
                          post: post,
                          showDeleteButton: true, // Sempre mostra o botão de deletar para o admin
                          onPostDeleted: _fetchPosts, // Recarrega os posts após a exclusão
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

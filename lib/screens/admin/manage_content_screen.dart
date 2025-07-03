import 'package:flutter/material.dart';
import 'package:sajin/models/post.dart'; // Importação correta do modelo Post
import 'package:sajin/models/user.dart';
import 'package:sajin/utils/database_helper.dart';
import 'package:sajin/widgets/post_card.dart'; // Importação correta do widget PostCard
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart'; // Importação do pacote shimmer
import 'package:google_fonts/google_fonts.dart'; // Importação para usar GoogleFonts

class ManageContentScreen extends StatefulWidget {
  const ManageContentScreen({super.key});

  @override
  State<ManageContentScreen> createState() => _ManageContentScreenState();
}

class _ManageContentScreenState extends State<ManageContentScreen> {
  List<Post> _allPosts = []; // Todos os posts
  List<Post> _filteredPosts = []; // Posts filtrados
  List<User> _allUsers = []; // Todos os utilizadores para o filtro (mantido para enriquecer posts)
  bool _isLoading = true; // Estado de carregamento
  final TextEditingController _searchController = TextEditingController(); // Controlador para a busca

  @override
  void initState() {
    super.initState();
    _fetchPostsAndUsers();
  }

  // Busca todos os posts e utilizadores
  Future<void> _fetchPostsAndUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Simula um atraso para ver o shimmer effect
      await Future.delayed(const Duration(seconds: 1));

      final dbHelper = DatabaseHelper.instance;
      final posts = await dbHelper.getAllPosts();
      final users = await dbHelper.getAllUsers();

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
        _allUsers = users; // Ainda necessário para enriquecer os dados do post
        _applyFilters(); // Aplica os filtros iniciais
      });
    } catch (e) {
      print('Erro ao carregar posts ou utilizadores: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar postagens para gerenciamento.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Aplica todos os filtros aos posts
  void _applyFilters() {
    List<Post> tempFilteredPosts = List.from(_allPosts);

    // Filtro por termo de busca (descrição ou username)
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      tempFilteredPosts = tempFilteredPosts.where((post) {
        final description = post.description?.toLowerCase() ?? '';
        final username = post.username?.toLowerCase() ?? '';
        return description.contains(query) || username.contains(query);
      }).toList();
    }

    // O filtro por utilizador selecionado foi removido

    setState(() {
      _filteredPosts = tempFilteredPosts;
    });
  }

  // Widget de placeholder para o PostCard (Shimmer Effect)
  Widget _buildShimmerPostCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // Cor de fundo do card
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 120,
                          height: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 80,
                          height: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: double.infinity,
              height: 280,
              color: Colors.white,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: double.infinity,
                    height: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 150,
                    height: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12.0),
                Row(
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 80,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 100,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar posts por descrição ou utilizador...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                ),
                onChanged: (value) => _applyFilters(), // Aplica filtros ao mudar o texto
              ),
              // O SizedBox e o DropdownButtonFormField foram removidos daqui
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? ListView.builder(
                  itemCount: 3, // Exibe 3 shimmer cards enquanto carrega
                  itemBuilder: (context, index) => _buildShimmerPostCard(),
                )
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
                            style: GoogleFonts.inter(fontSize: 18, color: Colors.grey[600]),
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
                          onPostDeleted: _fetchPostsAndUsers, // Recarrega os posts após a exclusão
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

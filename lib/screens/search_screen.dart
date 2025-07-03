import 'package:flutter/material.dart';
import 'package:sajin/models/post.dart';
import 'package:sajin/models/user.dart';
import 'package:sajin/utils/database_helper.dart';
import 'package:sajin/widgets/post_card.dart';
import 'package:shimmer/shimmer.dart'; // Importação do pacote shimmer
import 'package:google_fonts/google_fonts.dart'; // Importação para usar GoogleFonts

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Post> _searchResults = []; // Resultados da pesquisa
  bool _isSearching = false; // Estado de pesquisa
  bool _hasSearched = false; // Indica se uma pesquisa já foi realizada

  @override
  void initState() {
    super.initState();
  }

  // Realiza a busca por posts
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = true;
        _isSearching = false; // Garante que o shimmer pare se a busca for vazia
      });
      return;
    }

    setState(() {
      _isSearching = true; // Ativa o indicador de pesquisa
      _hasSearched = true;
    });

    // Simula um atraso para ver o shimmer effect
    await Future.delayed(const Duration(seconds: 1));

    final dbHelper = DatabaseHelper.instance;
    final allPosts = await dbHelper.getAllPosts(); // Busca todos os posts
    final allUsers = await dbHelper.getAllUsers(); // Busca todos os usuários

    List<Post> filteredPosts = [];

    // Filtra posts pela descrição ou pelo nome de usuário
    for (var post in allPosts) {
      final user = allUsers.firstWhere(
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

      final postDescription = post.description?.toLowerCase() ?? '';
      final username = user.username.toLowerCase();
      final lowerCaseQuery = query.toLowerCase();

      if (postDescription.contains(lowerCaseQuery) || username.contains(lowerCaseQuery)) {
        filteredPosts.add(post.copy(
          username: user.username,
          userProfilePicture: user.profilePicture,
        ));
      }
    }

    setState(() {
      _searchResults = filteredPosts;
      _isSearching = false; // Desativa o indicador de pesquisa
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Campo de pesquisa
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por descrição ou nome de utilizador...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).inputDecorationTheme.fillColor,
            ),
            onChanged: (value) {
              // Dispara a pesquisa com um pequeno atraso para evitar muitas chamadas
              Future.delayed(const Duration(milliseconds: 300), () {
                _performSearch(value);
              });
            },
            onSubmitted: _performSearch, // Dispara a pesquisa ao pressionar Enter
          ),
          const SizedBox(height: 16),
          // Exibe o indicador de carregamento ou os resultados
          _isSearching
              ? Expanded(
                  child: ListView.builder(
                    itemCount: 3, // Exibe 3 shimmer cards enquanto carrega
                    itemBuilder: (context, index) => _buildShimmerPostCard(),
                  ),
                )
              : _hasSearched && _searchResults.isEmpty
                  ? Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sentiment_dissatisfied, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhum resultado encontrado para "${_searchController.text}".',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(fontSize: 18, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Expanded(
                      child: ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final post = _searchResults[index];
                          // Passa o objeto Post completo para o PostCard
                          return PostCard(post: post);
                        },
                      ),
                    ),
        ],
      ),
    );
  }
}

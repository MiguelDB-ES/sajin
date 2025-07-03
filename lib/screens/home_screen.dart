import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import para SystemNavigator.pop
import 'package:provider/provider.dart';
import 'package:sajin/screens/add_photo_screen.dart';
import 'package:sajin/screens/profile_screen.dart';
import 'package:sajin/screens/search_screen.dart';
import 'package:sajin/screens/settings_screen.dart';
import 'package:sajin/widgets/post_card.dart';
import 'package:sajin/models/post.dart'; // Importação correta do modelo Post
import 'package:sajin/models/user.dart';
import 'package:sajin/utils/database_helper.dart';
import 'package:sajin/services/auth_service.dart';
import 'dart:io';
import 'package:shimmer/shimmer.dart'; // Importação do pacote shimmer
import 'package:google_fonts/google_fonts.dart'; // Importação para usar GoogleFonts

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Índice da aba selecionada
  List<Post> _posts = []; // Lista de posts para o feed
  bool _isLoading = true; // Estado de carregamento
  User? _currentUser; // Usuário logado
  DateTime? _lastExitTime; // Para controlar o "dois cliques para sair"

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserAndPosts();
  }

  // Busca o usuário atual e os posts
  Future<void> _fetchCurrentUserAndPosts() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    setState(() {
      _currentUser = authService.currentUser;
    });
    await _fetchPosts();
  }

  // Busca todos os posts do banco de dados
  Future<void> _fetchPosts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Simula um atraso para ver o shimmer effect
      await Future.delayed(const Duration(seconds: 1));
      final dbHelper = DatabaseHelper.instance;
      final posts = await dbHelper.getAllPosts();
      // Para cada post, busca o usuário correspondente
      List<Post> postsWithUsers = [];
      for (var post in posts) {
        final user = await dbHelper.getUserById(post.userId);
        if (user != null) {
          postsWithUsers.add(post.copy(
            username: user.username,
            userProfilePicture: user.profilePicture,
          ));
        }
      }
      setState(() {
        _posts = postsWithUsers;
      });
    } catch (e) {
      print('Erro ao carregar posts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar postagens.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Widget de placeholder para o Shimmer Effect
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

  // Widgets para cada tela da navegação inferior
  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        // Feed
        return RefreshIndicator(
          onRefresh: _fetchPosts, // Permite puxar para recarregar
          child: _isLoading
              ? ListView.builder(
                  itemCount: 3, // Exibe 3 shimmer cards enquanto carrega
                  itemBuilder: (context, index) => _buildShimmerPostCard(),
                )
              : _posts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_library, size: 80, color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.4)),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhuma postagem ainda. Seja o primeiro a compartilhar!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6)),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _posts.length,
                      itemBuilder: (context, index) {
                        final post = _posts[index];
                        return PostCard(
                          post: post,
                          onPostDeleted: _fetchPosts, // Recarrega o feed após a exclusão
                        );
                      },
                    ),
        );
      case 1:
        return const SearchScreen(); // Tela de busca
      case 2:
        return AddPhotoScreen(onPostAdded: _fetchPosts); // Tela de adicionar foto
      case 3:
        return ProfileScreen(
          userId: _currentUser?.id,
          onProfileUpdated: _fetchCurrentUserAndPosts, // Recarrega perfil se atualizado
          onPostDeleted: _fetchPosts, // Recarrega o feed se um post for deletado do perfil
        ); // Tela de perfil
      case 4:
        return const SettingsScreen(); // Tela de configurações
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

  @override
  Widget build(BuildContext context) {
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
          title: const Text('Sajin'),
          centerTitle: true,
          automaticallyImplyLeading: false, // Remove o botão de retorno padrão
        ),
        body: _getScreen(_selectedIndex), // Exibe a tela selecionada
        bottomNavigationBar: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: const Icon(Icons.home),
              label: 'Feed',
              backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.search),
              label: 'Buscar',
              backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.add_a_photo),
              label: 'Adicionar',
              backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
            ),
            BottomNavigationBarItem(
              icon: CircleAvatar(
                radius: 12,
                backgroundColor: Theme.of(context).primaryColor, // Usar a cor primária do tema
                // Exibe a foto de perfil do usuário logado ou a primeira letra do nome
                backgroundImage: _currentUser?.profilePicture != null && File(_currentUser!.profilePicture!).existsSync()
                    ? FileImage(File(_currentUser!.profilePicture!))
                    : null,
                child: _currentUser?.profilePicture == null || !File(_currentUser!.profilePicture!).existsSync()
                    ? Text(
                        _currentUser?.username[0].toUpperCase() ?? '?',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 10), // Usar GoogleFonts
                      )
                    : null,
              ),
              label: 'Perfil',
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
          type: BottomNavigationBarType.fixed, // Garante que todos os itens são exibidos
        ),
      ),
    );
  }
}

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

  // Widgets para cada tela da navegação inferior
  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        // Feed
        return RefreshIndicator(
          onRefresh: _fetchPosts, // Permite puxar para recarregar
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _posts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_library, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhuma postagem ainda. Seja o primeiro a compartilhar!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
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
                backgroundColor: Colors.blue,
                // Exibe a foto de perfil do usuário logado ou a primeira letra do nome
                backgroundImage: _currentUser?.profilePicture != null && File(_currentUser!.profilePicture!).existsSync()
                    ? FileImage(File(_currentUser!.profilePicture!))
                    : null,
                child: _currentUser?.profilePicture == null || !File(_currentUser!.profilePicture!).existsSync()
                    ? Text(
                        _currentUser?.username[0].toUpperCase() ?? '?',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
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

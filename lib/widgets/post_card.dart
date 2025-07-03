import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sajin/models/post.dart'; // Importação direta do modelo Post
import 'package:sajin/models/user.dart';
import 'package:sajin/utils/database_helper.dart';
import 'package:sajin/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final User? postUser;
  final VoidCallback? onPostDeleted;
  final bool showDeleteButton;

  const PostCard({
    super.key,
    required this.post,
    this.postUser,
    this.onPostDeleted,
    this.showDeleteButton = false,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  User? _displayUser;
  bool _isSaved = false;
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _showComments = false;
  final PageController _imagePageController = PageController(); // Controlador para as imagens do post
  int _currentImagePage = 0; // Índice da imagem atual no carrossel

  @override
  void initState() {
    super.initState();
    _loadPostUserAndSavedStatus();
    _loadComments();
    _imagePageController.addListener(() {
      setState(() {
        _currentImagePage = _imagePageController.page!.round();
      });
    });
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  Future<void> _loadPostUserAndSavedStatus() async {
    // Mover a chamada do Provider para antes do await
    final authService = Provider.of<AuthService>(context, listen: false);

    if (widget.postUser != null) {
      setState(() {
        _displayUser = widget.postUser;
      });
    } else {
      final user = await DatabaseHelper.instance.getUserById(widget.post.userId);
      setState(() {
        _displayUser = user;
      });
    }

    if (authService.currentUser != null) {
      final saved = await DatabaseHelper.instance.isPostSaved(
        authService.currentUser!.id!,
        widget.post.id!,
      );
      setState(() {
        _isSaved = saved;
      });
    }
  }

  Future<void> _loadComments() async {
    final comments = await DatabaseHelper.instance.getCommentsForPost(widget.post.id!);
    setState(() {
      _comments = comments;
    });
  }

  Future<void> _toggleSavePost() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa estar logado para salvar posts.')),
      );
      return;
    }

    if (_isSaved) {
      await DatabaseHelper.instance.unsavePost(
        authService.currentUser!.id!,
        widget.post.id!,
      );
    } else {
      await DatabaseHelper.instance.savePost(
        authService.currentUser!.id!,
        widget.post.id!,
      );
    }
    setState(() {
      _isSaved = !_isSaved;
    });
  }

  Future<void> _addComment() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa estar logado para comentar.')),
      );
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O comentário não pode ser vazio.')),
      );
      return;
    }

    final comment = {
      'postId': widget.post.id!,
      'userId': authService.currentUser!.id!,
      'commentText': _commentController.text.trim(),
      'commentDate': DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
    };

    await DatabaseHelper.instance.createComment(comment);
    _commentController.clear();
    _loadComments();
  }

  Future<void> _deleteComment(int commentId) async {
    await DatabaseHelper.instance.deleteComment(commentId);
    _loadComments();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comentário excluído com sucesso!')),
    );
  }

  void _confirmDeletePost() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text('Tem certeza de que deseja excluir esta postagem?'),
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
                await DatabaseHelper.instance.deletePost(widget.post.id!);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Postagem excluída com sucesso!')),
                );
                if (widget.onPostDeleted != null) {
                  widget.onPostDeleted!();
                }
              },
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildCommentsSection(User? currentUser) {
    if (!_showComments) {
      return [];
    }

    return [
      const Divider(height: 24, thickness: 0.5),
      Text('Comentários:', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
      const SizedBox(height: 12.0),
      _comments.isEmpty
          ? Center(child: Text('Nenhum comentário ainda.', style: GoogleFonts.inter(color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6), fontSize: 14)))
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                final comment = _comments[index];
                final commentUsername = comment['username'] ?? 'Utilizador';
                final commentProfilePicture = comment['profilePicture'];
                final commentText = comment['commentText'];
                final commentDate = comment['commentDate'];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                        backgroundImage: commentProfilePicture != null && File(commentProfilePicture).existsSync()
                            ? FileImage(File(commentProfilePicture))
                            : null,
                        child: commentProfilePicture == null || !File(commentProfilePicture).existsSync()
                            ? Text(commentUsername[0].toUpperCase(), style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).primaryColor))
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              commentUsername,
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color),
                            ),
                            Text(
                              commentText,
                              style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.9)),
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(commentDate)),
                              style: GoogleFonts.inter(color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.5), fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      if (currentUser != null && (currentUser.isAdmin || currentUser.id == comment['userId']))
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: Colors.redAccent),
                          onPressed: () => _deleteComment(comment['id']),
                          tooltip: 'Apagar Comentário',
                        ),
                    ],
                  ),
                );
              },
            ),
      const SizedBox(height: 16.0),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Adicionar um comentário...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
              ),
              style: GoogleFonts.inter(color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(25),
            ),
            child: IconButton(
              icon: Icon(Icons.send_rounded, color: Theme.of(context).cardColor),
              onPressed: _addComment,
              tooltip: 'Enviar Comentário',
            ),
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;

    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final List<Color> cardBackgroundGradientColors = isDarkMode
        ? [const Color(0xFF1E1E1E), const Color(0xFF262626)]
        : [const Color(0xFFFFFFFF), const Color(0xFFF0F0F0)];

    final List<Color> cardBorderGradientColors = isDarkMode
        ? [const Color(0xFF00C853), const Color(0xFF69F0AE)]
        : [const Color(0xFF4CAF50), const Color(0xFF8BC34A)];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        gradient: LinearGradient(
          colors: cardBorderGradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: cardBackgroundGradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                        backgroundImage: _displayUser?.profilePicture != null && File(_displayUser!.profilePicture!).existsSync()
                            ? FileImage(File(_displayUser!.profilePicture!))
                            : null,
                        child: _displayUser?.profilePicture == null || !File(_displayUser!.profilePicture!).existsSync()
                            ? Text(
                                _displayUser?.username[0].toUpperCase() ?? '?',
                                style: GoogleFonts.inter(color: Theme.of(context).primaryColor, fontSize: 20, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _displayUser?.username ?? 'Utilizador Desconhecido',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
                            ),
                            Text(
                              '${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(widget.post.postDate))}',
                              style: GoogleFonts.inter(color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6), fontSize: 12.0),
                            ),
                          ],
                        ),
                      ),
                      if (widget.showDeleteButton || (currentUser != null && currentUser.isAdmin))
                        IconButton(
                          icon: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 24),
                          onPressed: _confirmDeletePost,
                          tooltip: 'Eliminar Publicação',
                        ),
                    ],
                  ),
                ),
                // Exibe as imagens do post com PageView e indicadores
                if (widget.post.imagePaths.isNotEmpty)
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      SizedBox(
                        height: 280, // Altura ajustada
                        child: PageView.builder(
                          controller: _imagePageController,
                          itemCount: widget.post.imagePaths.length,
                          itemBuilder: (context, index) {
                            final imagePath = widget.post.imagePaths[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (BuildContext context) {
                                      return Scaffold(
                                        backgroundColor: Colors.black,
                                        appBar: AppBar(
                                          backgroundColor: Colors.black,
                                          iconTheme: const IconThemeData(color: Colors.white),
                                          leading: IconButton(
                                            icon: const Icon(Icons.close),
                                            onPressed: () => Navigator.of(context).pop(),
                                          ),
                                        ),
                                        body: Center(
                                          child: Hero(
                                            tag: 'postImage-${widget.post.id}-$index', // Tag única por imagem
                                            child: File(imagePath).existsSync()
                                                ? Image.file(
                                                    File(imagePath),
                                                    fit: BoxFit.contain,
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                  )
                                                : Icon(Icons.image_not_supported_rounded, size: 100, color: Colors.grey[700]),
                                          ),
                                        ),
                                      );
                                    },
                                    fullscreenDialog: true,
                                  ),
                                );
                              },
                              child: Hero(
                                tag: 'postImage-${widget.post.id}-$index',
                                child: File(imagePath).existsSync()
                                    ? Image.file(
                                        File(imagePath),
                                        width: double.infinity,
                                        height: 280,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: double.infinity,
                                        height: 280,
                                        color: Theme.of(context).cardColor.withOpacity(0.5),
                                        child: Center(
                                          child: Icon(Icons.image_not_supported_rounded, size: 60, color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.4)),
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Indicadores de página
                      Positioned(
                        bottom: 10,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(widget.post.imagePaths.length, (index) {
                            return Container(
                              width: 8.0,
                              height: 8.0,
                              margin: const EdgeInsets.symmetric(horizontal: 4.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImagePage == index
                                    ? Colors.white // Cor do indicador ativo
                                    : Colors.grey.withOpacity(0.5), // Cor do indicador inativo
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  )
                else
                  // Placeholder se não houver imagens
                  Container(
                    width: double.infinity,
                    height: 280,
                    color: Theme.of(context).cardColor.withOpacity(0.5),
                    child: Center(
                      child: Icon(Icons.image_not_supported_rounded, size: 60, color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.4)),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.post.description != null && widget.post.description!.isNotEmpty)
                        Text(
                          widget.post.description!,
                          style: GoogleFonts.inter(fontSize: 15.0, color: Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                      const SizedBox(height: 12.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: _toggleSavePost,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _isSaved ? Theme.of(context).primaryColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _isSaved ? Theme.of(context).primaryColor : (Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.3) ?? Colors.grey),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _isSaved ? FontAwesomeIcons.solidBookmark : FontAwesomeIcons.bookmark,
                                    size: 20,
                                    color: _isSaved ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Guardar',
                                    style: GoogleFonts.inter(
                                      color: _isSaved ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showComments = !_showComments;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.3) ?? Colors.grey,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.comment_rounded, size: 20, color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Comentar',
                                    style: GoogleFonts.inter(
                                      color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      ..._buildCommentsSection(currentUser),
                    ],
                  ),
                ), // Adicionada vírgula aqui
              ],
            ),
          ),
        ),
      ),
    );
  }
}

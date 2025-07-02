import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sajin/models/post.dart'; // Importação correta do modelo Post
import 'package:sajin/models/user.dart';
import 'package:sajin/utils/database_helper.dart';
import 'package:sajin/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final User? postUser; // Opcional, para passar o usuário do post diretamente
  final VoidCallback? onPostDeleted; // Callback para quando um post é deletado
  final bool showDeleteButton; // Para admins ou o próprio usuário

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

  @override
  void initState() {
    super.initState();
    _loadPostUserAndSavedStatus();
    _loadComments();
  }

  // Carrega o usuário do post e verifica se o post está salvo
  Future<void> _loadPostUserAndSavedStatus() async {
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

    final authService = Provider.of<AuthService>(context, listen: false);
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

  // Carrega os comentários do post
  Future<void> _loadComments() async {
    final comments = await DatabaseHelper.instance.getCommentsForPost(widget.post.id!);
    setState(() {
      _comments = comments;
    });
  }

  // Alterna o status de salvamento do post
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

  // Adiciona um comentário ao post
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
    _loadComments(); // Recarrega os comentários
  }

  // Deleta um comentário
  Future<void> _deleteComment(int commentId) async {
    await DatabaseHelper.instance.deleteComment(commentId);
    _loadComments(); // Recarrega os comentários
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comentário excluído com sucesso!')),
    );
  }

  // Confirmação para deletar um post
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
                  widget.onPostDeleted!(); // Chama o callback para atualizar a lista
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue,
                  // Exibe a imagem de perfil ou a primeira letra do nome
                  backgroundImage: _displayUser?.profilePicture != null && File(_displayUser!.profilePicture!).existsSync()
                      ? FileImage(File(_displayUser!.profilePicture!))
                      : null,
                  child: _displayUser?.profilePicture == null || !File(_displayUser!.profilePicture!).existsSync()
                      ? Text(
                          _displayUser?.username[0].toUpperCase() ?? '?',
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                        )
                      : null,
                ),
                const SizedBox(width: 8.0),
                Text(
                  _displayUser?.username ?? 'Usuário Desconhecido',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (widget.showDeleteButton || (currentUser != null && currentUser.isAdmin))
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _confirmDeletePost,
                  ),
              ],
            ),
          ),
          // Exibe a imagem do post
          widget.post.imagePath.isNotEmpty && File(widget.post.imagePath).existsSync()
              ? Image.file(
                  File(widget.post.imagePath),
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: double.infinity,
                  height: 250,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                  ),
                ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.post.description != null && widget.post.description!.isNotEmpty)
                  Text(
                    widget.post.description!,
                    style: const TextStyle(fontSize: 16.0),
                  ),
                const SizedBox(height: 8.0),
                Text(
                  'Postado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(widget.post.postDate))}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12.0),
                ),
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botão de comentários
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showComments = !_showComments;
                        });
                      },
                      icon: const Icon(Icons.comment, size: 20),
                      label: const Text('Comentários'),
                    ),
                    // Ícone de marcador de livro para salvar
                    IconButton(
                      icon: Icon(
                        _isSaved ? FontAwesomeIcons.solidBookmark : FontAwesomeIcons.bookmark,
                        color: _isSaved ? Colors.blue : Colors.grey,
                      ),
                      onPressed: _toggleSavePost,
                    ),
                  ],
                ),
                if (_showComments) ...[
                  const Divider(),
                  const Text('Comentários:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  // Lista de comentários
                  _comments.isEmpty
                      ? const Text('Nenhum comentário ainda.')
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final comment = _comments[index];
                            final commentUsername = comment['username'] ?? 'Usuário';
                            final commentProfilePicture = comment['profilePicture'];
                            final commentText = comment['commentText'];
                            final commentDate = comment['commentDate'];

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 15,
                                    backgroundColor: Colors.grey[300],
                                    backgroundImage: commentProfilePicture != null && File(commentProfilePicture).existsSync()
                                        ? FileImage(File(commentProfilePicture))
                                        : null,
                                    child: commentProfilePicture == null || !File(commentProfilePicture).existsSync()
                                        ? Text(commentUsername[0].toUpperCase(), style: const TextStyle(fontSize: 12))
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          commentUsername,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        Text(
                                          commentText,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        Text(
                                          DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(commentDate)),
                                          style: TextStyle(color: Colors.grey[600], fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (currentUser != null && (currentUser.isAdmin || currentUser.id == comment['userId']))
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 16, color: Colors.red),
                                      onPressed: () => _deleteComment(comment['id']),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 8.0),
                  // Campo para adicionar comentário
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Adicionar um comentário...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _addComment,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

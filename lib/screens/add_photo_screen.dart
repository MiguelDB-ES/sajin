import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sajin/models/post.dart';
import 'package:sajin/services/auth_service.dart';
import 'package:sajin/services/image_picker_service.dart';
import 'package:sajin/utils/database_helper.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class AddPhotoScreen extends StatefulWidget {
  final VoidCallback? onPostAdded; // Callback para notificar a adição de um post

  const AddPhotoScreen({super.key, this.onPostAdded});

  @override
  State<AddPhotoScreen> createState() => _AddPhotoScreenState();
}

class _AddPhotoScreenState extends State<AddPhotoScreen> {
  final ImagePickerService _imagePickerService = ImagePickerService();
  final TextEditingController _descriptionController = TextEditingController();
  File? _selectedImage; // Imagem selecionada
  bool _isLoading = false; // Estado de carregamento

  // Seleciona uma imagem da galeria
  Future<void> _pickImage() async {
    final image = await _imagePickerService.pickImageFromGallery();
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  // Publica a imagem
  Future<void> _publishPost() async {
    if (_selectedImage == null) {
      _showSnackBar('Por favor, selecione uma imagem para publicar.');
      return;
    }

    setState(() {
      _isLoading = true; // Ativa o indicador de carregamento
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      _showSnackBar('Você precisa estar logado para publicar.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Salva a imagem localmente
      final savedImagePath = await _imagePickerService.saveImageLocally(_selectedImage!);
      if (savedImagePath == null) {
        _showSnackBar('Erro ao salvar a imagem localmente.');
        return;
      }

      // Cria o objeto Post
      final newPost = Post(
        userId: currentUser.id!,
        imagePath: savedImagePath,
        description: _descriptionController.text.trim(),
        postDate: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
        // Removidos userImage e username daqui, pois são preenchidos ao carregar o post
        // e não são campos diretos de criação do Post no banco de dados.
      );

      // Salva o post no banco de dados
      await DatabaseHelper.instance.createPost(newPost); // Corrigido de insertPost para createPost

      _showSnackBar('Postagem publicada com sucesso!');
      _descriptionController.clear();
      setState(() {
        _selectedImage = null; // Limpa a imagem selecionada
      });

      if (widget.onPostAdded != null) {
        widget.onPostAdded!(); // Chama o callback para notificar a adição do post
      }
    } catch (e) {
      _showSnackBar('Erro ao publicar postagem: $e');
    } finally {
      setState(() {
        _isLoading = false; // Desativa o indicador de carregamento
      });
    }
  }

  // Exibe um SnackBar com a mensagem
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Adicionado Scaffold aqui
      appBar: AppBar(
        title: const Text('Adicionar Foto'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Área para exibir a imagem selecionada
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 50, color: Colors.grey[600]),
                            const SizedBox(height: 8),
                            Text(
                              'Toque para anexar foto',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              // Campo para descrição
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Adicionar descrição...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                ),
              ),
              const SizedBox(height: 32),
              // Botão de Publicar
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _publishPost,
                      child: const Text('Publicar'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
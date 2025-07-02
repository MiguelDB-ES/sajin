import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importado para TextInputFormatter

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters; // Novo parâmetro para máscaras
  final VoidCallback? onTap; // Novo parâmetro para o evento de toque
  final bool readOnly; // Novo parâmetro para tornar o campo somente leitura

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.suffixIcon,
    this.maxLines = 1,
    this.inputFormatters, // Adicionado ao construtor
    this.onTap, // Adicionado ao construtor
    this.readOnly = false, // Adicionado ao construtor
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        inputFormatters: inputFormatters, // Aplicando os formatadores de entrada
        onTap: onTap, // Aplicando o callback de toque
        readOnly: readOnly, // Aplicando o modo somente leitura
        decoration: InputDecoration(
          labelText: labelText,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).inputDecorationTheme.fillColor,
          focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
          enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
        ),
      ),
    );
  }
}

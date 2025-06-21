import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

import '../../controllers/perfil_controller.dart'; // Verifica que la ruta sea correcta

class PerfilScreen extends StatefulWidget {
  final User user;
  const PerfilScreen({required this.user, Key? key}) : super(key: key);

  @override
  _PerfilScreenState createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _nombre;
  File? _nuevaImagen;
  final List<Map<String, String>> _contactos = List.generate(
    5,
    (_) => {"nombre": "", "email": ""},
  );

  final PerfilController _perfilController = PerfilController();

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _nuevaImagen = File(image.path);
      });
    }
  }

  Future<void> _guardarCambios() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        await _perfilController.actualizarPerfil(
          nombre: _nombre ?? widget.user.displayName ?? "",
          nuevaImagen: _nuevaImagen,
          contactos: _contactos,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Perfil actualizado correctamente")),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al actualizar: ${e.toString()}")),
        );
      }
    }
  }

  Widget _buildContactoInput(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Contacto ${index + 1}",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: _contactos[index]["nombre"],
          decoration: const InputDecoration(labelText: 'Nombre'),
          style: GoogleFonts.poppins(),
          onSaved: (value) => _contactos[index]["nombre"] = value ?? "",
        ),
        TextFormField(
          initialValue: _contactos[index]["email"],
          decoration: const InputDecoration(labelText: 'Correo electrónico'),
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.poppins(),
          validator: (value) {
            if (value != null && value.isNotEmpty && !value.contains('@')) {
              return 'Correo inválido';
            }
            return null;
          },
          onSaved: (value) => _contactos[index]["email"] = value ?? "",
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildGradientButton(String text, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(255, 51, 129, 244),
              Colors.lightBlue,
              Colors.cyan,
              Colors.white,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Mi Perfil",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 51, 129, 244),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _seleccionarImagen,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _nuevaImagen != null
                      ? FileImage(_nuevaImagen!)
                      : (user.photoURL != null
                                ? CachedNetworkImageProvider(user.photoURL!)
                                : const AssetImage("assets/default_avatar.png"))
                            as ImageProvider,
                  child: _nuevaImagen == null && user.photoURL == null
                      ? const Icon(Icons.account_circle, size: 60)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: user.displayName ?? "",
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo obligatorio' : null,
                onSaved: (value) => _nombre = value,
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Contactos de confianza",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(5, (index) => _buildContactoInput(index)),
              const SizedBox(height: 24),
              _buildGradientButton("Guardar cambios", _guardarCambios),
            ],
          ),
        ),
      ),
    );
  }
}

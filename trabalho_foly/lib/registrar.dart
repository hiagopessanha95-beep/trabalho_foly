import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trabalho_foly/authentication.dart';
import 'package:trabalho_foly/principal.dart';
import 'package:trabalho_foly/turmas.dart';

class Registrar extends StatelessWidget {
  const Registrar({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4A00E0),
              Color(0xFF8E2DE2),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Align(
              alignment: const Alignment(0, -0.3),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ÍCONE / LOGO EM CÍRCULO
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_outlined,
                        size: 52,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 8),
                    Text(
                      'Crie sua conta',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 20,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // CARD BRANCO COM O FORMULÁRIO
                    Container(
                      constraints: const BoxConstraints(maxWidth: 440),
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const RegistrarForm(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegistrarForm extends StatefulWidget {
  const RegistrarForm({Key? key}) : super(key: key);

  @override
  _RegistrarFormState createState() => _RegistrarFormState();
}

class _RegistrarFormState extends State<RegistrarForm> {
  final _formKey = GlobalKey<FormState>();

  String? nome;
  String? email;
  String? senha;
  String? confirmarSenha;
  String? turma;

  bool _obscureText = true;
  bool _obscureTextConfirmar = true;
  bool _isLoading = false;

  static const Color roxoPrincipal = Color(0xFF6A11CB);
  static const Color roxoSecundario = Color(0xFF8E2DE2);

  InputDecoration _buildDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 15),
      prefixIcon: Icon(icon, color: roxoPrincipal, size: 24),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF5F3FB),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(color: roxoPrincipal, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // NOME
          TextFormField(
            decoration: _buildDecoration(
              label: 'Nome',
              icon: Icons.person_outline,
            ),
            style: const TextStyle(fontSize: 16),
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Campo vazio';
              }
              return null;
            },
            onSaved: (val) {
              nome = val?.trim();
            },
          ),

          const SizedBox(height: 18),

          // EMAIL
          TextFormField(
            decoration: _buildDecoration(
              label: 'Email',
              icon: Icons.email_outlined,
            ),
            style: const TextStyle(fontSize: 16),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Campo vazio';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Email inválido';
              }
              return null;
            },
            onSaved: (val) {
              email = val?.trim();
            },
          ),

          const SizedBox(height: 18),

          // TURMA
          DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: _buildDecoration(
              label: 'Turma',
              icon: Icons.groups_outlined,
            ),
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            borderRadius: BorderRadius.circular(16),
            items: listaTurmas
                .map(
                  (t) => DropdownMenuItem<String>(
                    value: t,
                    child: Text(t),
                  ),
                )
                .toList(),
            onChanged: _isLoading
                ? null
                : (val) {
                    setState(() => turma = val);
                  },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Selecione sua turma';
              }
              return null;
            },
            onSaved: (val) {
              turma = val;
            },
          ),

          const SizedBox(height: 18),

          // SENHA
          TextFormField(
            decoration: _buildDecoration(
              label: 'Senha',
              icon: Icons.lock_outline,
              suffixIcon: GestureDetector(
                onTap: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
                child: Icon(
                  _obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey[600],
                  size: 24,
                ),
              ),
            ),
            style: const TextStyle(fontSize: 16),
            obscureText: _obscureText,
            onSaved: (val) {
              senha = val;
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Campo vazio';
              }
              if (value.length < 6) {
                return 'Mínimo de 6 caracteres';
              }
              return null;
            },
          ),

          const SizedBox(height: 18),

          // CONFIRMAR SENHA
          TextFormField(
            decoration: _buildDecoration(
              label: 'Confirmar senha',
              icon: Icons.lock_outline,
              suffixIcon: GestureDetector(
                onTap: () {
                  setState(() {
                    _obscureTextConfirmar = !_obscureTextConfirmar;
                  });
                },
                child: Icon(
                  _obscureTextConfirmar
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey[600],
                  size: 24,
                ),
              ),
            ),
            style: const TextStyle(fontSize: 16),
            obscureText: _obscureTextConfirmar,
            onSaved: (val) {
              confirmarSenha = val;
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Campo vazio';
              }
              return null;
            },
          ),

          const SizedBox(height: 30),

          // BOTÃO DE REGISTRAR COM GRADIENTE
          SizedBox(
            height: 58,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                gradient: const LinearGradient(
                  colors: [roxoPrincipal, roxoSecundario],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRegistrar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Registrar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // LINK PARA VOLTAR AO LOGIN
          Center(
            child: TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      Navigator.pop(context);
                    },
              child: RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  children: const [
                    TextSpan(text: 'Já tem conta? '),
                    TextSpan(
                      text: 'Entrar',
                      style: TextStyle(
                        color: roxoPrincipal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Text(
          mensagem,
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }

  Future<void> _handleRegistrar() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    if (senha != confirmarSenha) {
      _mostrarErro('As senhas não coincidem');
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthenticationHelper().signUp(
      nome: nome!,
      email: email!,
      password: senha!,
    );

    if (!mounted) return;

    if (result != null) {
      setState(() => _isLoading = false);
      _mostrarErro(AuthenticationHelper().traduzirRetorno(result));
      return;
    }

    // Cadastro criado: salva a turma do usuário no Firestore
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .set({
          'nome': nome,
          'email': email!.toLowerCase(),
          'turma': turma,
          'criadoEm': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Erro ao salvar turma: $e');
      // Segue em frente: na tela principal o usuário pode escolher a turma
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const Principal(),
      ),
    );
  }
}
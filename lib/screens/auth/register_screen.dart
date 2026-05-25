import 'package:flutter/material.dart';
import 'package:la_repe/screens/main_layout.dart';
import 'package:la_repe/services/supabase_service.dart';
import 'package:la_repe/state/album_state.dart';
import 'package:la_repe/theme/theme.dart';
import 'package:la_repe/utils/supabase_errors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl      = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _passCtrl      = TextEditingController();
  final _passConfCtrl  = TextEditingController();
  final _waCtrl        = TextEditingController();

  String _selectedCity = 'Ibagué';
  bool _obscurePass     = true;
  bool _obscurePassConf = true;
  bool _isLoading       = false;

  static const _cities = [
    'Ibagué', 'Bogotá', 'Medellín', 'Cali', 'Bucaramanga',
    'Barranquilla', 'Cartagena', 'Buenos Aires', 'São Paulo',
    'Ciudad de México', 'Madrid', 'París',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _passConfCtrl.dispose();
    _waCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final usuario = await SupabaseService.signUpWithEmail(
        email:    _emailCtrl.text.trim(),
        password: _passCtrl.text,
        nombre:   _nameCtrl.text.trim(),
        whatsapp: _waCtrl.text.trim(),
      );

      // Sincronizar estado local
      if (!mounted) return;
      AlbumStateProvider.of(context).loginOrRegister(
        usuario.nombre,
        _selectedCity,
        '',
        usuario.whatsapp ?? '',
      );

      // Precargar IDs de figuritas en background
      SupabaseService.preloadFiguritaIds(1).catchError((_) {});

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainLayout()),
        (route) => false,
      );
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _label('Nombre completo'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Ej: Diego Gómez',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Ingresa tu nombre' : null,
                ),
                const SizedBox(height: 20),

                _label('Email'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'tu@correo.com',
                    prefixIcon: Icon(Icons.mail_outline, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingresa tu email';
                    if (!v.contains('@')) return 'Email inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _label('Contraseña'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  decoration: InputDecoration(
                    hintText: 'Mínimo 6 caracteres',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                        color: Colors.white38,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 6) {
                      return 'Mínimo 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _label('Confirmar contraseña'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passConfCtrl,
                  obscureText: _obscurePassConf,
                  decoration: InputDecoration(
                    hintText: 'Repetí la contraseña',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassConf ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                        color: Colors.white38,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassConf = !_obscurePassConf),
                    ),
                  ),
                  validator: (v) {
                    if (v != _passCtrl.text) return 'Las contraseñas no coinciden';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _label('WhatsApp'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _waCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: '+57 300 123 4567',
                    prefixIcon: Icon(Icons.phone_iphone_outlined, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingresa tu número';
                    if (v.trim().length < 7) return 'Número demasiado corto';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _label('Ciudad'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  dropdownColor: AppTheme.surface,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_city_outlined, size: 20),
                  ),
                  items: _cities
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedCity = val!),
                ),
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppTheme.goldGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppTheme.shadowGold,
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.background,
                              ),
                            )
                          : const Text(
                              'CREAR CUENTA',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.background,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
      );
}

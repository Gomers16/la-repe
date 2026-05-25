import 'dart:async';
import 'package:flutter/material.dart';
import 'package:la_repe/screens/main_layout.dart';
import 'package:la_repe/services/supabase_service.dart';
import 'package:la_repe/state/album_state.dart';
import 'package:la_repe/theme/theme.dart';
import 'package:la_repe/utils/supabase_errors.dart';

class ProfileCompletionScreen extends StatefulWidget {
  final bool isGoogle;

  const ProfileCompletionScreen({super.key, required this.isGoogle});

  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _whatsappController;
  
  String _selectedCity = 'Ibagué';
  String _selectedCountry = 'Colombia';

  final List<String> _cities = ['Ibagué', 'Bogotá', 'Cali', 'Medellín', 'Barranquilla'];
  final List<String> _countries = ['Colombia', 'Argentina', 'Brasil', 'Uruguay', 'México'];

  bool _isLoading = false;
  double _loadingProgress = 0.0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _whatsappController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _whatsappController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _loadingProgress = 0.0;
    });

    // Animación de progreso mientras guardamos
    _progressTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        if (_loadingProgress < 0.85) _loadingProgress += 0.05;
      });
    });

    try {
      // Si hay sesión activa (Google OAuth), actualizar el perfil en Supabase
      final userId = SupabaseService.currentUserId;
      if (userId != null) {
        await SupabaseService.updateUsuario(
          userId:   userId,
          nombre:   _nameController.text.trim(),
          whatsapp: _whatsappController.text.trim(),
        );
      }

      // Actualizar estado local (Hive)
      if (!mounted) return;
      AlbumStateProvider.of(context).loginOrRegister(
        _nameController.text.trim(),
        _selectedCity,
        _selectedCountry,
        _whatsappController.text.trim(),
      );

      SupabaseService.preloadFiguritaIds(1).catchError((_) {});

      setState(() => _loadingProgress = 1.0);
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainLayout()),
        (route) => false,
      );
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      _progressTimer?.cancel();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGold.withValues(alpha: 0.2),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
                    strokeWidth: 4,
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Creando tu cuenta...',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Esto puede tardar unos segundos.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white60,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Simulated linear progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _loadingProgress,
                    backgroundColor: AppTheme.surfaceLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
                    minHeight: 6,
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Completar Perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.surfaceLight,
                        child: widget.isGoogle 
                            ? const Icon(Icons.person, size: 50, color: Colors.white70)
                            : const Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.white30),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryGold,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, size: 16, color: AppTheme.background),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    widget.isGoogle ? '¡Un paso más!' : 'Crea tu cuenta',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    widget.isGoogle 
                        ? 'Completa tu perfil para comenzar' 
                        : 'Completa los datos para comenzar',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white60,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Name Field
                const Text(
                  'Nombre Completo',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa tu nombre' : null,
                  decoration: const InputDecoration(
                    hintText: 'Ej: Diego Gómez',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                ),
                const SizedBox(height: 20),

                // Country Field (Dropdown)
                const Text(
                  'País',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCountry,
                  dropdownColor: AppTheme.surface,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.public, size: 20),
                  ),
                  items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => _selectedCountry = val!),
                ),
                const SizedBox(height: 20),

                // City Field (Dropdown)
                const Text(
                  'Ciudad',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  dropdownColor: AppTheme.surface,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_city_outlined, size: 20),
                  ),
                  items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => _selectedCity = val!),
                ),
                const SizedBox(height: 20),

                // WhatsApp Field
                const Text(
                  'WhatsApp',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _whatsappController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Ingresa tu número';
                    if (!value.startsWith('+') && value.length < 7) return 'Formato inválido (Ej: +57 300...)';
                    return null;
                  },
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: '+57 300 123 4567',
                    prefixIcon: Icon(Icons.phone_iphone_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 40),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitProfile,
                    style: ElevatedButton.styleFrom(
                      elevation: 4,
                      shadowColor: AppTheme.primaryGold.withValues(alpha: 0.3),
                    ),
                    child: const Text('CONTINUAR'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

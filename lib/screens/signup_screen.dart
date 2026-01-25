import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../services/auth_service.dart';
import '../config/app_colors.dart';
import 'otp_verification_screen.dart';

/// Écran de création de compte avec formulaire téléphone
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Envoie l'OTP via AuthService
    final result = await AuthService.instance.sendOtp(_phoneController.text.trim());
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      if (result == OtpSendResult.insufficientCredits) {
        // Afficher un message d'erreur pour crédits insuffisants
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Crédits SMS insuffisants. Veuillez recharger votre compte avant d\'envoyer un code OTP.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
        return;
      } else if (result != OtpSendResult.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'envoi du code OTP'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Naviguer vers l'écran de vérification OTP
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            phone: _phoneController.text.trim(),
            isLogin: false,
          ),
        ),
      );
    }
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre numéro de téléphone';
    }
    // Validation basique du format téléphone
    final phoneRegex = RegExp(r'^[+]?[0-9]{8,15}$');
    final cleanPhone = value.replaceAll(RegExp(r'[\s-]'), '');
    if (!phoneRegex.hasMatch(cleanPhone)) {
      return 'Format de téléphone invalide';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.getTextColor(isDark),
          ),
        ),
        title: Text(
          'Création de compte',
          style: TextStyle(
            color: AppColors.getTextColor(isDark),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    AppColors.backgroundDark,
                    AppColors.surfaceDark,
                  ]
                : [
                    AppColors.white,
                    AppColors.primaryLight.withOpacity(0.05),
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // Logo placeholder
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.toSurface(),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_add,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'CRÉER UN COMPTE',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextColor(isDark),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Entrez votre numéro de téléphone pour créer votre compte',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.getTextColor(isDark, type: TextType.secondary),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Formulaire
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.getSurfaceColor(isDark),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.getBorderColor(isDark),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Numéro de téléphone *',
                            hintText: '+225 XX XX XX XX',
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.getBorderColor(isDark),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.getBorderColor(isDark),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.phone,
                              color: AppColors.getTextColor(isDark, type: TextType.secondary),
                            ),
                            labelStyle: TextStyle(
                              color: AppColors.getTextColor(isDark, type: TextType.secondary),
                            ),
                            hintStyle: TextStyle(
                              color: AppColors.getTextColor(isDark, type: TextType.secondary).withOpacity(0.6),
                            ),
                          ),
                          style: TextStyle(
                            color: AppColors.getTextColor(isDark),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: _validatePhone,
                          autofocus: true,
                        ),
                        const SizedBox(height: 24),
                        CustomButton(
                          text: 'Envoyer le code OTP',
                          onPressed: _handleSignup,
                          isLoading: _isLoading,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Info box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.toSurface(),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Un code de vérification sera envoyé par SMS à votre numéro de téléphone.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.getTextColor(isDark, type: TextType.secondary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/validators.dart';
import '../providers/registration_provider.dart';

class RegistrationPage extends ConsumerStatefulWidget {
  const RegistrationPage({Key? key}) : super(key: key);

  @override
  ConsumerState<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends ConsumerState<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registrationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('會員註冊'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: '請輸入 Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  validator: Validators.validateName,
                  decoration: InputDecoration(
                    labelText: '姓名',
                    hintText: '請輸入姓名',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: Validators.validatePassword,
                  onChanged: (value) {
                    setState(() {}); // Rebuild to show password strength
                  },
                  decoration: InputDecoration(
                    labelText: '密碼',
                    hintText: '請輸入密碼 (8-20 字元)',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                if (_passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildPasswordStrengthIndicator(),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return '密碼不相符';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: '確認密碼',
                    hintText: '再次輸入密碼',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (state.errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      state.errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: state.state == RegistrationState.loading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            ref.read(registrationProvider.notifier).registerUser(
                              email: _emailController.text.trim(),
                              name: _nameController.text.trim(),
                              password: _passwordController.text,
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: state.state == RegistrationState.loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('註冊'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final strength = Validators.checkPasswordStrength(_passwordController.text);
    final color = _getStrengthColor(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _getStrengthValue(strength),
            color: color,
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            _buildStrengthChip('8+ 字元', strength['hasMinLength']!),
            _buildStrengthChip('大寫', strength['hasUppercase']!),
            _buildStrengthChip('小寫', strength['hasLowercase']!),
            _buildStrengthChip('數字', strength['hasNumber']!),
          ],
        ),
      ],
    );
  }

  Widget _buildStrengthChip(String label, bool met) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: met ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
      side: BorderSide(
        color: met ? Colors.green : Colors.grey,
      ),
    );
  }

  Color _getStrengthColor(Map<String, bool> strength) {
    final metCount = strength.values.where((v) => v).length;
    if (metCount <= 2) return Colors.red;
    if (metCount <= 4) return Colors.orange;
    return Colors.green;
  }

  double _getStrengthValue(Map<String, bool> strength) {
    final metCount = strength.values.where((v) => v).length;
    return metCount / strength.length;
  }
}

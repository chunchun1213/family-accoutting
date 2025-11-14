import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../providers/registration_provider.dart';

class EmailVerificationPage extends ConsumerStatefulWidget {
  const EmailVerificationPage({Key? key}) : super(key: key);

  @override
  ConsumerState<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends ConsumerState<EmailVerificationPage> {
  final _codeController = TextEditingController();
  late int _countdownSeconds;

  @override
  void initState() {
    super.initState();
    _countdownSeconds = AppConstants.verificationCodeValidityMinutes * 60;
    _startCountdown();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _countdownSeconds > 0) {
        setState(() => _countdownSeconds--);
        _startCountdown();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registrationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Email 驗證'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.mail, size: 48, color: Colors.blue),
                    const SizedBox(height: 16),
                    Text(
                      '驗證碼已發送至',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.userEmail,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                '請輸入 6 位數驗證碼',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32, letterSpacing: 8),
                decoration: InputDecoration(
                  hintText: '000000',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (state.errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                      if (state.remainingAttempts > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '剩餘嘗試次數: ${state.remainingAttempts}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '驗證碼有效期: ${_formatCountdown(_countdownSeconds)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (state.canResendCode)
                    TextButton(
                      onPressed: () {
                        ref.read(registrationProvider.notifier).resendVerificationCode();
                        setState(() => _countdownSeconds = AppConstants.verificationCodeValidityMinutes * 60);
                        _startCountdown();
                      },
                      child: const Text('重新發送'),
                    )
                  else
                    TextButton(
                      onPressed: null,
                      child: Text('${AppConstants.verificationCodeResendCooldownSeconds} 秒後可重新發送'),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: state.state == RegistrationState.verifying
                    ? null
                    : () {
                        final error = Validators.validateVerificationCode(_codeController.text);
                        if (error == null) {
                          ref.read(registrationProvider.notifier).verifyCode(
                            code: _codeController.text.trim(),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error)),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: state.state == RegistrationState.verifying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('驗證'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCountdown(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}

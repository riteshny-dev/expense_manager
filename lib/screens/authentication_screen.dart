import 'package:flutter/material.dart';
import '../services/authentication_service.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  final _pinController = TextEditingController();
  bool _isSettingPin = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final hasBiometrics = await AuthenticationService.isBiometricAvailable();
    if (hasBiometrics) {
      final authenticated = await AuthenticationService.authenticateWithBiometrics();
      if (authenticated) {
        _navigateToHome();
        return;
      }
    }

    final hasPinSet = await AuthenticationService.isPinSet();
    if (!hasPinSet) {
      setState(() => _isSettingPin = true);
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  Future<void> _handlePinSubmission() async {
    if (_pinController.text.length < 4) {
      setState(() => _errorMessage = 'PIN must be at least 4 digits');
      return;
    }

    if (_isSettingPin) {
      await AuthenticationService.setPin(_pinController.text);
      _navigateToHome();
    } else {
      final verified = await AuthenticationService.verifyPin(_pinController.text);
      if (verified) {
        _navigateToHome();
      } else {
        setState(() => _errorMessage = 'Invalid PIN');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSettingPin ? 'Set PIN' : 'Enter PIN'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: _isSettingPin ? 'Create PIN' : 'Enter PIN',
                errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _handlePinSubmission,
              child: Text(_isSettingPin ? 'Set PIN' : 'Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
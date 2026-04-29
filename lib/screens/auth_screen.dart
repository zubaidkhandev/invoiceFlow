import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoice_flow/blocs/auth_cubit.dart';
import 'package:invoice_flow/utils/constants.dart';
import 'package:invoice_flow/widgets/premium_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _controller = TextEditingController();
  bool _error = false;

  void _submit() {
    final success = context.read<AuthCubit>().unlock(_controller.text);
    if (!success) {
      setState(() => _error = true);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          child: PremiumCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(size: 80),
                const SizedBox(height: 24),
                const Text(
                  'Access Locked',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please enter your app password to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _controller,
                  obscureText: true,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    errorText: _error ? 'Incorrect password' : null,
                    prefixIcon: const Icon(Icons.password),
                  ),
                ),
                const SizedBox(height: 24),
                PremiumButton(
                  label: 'Unlock App',
                  onPressed: _submit,
                  width: double.infinity,
                  icon: Icons.lock_open,
                ),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: () => launchUrl(Uri.parse(AppConstants.appWebsite)),
                  child: Text(
                    'Visit ${AppConstants.appWebsite.replaceAll('https://', '').replaceAll('/', '')}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:invoice_flow/blocs/auth_cubit.dart';
import 'package:invoice_flow/blocs/settings_cubit.dart';
import 'package:invoice_flow/models/sender_info.dart';
import 'package:invoice_flow/utils/constants.dart';
import 'package:invoice_flow/widgets/premium_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _registrationController;
  late TextEditingController _websiteController;
  String? _logoData;

  @override
  void initState() {
    super.initState();
    final sender = context.read<SettingsCubit>().state.sender;
    _emailController = TextEditingController(text: sender.email);
    _phoneController = TextEditingController(text: sender.phone);
    _addressController = TextEditingController(text: sender.address);
    _websiteController = TextEditingController(text: sender.website);
    _logoData = sender.logoData;
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final image =
        await picker.pickImage(source: ImageSource.gallery, maxWidth: 400);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _logoData = base64Encode(bytes));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _registrationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final sender = SenderInfo(
      businessName: AppConstants.appName,
      email: _emailController.text,
      phone: _phoneController.text,
      address: _addressController.text,
      registrationNumber: AppConstants.registrationNumber,
      website: _websiteController.text,
      logoData: _logoData,
    );
    context.read<SettingsCubit>().updateSender(sender);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Business Profile', 'Manage your company details for invoices'),
                const SizedBox(height: 24),
                PremiumCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: _pickLogo,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.2),
                                        width: 2),
                                    image: _logoData != null
                                        ? DecorationImage(
                                            image: MemoryImage(
                                                base64Decode(_logoData!)),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: _logoData == null
                                      ? Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_a_photo_outlined,
                                                size: 28,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary),
                                            const SizedBox(height: 8),
                                            const Text('Upload Logo',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ],
                                        )
                                      : Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            color:
                                                Colors.black.withValues(alpha: 0.3),
                                          ),
                                          child: const Center(
                                            child: Icon(Icons.edit_outlined,
                                                color: Colors.white, size: 24),
                                          ),
                                        ),
                                ),
                              ),
                              if (_logoData != null)
                                Positioned(
                                  top: -8,
                                  right: -8,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _logoData = null),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close,
                                          size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(AppConstants.appName,
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                                Text(
                                    'Registration: ${AppConstants.registrationNumber}',
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                              child: _buildTextField('Professional Email',
                                  _emailController, Icons.email_outlined)),
                          const SizedBox(width: 16),
                          Expanded(
                              child: _buildTextField('Phone Number',
                                  _phoneController, Icons.phone_outlined)),
                        ],
                      ),

                      const SizedBox(height: 20),
                      _buildTextField('Business Website / Link',
                          _websiteController, Icons.link_outlined),
                      const SizedBox(height: 20),
                      _buildTextField('Physical Address', _addressController,
                          Icons.location_on_outlined,
                          maxLines: 3),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                _buildSectionHeader('Preferences', 'Customize your app experience'),
                const SizedBox(height: 24),
                PremiumCard(
                  child: BlocBuilder<SettingsCubit, SettingsState>(
                    builder: (context, state) {
                      return Column(
                        children: [
                          _buildPreferenceTile(
                            'Active Currency',
                            'Select the currency symbol for your reports',
                            Icons.payments_outlined,
                            DropdownButton<String>(
                              value: state.currency,
                              underline: const SizedBox.shrink(),
                              onChanged: (val) {
                                if (val != null) context.read<SettingsCubit>().updateCurrency(val);
                              },
                              items: AppConstants.currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            ),
                          ),
                          const Divider(height: 40),
                          _buildPreferenceTile(
                            'Dark Appearance',
                            'Switch between light and dark themes',
                            Icons.dark_mode_outlined,
                            Switch.adaptive(
                              value: state.isDarkMode,
                              onChanged: (_) => context.read<SettingsCubit>().toggleDarkMode(),
                              activeTrackColor: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 48),
                _buildSectionHeader('Security', 'Protect your financial data with an app lock'),
                const SizedBox(height: 24),
                PremiumCard(
                  child: BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      final hasPassword = context.read<AuthCubit>().storageService.hasAppPassword();
                      return Column(
                        children: [
                          _buildPreferenceTile(
                            hasPassword ? 'Change Password' : 'Set App Password',
                            'Unlock with a secure password on startup',
                            Icons.lock_outline,
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () => _showPasswordDialog(context),
                            ),
                          ),
                          if (hasPassword) ...[
                            const Divider(height: 40),
                            _buildPreferenceTile(
                              'Remove Protection',
                              'Disables the startup password prompt',
                              Icons.lock_open_outlined,
                              TextButton(
                                onPressed: () {
                                  context.read<AuthCubit>().setPassword(null);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password protection removed.')));
                                },
                                child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 48),
                PremiumButton(
                  label: 'Save Profile Changes',
                  onPressed: _saveSettings,
                  width: double.infinity,
                  icon: Icons.save_outlined,
                ),
                const SizedBox(height: 32),
                Center(
                  child: TextButton.icon(
                    onPressed: () => launchUrl(Uri.parse(AppConstants.appWebsite)),
                    icon: const Icon(Icons.language, size: 16),
                    label: Text(
                      'Official Website: ${AppConstants.appWebsite.replaceAll('https://', '').replaceAll('/', '')}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade500 : Colors.blueGrey.shade400, fontSize: 14)),
      ],
    );
  }

  void _showPasswordDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set App Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choose a strong password to protect your invoices. This password will be required every time you open the app.', style: TextStyle(fontSize: 13, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey : Colors.blueGrey.shade600)),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password', prefixIcon: Icon(Icons.password)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<AuthCubit>().setPassword(controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully!')));
              }
            },
            child: const Text('Save Password'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }

  Widget _buildPreferenceTile(String title, String subtitle, IconData icon, Widget trailing) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade500 : Colors.blueGrey.shade400, fontSize: 12)),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}

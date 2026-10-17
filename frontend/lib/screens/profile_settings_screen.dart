import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../widgets/brand_navigation.dart';

const _institutionTypes = <String, String>{
  'school': 'School',
  'college': 'College',
  'university': 'University',
  'other': 'Other',
};

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  Future<UserProfile>? _profile;
  String? _profileUserId;

  void _loadProfile(String userId) {
    if (_profileUserId == userId && _profile != null) return;
    _profileUserId = userId;
    _profile = ProfileService(apiClient).get();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    if (auth.isLoading) {
      return const Scaffold(
        backgroundColor: AppConstants.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (auth.user == null) {
      return Scaffold(
        backgroundColor: AppConstants.background,
        appBar: AppBar(
          leading: const AppBackButton(),
          title: const Text('Profile settings'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline,
                      size: 44, color: AppConstants.primary),
                  const SizedBox(height: 12),
                  const Text(
                    'Profile settings দেখতে sign in করুন',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => context.push(
                      '/account?redirect=${Uri.encodeComponent('/profile/settings')}',
                    ),
                    icon: const Icon(Icons.login),
                    label: const Text('Sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    _loadProfile(auth.user!.userId);
    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Profile settings'),
      ),
      body: FutureBuilder<UserProfile>(
        future: _profile,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            final error = snapshot.error;
            final needsSignIn = error is ApiException &&
                (error.statusCode == 401 || error.statusCode == 403);
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_off_outlined, size: 40),
                  const SizedBox(height: 10),
                  Text(needsSignIn
                      ? 'Session শেষ হয়েছে; আবার sign in করুন'
                      : 'Profile লোড করা যায়নি'),
                  if (error != null && !needsSignIn) ...[
                    const SizedBox(height: 4),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppConstants.mutedText),
                    ),
                  ],
                  if (needsSignIn)
                    TextButton.icon(
                      onPressed: () => context.push(
                        '/account?redirect=${Uri.encodeComponent('/profile/settings')}',
                      ),
                      icon: const Icon(Icons.login),
                      label: const Text('আবার sign in করুন'),
                    ),
                  TextButton.icon(
                    onPressed: () => setState(
                        () => _profile = ProfileService(apiClient).get()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('আবার চেষ্টা করুন'),
                  ),
                ],
              ),
            );
          }
          return _ProfileSettingsForm(profile: snapshot.data!);
        },
      ),
    );
  }
}

class _ProfileSettingsForm extends StatefulWidget {
  const _ProfileSettingsForm({required this.profile});

  final UserProfile profile;

  @override
  State<_ProfileSettingsForm> createState() => _ProfileSettingsFormState();
}

class _ProfileSettingsFormState extends State<_ProfileSettingsForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _institutionName;
  late final TextEditingController _location;
  late String? _institutionType;
  late bool _notificationsEnabled;
  late String _preferredLanguage;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _name = TextEditingController(text: profile.displayName);
    _email = TextEditingController(text: profile.email ?? '');
    _institutionName =
        TextEditingController(text: profile.institutionName ?? '');
    _location = TextEditingController(text: profile.location ?? '');
    _institutionType = _institutionTypes.containsKey(profile.institutionType)
        ? profile.institutionType
        : null;
    _notificationsEnabled = profile.notificationsEnabled;
    _preferredLanguage = profile.preferredLanguage;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _institutionName.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = await ProfileService(apiClient).update(
        displayName: _name.text.trim(),
        email: _email.text.trim(),
        institutionType: _institutionType ?? '',
        institutionName: _institutionName.text.trim(),
        location: _location.text.trim(),
        notificationsEnabled: _notificationsEnabled,
        preferredLanguage: _preferredLanguage,
      );
      if (mounted) context.pop<UserProfile>(updated);
    } catch (error) {
      if (mounted) {
        final message = error is ApiException
            ? error.message
            : 'Profile save করা যায়নি: $error';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final values = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Password পরিবর্তন করুন'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: current,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'বর্তমান password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: next,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'নতুন password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              (current.text, next.text),
            ),
            child: const Text('আপডেট'),
          ),
        ],
      ),
    );
    current.dispose();
    next.dispose();
    if (values == null) return;
    try {
      await ProfileService(apiClient).changePassword(values.$1, values.$2);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ProfileSettingsHeader(profile: widget.profile),
                          const SizedBox(height: 18),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _SettingsSection(
                                  icon: Icons.person_outline,
                                  title: 'Personal details',
                                  subtitle: 'আপনার যোগাযোগের তথ্য',
                                  children: [
                                    _SettingsTextField(
                                      controller: _name,
                                      label: 'পূর্ণ নাম',
                                      icon: Icons.badge_outlined,
                                      validator: (value) =>
                                          (value ?? '').trim().isEmpty
                                              ? 'নাম লিখুন'
                                              : null,
                                    ),
                                    const SizedBox(height: 14),
                                    _SettingsTextField(
                                      controller: _email,
                                      label: 'Gmail / Email',
                                      hint: 'name@gmail.com',
                                      icon: Icons.alternate_email,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        final email = (value ?? '').trim();
                                        if (email.isEmpty) return null;
                                        return RegExp(
                                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                        ).hasMatch(email)
                                            ? null
                                            : 'সঠিক email address লিখুন';
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'মোবাইল নম্বর',
                                        prefixIcon: Icon(Icons.phone_android),
                                      ),
                                      child: Text(
                                        widget.profile.phoneNumber.isEmpty
                                            ? 'যোগ করা নেই'
                                            : widget.profile.phoneNumber,
                                        style: const TextStyle(
                                          color: AppConstants.mutedText,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _SettingsSection(
                                  icon: Icons.school_outlined,
                                  title: 'Education',
                                  subtitle: 'আপনি কোথায় পড়াশোনা করছেন',
                                  children: [
                                    DropdownButtonFormField<String>(
                                      value: _institutionType,
                                      decoration: const InputDecoration(
                                        labelText: 'প্রতিষ্ঠানের ধরন',
                                        prefixIcon: Icon(
                                            Icons.account_balance_outlined),
                                      ),
                                      items: [
                                        for (final option
                                            in _institutionTypes.entries)
                                          DropdownMenuItem(
                                            value: option.key,
                                            child: Text(option.value),
                                          ),
                                      ],
                                      onChanged: _saving
                                          ? null
                                          : (value) => setState(
                                              () => _institutionType = value),
                                    ),
                                    const SizedBox(height: 14),
                                    _SettingsTextField(
                                      controller: _institutionName,
                                      label: _institutionType == 'university'
                                          ? 'বিশ্ববিদ্যালয়ের নাম'
                                          : 'স্কুল / কলেজ / প্রতিষ্ঠানের নাম',
                                      icon: Icons.account_balance,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _SettingsSection(
                                  icon: Icons.location_on_outlined,
                                  title: 'Location',
                                  subtitle: 'শহর বা জেলা যোগ করুন',
                                  children: [
                                    _SettingsTextField(
                                      controller: _location,
                                      label: 'শহর / জেলা',
                                      hint: 'যেমন: ঢাকা',
                                      icon: Icons.map_outlined,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _SettingsSection(
                                  icon: Icons.tune,
                                  title: 'Preferences',
                                  subtitle: 'অ্যাপটি আপনার মতো করে সাজান',
                                  children: [
                                    SwitchListTile.adaptive(
                                      contentPadding: EdgeInsets.zero,
                                      value: _notificationsEnabled,
                                      onChanged: _saving
                                          ? null
                                          : (value) => setState(() =>
                                              _notificationsEnabled = value),
                                      secondary:
                                          const Icon(Icons.notifications_none),
                                      title: const Text('Study notifications'),
                                      subtitle:
                                          const Text('পড়াশোনার reminder পান'),
                                    ),
                                    DropdownButtonFormField<String>(
                                      value: _preferredLanguage,
                                      decoration: const InputDecoration(
                                        labelText: 'ভাষা',
                                        prefixIcon: Icon(Icons.language),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'বাংলা',
                                            child: Text('বাংলা')),
                                        DropdownMenuItem(
                                            value: 'English',
                                            child: Text('English')),
                                      ],
                                      onChanged: _saving
                                          ? null
                                          : (value) => setState(() =>
                                              _preferredLanguage =
                                                  value ?? 'বাংলা'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _SettingsSection(
                                  icon: Icons.shield_outlined,
                                  title: 'Account security',
                                  subtitle: 'আপনার account সুরক্ষিত রাখুন',
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed:
                                          _saving ? null : _changePassword,
                                      icon: const Icon(Icons.lock_reset),
                                      label: const Text('Password পরিবর্তন'),
                                      style: OutlinedButton.styleFrom(
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: const BoxDecoration(
                color: AppConstants.surface,
                border: Border(top: BorderSide(color: Color(0xFFE1E9E7))),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: const Text('পরিবর্তন সংরক্ষণ করুন'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppConstants.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}

class _ProfileSettingsHeader extends StatelessWidget {
  const _ProfileSettingsHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final imageUrl = profile.profileImageUrl;
    final ImageProvider<Object>? imageProvider = imageUrl == null
        ? null
        : imageUrl.startsWith('data:image/')
            ? MemoryImage(
                base64Decode(imageUrl.substring(imageUrl.indexOf(',') + 1)))
            : NetworkImage(imageUrl);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 29,
            backgroundColor: Colors.white,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? const Icon(Icons.person_outline,
                    color: AppConstants.primary, size: 30)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your profile',
                  style: TextStyle(
                    color: Color(0xFFBFE1DC),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.tune, color: Colors.white70),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConstants.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2EAE8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9F2F1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: AppConstants.primary, size: 20),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                              color: AppConstants.mutedText, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      );
}

class _SettingsTextField extends StatelessWidget {
  const _SettingsTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLength: 180,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          counterText: '',
        ),
      );
}

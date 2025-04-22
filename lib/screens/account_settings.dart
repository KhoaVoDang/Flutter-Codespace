import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:html' as html;

class AccountSettingsScreen extends StatefulWidget {
  final VoidCallback onClose;
  const AccountSettingsScreen({Key? key, required this.onClose}) : super(key: key);

  @override
  _AccountSettingsScreenState createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _nameController = TextEditingController();
  String? _avatarUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      if (response != null) {
        setState(() {
          _nameController.text = response['preferred_name'] ?? '';
          _avatarUrl = response['avatar_url'];
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'preferred_name': _nameController.text,
        'avatar_url': _avatarUrl,
      });

      // Also update shared preferences for local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('entered_value', _nameController.text);

      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast(description: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(description: Text('Error updating profile: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadAvatar() async {
    setState(() => _isLoading = true);
    try {
      Uint8List? fileBytes;
      String? fileName;

      if (kIsWeb) {
        // Web: Use dart:html for file picking
        final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
        uploadInput.click();
        await uploadInput.onChange.first;
        final file = uploadInput.files?.first;
        if (file == null) throw 'No file selected';
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        await reader.onLoad.first;
        fileBytes = reader.result as Uint8List;
        fileName = file.name;
      } else {
        // Mobile/Desktop: Use file_picker
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true,
          allowCompression: true,
        );
        if (result == null || result.files.isEmpty) {
          setState(() => _isLoading = false);
          return;
        }
        fileBytes = result.files.first.bytes;
        fileName = result.files.first.name;
      }

      if (fileBytes == null || fileName == null) throw 'Failed to read file';

      final fileExt = fileName.split('.').last.toLowerCase(); // ensure lowercase extension
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw 'User not logged in';

      // Simplified path structure
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${timestamp}_${user.id}.$fileExt';

      print('Uploading to path: $path'); // Debug log

      // Try to upload with error catching
      String? uploadResult;
      try {
        uploadResult = await Supabase.instance.client.storage
            .from('avatars')
            .uploadBinary(
              path,
              fileBytes,
              fileOptions: FileOptions(
                contentType: 'image/$fileExt',
                upsert: true,
              ),
            );
      } catch (e) {
        throw 'Upload failed: ${e.toString()}';
      }

      if (uploadResult == null) throw 'Failed to upload avatar';

      final publicUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(path);

      // Update profile with new avatar URL
      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'avatar_url': publicUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });

      setState(() {
        _avatarUrl = publicUrl;
      });

      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast(description: Text('Avatar updated successfully')),
        );
      }
    } catch (e) {
      print('Error uploading avatar: $e');
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(description: Text(e.toString())),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear user data
      
      if (mounted) {
        // Pop the bottom sheet first
        Navigator.pop(context);
        
        // Navigate to login screen and remove all previous routes
        Navigator.pushNamedAndRemoveUntil(
          context,
          'login_screen', // Make sure this matches your route name in main.dart
          (route) => false, // This will remove all previous routes
        );
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(description: Text('Error signing out: $e')),
        );
      }
    }
  }

  Widget sectionTitle(String text) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: theme.textTheme.h4?.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Divider(thickness: 1, color: theme.colorScheme.border),
        ],
      ),
    );
  }

  Widget settingRow({
    required String title,
    String? subtitle,
    required Widget trailing,
    bool showDivider = true,
    GestureTapCallback? onTap,
  }) {
    final theme = ShadTheme.of(context);
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: subtitle != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.p?.copyWith(fontWeight: FontWeight.w500)),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subtitle,
                            style: theme.textTheme.muted?.copyWith(fontSize: 13),
                          ),
                        ),
                    ],
                  ),
                ),
                trailing,
              ],
            ),
          ),
        ),
        if (showDivider) Divider(height: 1, color: theme.colorScheme.border),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.background,
          elevation: 0,
          leading: IconButton(
            icon: Icon(LucideIcons.x),
            color: theme.colorScheme.mutedForeground,
            onPressed: widget.onClose,
          ),
          title: Text('Account Settings', style: theme.textTheme.h4),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionTitle("Profile"),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundImage: _avatarUrl != null
                                    ? NetworkImage(_avatarUrl!)
                                    : null,
                                child: _avatarUrl == null
                                    ? Icon(LucideIcons.user, size: 40)
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: ShadButton.secondary(
                                  size: ShadButtonSize.sm,
                                  onPressed: _uploadAvatar,
                                  child: Icon(LucideIcons.upload, size: 12),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Preferred name', style: theme.textTheme.muted),
                                SizedBox(height: 8),
                                ShadInput(
                                  controller: _nameController,
                                  placeholder: Text('Enter your preferred name'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    ShadButton(
                      width: double.infinity,
                      onPressed: _updateProfile,
                      child: Text('Save Changes'),
                    ),
                    sectionTitle("Security"),
                    settingRow(
                      title: "Change Email",
                      subtitle: "Update your email address.",
                      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.muted),
                      onTap: () {
                        // TODO: Implement change email
                      },
                    ),
                    settingRow(
                      title: "Change Password",
                      subtitle: "Update your account password.",
                      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.muted),
                      onTap: () {
                        // TODO: Implement change password
                      },
                    ),
                    sectionTitle("Session"),
                    settingRow(
                      title: "Log Out",
                      subtitle: "Sign out of your account.",
                      trailing: Icon(LucideIcons.logOut, color: theme.colorScheme.destructive),
                      showDivider: false,
                      onTap: _logOut,
                    ),
                    SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }
}

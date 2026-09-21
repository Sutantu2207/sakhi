import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../models/contact.dart';
import '../services/api_service.dart';
import 'privacy_dashboard_screen.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<EmergencyContact> _contacts = [];
  bool _loadingContacts = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _loadingContacts = true);
    try {
      final data = await ApiService.getContacts();
      setState(() => _contacts = data);
    } catch (e) {
      debugPrint('Error loading contacts: $e');
    } finally {
      setState(() => _loadingContacts = false);
    }
  }

  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relController = TextEditingController(text: 'Family');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Emergency Contact', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Contact Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number (with country code)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: relController,
              decoration: const InputDecoration(labelText: 'Relationship (e.g. Mother, Partner)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              if (name.isEmpty || phone.isEmpty) return;

              Navigator.pop(ctx);
              try {
                await ApiService.addContact(
                  name: name,
                  phone: phone,
                  relationshipLabel: relController.text.trim(),
                  notifyOnSos: true,
                );
                _loadContacts();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding contact: $e')),
                  );
                }
              }
            },
            child: const Text('Save Contact'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteContact(String id) async {
    try {
      await ApiService.deleteContact(id);
      _loadContacts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete contact: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Safety Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: AppColors.primaryViolet),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrivacyDashboardScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // User Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.softLavender,
                    child: Text(
                      user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'S',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryViolet),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'Sakhi User',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkCharcoal),
                        ),
                        const SizedBox(height: 2),
                        Text(user?.email ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        if (user?.phone != null) ...[
                          const SizedBox(height: 2),
                          Text(user!.phone!, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Emergency Contacts Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Emergency Contacts (SOS Alerted)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                TextButton.icon(
                  onPressed: _showAddContactDialog,
                  icon: const Icon(Icons.add, size: 16, color: AppColors.primaryViolet),
                  label: const Text('Add Contact', style: TextStyle(fontSize: 12, color: AppColors.primaryViolet, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Contacts List
            if (_loadingContacts)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (_contacts.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.contact_phone_outlined, size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      const Text('No Emergency Contacts Added', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      const Text(
                        'Add trusted family or friends to receive instant SMS and notifications when SOS is triggered.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _showAddContactDialog, child: const Text('Add First Contact')),
                    ],
                  ),
                ),
              )
            else
              ..._contacts.map((c) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.softLavender,
                        child: Icon(Icons.person, color: AppColors.primaryViolet, size: 20),
                      ),
                      title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('${c.relationshipLabel ?? "Contact"} • ${c.phone}', style: const TextStyle(fontSize: 11)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        onPressed: () => _deleteContact(c.id),
                      ),
                    ),
                  )),

            const SizedBox(height: 24),

            // Settings Shortcuts
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primaryViolet),
                    title: const Text('Privacy & Data Dashboard', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Manage retention, sharing, and safety network', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PrivacyDashboardScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, color: AppColors.borderLight),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text('Sign Out', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    onTap: () async {
                      await auth.logout();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const AuthScreen()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

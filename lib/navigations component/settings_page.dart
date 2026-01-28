import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quote_application/theme/theme_provider.dart';
import 'package:quote_application/services/notification_service.dart';
import 'package:quote_application/daily_notification_scheduler.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;

  // Add your links here
  final String playStoreLink = "https://play.google.com/store/apps/details?id=com.quoteinspo.app";
  final String privacyPolicyLink = "https://sites.google.com/view/quote-inspo-privacy-policy/home";
  final String contactEmail = "chimezie5starr@gmail.com";

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _toggleNotification(bool val) async {
    setState(() {
      _notificationsEnabled = val;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', val);

    if (val) {
      await DailyNotificationsScheduler.scheduleAllDailyNotifications();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Daily notifications scheduled')),
        );
      }
    } else {
      await NotificationService.cancelAllScheduledNotifications();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🚫 All notifications cancelled')),
        );
      }
    }
  }

  void _showThemeDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select App Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ThemeMode.values.map((mode) {
              String modeName = switch (mode) {
                ThemeMode.system => 'System Default',
                ThemeMode.light => 'Light',
                ThemeMode.dark => 'Dark',
              };
              return RadioListTile<ThemeMode>(
                title: Text(modeName),
                value: mode,
                groupValue: themeProvider.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // Open external link safely
  void _openLink(String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠ Could not open link')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠ Could not open link')),
        );
      }
    }
  }

  // Open email client
  void _contactUs() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: contactEmail,
      query: 'subject=App Inquiry',
    );
    try {
      if (!await launchUrl(emailUri)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⚠ Could not open email client')),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠ Could not open email client')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final iconColor = theme.iconTheme.color;
    final textColor = theme.textTheme.bodyLarge?.color;

    BoxDecoration boxDecoration = BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        if (!isDark)
          const BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // App Theme
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: boxDecoration,
                child: ListTile(
                  leading: Icon(Icons.color_lens, color: iconColor),
                  title: Text('App Theme', style: TextStyle(color: textColor)),
                  subtitle: Text(
                    switch (themeProvider.themeMode) {
                      ThemeMode.system => 'System Default',
                      ThemeMode.light => 'Light',
                      ThemeMode.dark => 'Dark',
                    },
                    style: TextStyle(color: textColor?.withOpacity(0.7)),
                  ),
                  trailing: Icon(Icons.chevron_right, color: iconColor),
                  onTap: _showThemeDialog,
                ),
              ),
        
              // Manage Notifications
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: boxDecoration,
                child: SwitchListTile(
                  secondary: Icon(Icons.notifications, color: iconColor),
                  title: Text('Daily Notifications', style: TextStyle(color: textColor)),
                  value: _notificationsEnabled,
                  onChanged: _toggleNotification,
                ),
              ),
        
              // Rate App
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: boxDecoration,
                child: ListTile(
                  leading: Icon(Icons.star_rate, color: iconColor),
                  title: Text('Rate Our App', style: TextStyle(color: textColor)),
                  trailing: Icon(Icons.chevron_right, color: iconColor),
                  onTap: () => _openLink(playStoreLink),
                ),
              ),
        
              // Privacy Policy
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: boxDecoration,
                child: ListTile(
                  leading: Icon(Icons.privacy_tip, color: iconColor),
                  title: Text('Privacy Policy', style: TextStyle(color: textColor)),
                  trailing: Icon(Icons.chevron_right, color: iconColor),
                  onTap: () => _openLink(privacyPolicyLink),
                ),
              ),
        
              // Contact Us
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: boxDecoration,
                child: ListTile(
                  leading: Icon(Icons.email, color: iconColor),
                  title: Text('Contact Us', style: TextStyle(color: textColor)),
                  trailing: Icon(Icons.chevron_right, color: iconColor),
                  onTap: _contactUs,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

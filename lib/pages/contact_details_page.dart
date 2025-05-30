import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tr_business_card_clone1/models/contact_model.dart';
import 'package:tr_business_card_clone1/providers/contact_provider.dart';
import 'package:tr_business_card_clone1/utils/helper_functions.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ContactDetailsPage extends StatelessWidget {
  static const String routeName = 'details';
  final int id;
  const ContactDetailsPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ContactProvider>(context, listen: false);
    return FutureBuilder<ContactModel>(
      future: provider.getContactById(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xff8160c7),
              title: const Text('Contact Details', style: TextStyle(color: Colors.white),),
            ),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        final contact = snapshot.data!;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xff8160c7),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Contact Details',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete Contact'),
                      content: const Text('Are you sure you want to delete this contact?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await provider.deleteContact(contact.id);
                    await provider.getAllContacts();
                    if (context.mounted) {
                      showMsg(context, 'Contact deleted');
                      context.go('/');
                    }
                  }
                },
              ),
            ],
          ),

          body: ListView(
            padding: const EdgeInsets.all(8.0),
            children: [
              if (contact.image.isNotEmpty && File(contact.image).existsSync())
                Image.file(
                  File(contact.image),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 12),

              ListTile(
                title: const Text('Name', style: TextStyle(color: Color(0xff8160c7))),
                subtitle: Text('${contact.firstName} ${contact.lastName}'),
              ),
              ListTile(
                title: const Text('Company', style: TextStyle(color: Color(0xff8160c7))),
                subtitle: Text(contact.company.isEmpty ? '-' : contact.company),
              ),
              ListTile(
                title: const Text('Designation', style: TextStyle(color: Color(0xff8160c7))),
                subtitle: Text(contact.designation.isEmpty ? '-' : contact.designation),
              ),
              ListTile(
                title: const Text('Mobile', style: TextStyle(color: Color(0xff8160c7))),
                subtitle: Text(contact.mobile),
              ),
              ListTile(
                title: const Text('Email', style: TextStyle(color: Color(0xff8160c7))),
                subtitle: Text(contact.email),
              ),
              ListTile(
                title: const Text('Address', style: TextStyle(color: Color(0xff8160c7))),
                subtitle: Text(contact.address),
              ),
              ListTile(
                title: const Text('Website', style: TextStyle(color: Color(0xff8160c7))),
                subtitle: Text(contact.website),
              ),
              ListTile(
                title: const Text('LinkedIn', style: TextStyle(color: Color(0xff8160c7))),
                subtitle: Text(contact.linkedin),
              ),
              ListTile(
                title: const Text('Twitter', style: TextStyle(color: Color(0xff8160c7))),
                subtitle: Text(contact.twitter),
              ),
              ListTile(
                title: const Text('Facebook', style: TextStyle(color: Color(0xff8160c7))),
                subtitle: Text(contact.facebook),
              ),
              ListTile(
                title: const Text('Instagram', style: TextStyle(color: Color(0xff8160c7))),
                subtitle: Text(contact.instagram),
              ),

            ],
          ),
        );
      },
    );
  }

  void _callContact(BuildContext context, String mobile) async {
    final url = 'tel:$mobile';
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      showMsg(context, 'Cannot perform this task');
    }
  }

  void _smsContact(BuildContext context, String mobile) async {
    final url = 'sms:$mobile';
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      showMsg(context, 'Cannot perform this task');
    }
  }

  void _sendEmail(BuildContext context, String email) async {
    final url = 'mailto:$email';
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      showMsg(context, 'Could not perform this operation');
    }
  }

  void _openBrowser(BuildContext context, String website) async {
    final url = 'https://$website';
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      showMsg(context, 'Could not perform this operation');
    }
  }

  void _openMap(BuildContext context, String address) async {
    final androidUrl = 'geo:0,0?q=$address';
    final iosUrl = 'http://maps.apple.com/?q=$address';
    final url = Platform.isAndroid ? androidUrl : iosUrl;
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      showMsg(context, 'Could not perform this operation');
    }
  }
}

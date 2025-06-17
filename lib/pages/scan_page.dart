import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tr_business_card_clone1/models/contact_model.dart';
import 'package:tr_business_card_clone1/providers/contact_provider.dart';
import 'package:tr_business_card_clone1/utils/constants.dart';
import 'package:tr_business_card_clone1/utils/helper_functions.dart';
import 'package:tr_business_card_clone1/utils/text_inference.dart'; // should contain inferContactFieldsFromText()

class ScanPage extends StatefulWidget {
  static const String routeName = 'scan';
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool isScanOver = false;
  List<TextBlock> textBlocks = [];
  ui.Image? uiImage;
  String image = '';

  final _formKey = GlobalKey<FormState>();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final companyController = TextEditingController();
  final designationController = TextEditingController();
  final webController = TextEditingController();
  final linkedinController = TextEditingController();
  final twitterController = TextEditingController();
  final facebookController = TextEditingController();
  final instagramController = TextEditingController();

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    addressController.dispose();
    companyController.dispose();
    designationController.dispose();
    webController.dispose();
    linkedinController.dispose();
    twitterController.dispose();
    facebookController.dispose();
    instagramController.dispose();
    super.dispose();
  }

  void saveContact() async {
    if (_formKey.currentState!.validate()) {
      final contact = ContactModel(
        firstName: firstNameController.text,
        lastName: lastNameController.text,
        mobile: mobileController.text,
        email: emailController.text,
        address: addressController.text,
        company: companyController.text,
        designation: designationController.text,
        website: webController.text,
        linkedin: linkedinController.text,
        twitter: twitterController.text,
        facebook: facebookController.text,
        instagram: instagramController.text,
        image: image,
      );

      final provider = Provider.of<ContactProvider>(context, listen: false);
      final id = await provider.insertContact(contact);
      if (id > 0) {
        showMsg(context, 'Saved');
        Navigator.pop(context);
      } else {
        showMsg(context, 'Failed to save');
      }
    }
  }

  void autoFillFields(Map<String, String> inferred) {
    firstNameController.text = inferred[ContactProperties.firstName] ?? '';
    lastNameController.text = inferred[ContactProperties.lastName] ?? '';
    mobileController.text = inferred[ContactProperties.mobile] ?? '';
    emailController.text = inferred[ContactProperties.email] ?? '';
    addressController.text = inferred[ContactProperties.address] ?? '';
    companyController.text = inferred[ContactProperties.company] ?? '';
    designationController.text = inferred[ContactProperties.designation] ?? '';
    webController.text = inferred[ContactProperties.website] ?? '';
    linkedinController.text = inferred[ContactProperties.linkedin] ?? '';
    twitterController.text = inferred[ContactProperties.twitter] ?? '';
    facebookController.text = inferred[ContactProperties.facebook] ?? '';
    instagramController.text = inferred[ContactProperties.instagram] ?? '';

    // Debug print to see what was extracted
    print('=== ML Kit Extraction Results ===');
    inferred.forEach((key, value) {
      print('$key: "$value"');
    });
    print('Address extracted: "${inferred[ContactProperties.address]}"');
    print('Address length: ${inferred[ContactProperties.address]?.length}');
  }

  void getImage(ImageSource source) async {
    final xFile = await ImagePicker().pickImage(source: source);
    if (xFile != null) {
      setState(() {
        image = xFile.path;
        isScanOver = false;
        textBlocks.clear();
        uiImage = null;
      });

      EasyLoading.show(status: 'Please wait');

      final inputImage = InputImage.fromFile(File(xFile.path));
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final result = await recognizer.processImage(inputImage);

      final List<String> tempLines = [];
      for (final block in result.blocks) {
        for (final line in block.lines) {
          tempLines.add(line.text);
        }
      }

      final byteData = await File(xFile.path).readAsBytes();
      final codec = await ui.instantiateImageCodec(byteData);
      final frame = await codec.getNextFrame();

      final fullText = tempLines.join('\n');
      final inferred = await inferContactFieldsFromText(fullText); // ML Kit entity extraction
      autoFillFields(inferred);

      EasyLoading.dismiss();

      setState(() {
        textBlocks = result.blocks;
        uiImage = frame.image;
        isScanOver = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xff8160c7),
        title: const Text('Scan Page', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: image.isEmpty ? null : saveContact,
            icon: const Icon(Icons.save, color: Colors.white),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () => getImage(ImageSource.camera),
                icon: const Icon(Icons.camera),
                label: const Text('Capture'),
              ),
              TextButton.icon(
                onPressed: () => getImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_album),
                label: const Text('Gallery'),
              ),
            ],
          ),
          if (uiImage != null && textBlocks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: BusinessCardWithBoxes(
                image: uiImage!,
                blocks: textBlocks,
              ),
            ),
          if (isScanOver) buildEditableForm(),
        ],
      ),
    );
  }

  Widget buildEditableForm() {
    const fieldColor = Color(0xff8160c7);

    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: fieldColor),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
                controller: firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (v) => v == null || v.isEmpty ? emptyFieldErrMsg : null
            ),
            TextFormField(
                controller: lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name')
            ),
            TextFormField(
                controller: mobileController,
                decoration: const InputDecoration(labelText: 'Mobile'),
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.isEmpty ? emptyFieldErrMsg : null
            ),
            TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress
            ),
            // Fixed multiline address field
            TextFormField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                alignLabelWithHint: true, // Keeps label at top for multiline
              ),
              maxLines: null, // Allows unlimited lines
              minLines: 2,    // Shows at least 2 lines initially
              keyboardType: TextInputType.multiline,
            ),
            TextFormField(
                controller: companyController,
                decoration: const InputDecoration(labelText: 'Company')
            ),
            TextFormField(
                controller: designationController,
                decoration: const InputDecoration(labelText: 'Designation')
            ),
            TextFormField(
              controller: webController,
              decoration: const InputDecoration(labelText: 'Website'),
              keyboardType: TextInputType.url,
            ),
            TextFormField(
              controller: linkedinController,
              decoration: const InputDecoration(labelText: 'LinkedIn'),
              keyboardType: TextInputType.url,
            ),
            TextFormField(
              controller: twitterController,
              decoration: const InputDecoration(labelText: 'Twitter'),
              keyboardType: TextInputType.url,
            ),
            TextFormField(
              controller: facebookController,
              decoration: const InputDecoration(labelText: 'Facebook'),
              keyboardType: TextInputType.url,
            ),
            TextFormField(
              controller: instagramController,
              decoration: const InputDecoration(labelText: 'Instagram'),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
      ),
    );
  }
}

class BusinessCardWithBoxes extends StatelessWidget {
  final ui.Image image;
  final List<TextBlock> blocks;

  const BusinessCardWithBoxes({super.key, required this.image, required this.blocks});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final displayWidth = constraints.maxWidth;
        final displayHeight = displayWidth * (image.height / image.width);

        return SizedBox(
          width: displayWidth,
          height: displayHeight,
          child: Stack(
            children: [
              RawImage(image: image, fit: BoxFit.contain),
              CustomPaint(
                size: Size(displayWidth, displayHeight),
                painter: BoundingBoxPainter(
                  blocks,
                  image.width.toDouble(),
                  image.height.toDouble(),
                  displayWidth,
                  displayHeight,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class BoundingBoxPainter extends CustomPainter {
  final List<TextBlock> blocks;
  final double originalWidth;
  final double originalHeight;
  final double displayWidth;
  final double displayHeight;

  BoundingBoxPainter(this.blocks, this.originalWidth, this.originalHeight, this.displayWidth, this.displayHeight);

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = displayWidth / originalWidth;
    final double scaleY = displayHeight / originalHeight;

    final paint = Paint()
      ..color = const Color(0xff8160c7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var block in blocks) {
      final rect = block.boundingBox;
      if (rect != null) {
        final scaledRect = Rect.fromLTRB(
          rect.left * scaleX,
          rect.top * scaleY,
          rect.right * scaleX,
          rect.bottom * scaleY,
        );
        canvas.drawRect(scaledRect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
import 'package:tr_business_card_clone1/utils/constants.dart';

Map<String, String> inferContactFieldsFromLines(List<String> lines) {
  final result = <String, String>{};
  final seen = <String>{};

  final phoneRegex = RegExp(r'(?:\+91[\s\-]?)?\d{10}|\d{3,5}[-\s]?\d{6,8}');
  final emailRegex = RegExp(r'\b[\w\.-]+@[\w\.-]+\.\w{2,4}\b');
  final websiteRegex = RegExp(r'(https?:\/\/)?(www\.)?[\w\-]+\.\w{2,}(\/\S*)?');
  final addressKeywords = ['road', 'street', 'galli', 'nagar', 'market', 'colony', 'lane', 'camp'];

  for (final line in lines) {
    final text = line.trim();
    final lower = text.toLowerCase();
    if (text.isEmpty || seen.contains(text)) continue;
    seen.add(text);

    // Mobile
    if (result[ContactProperties.mobile] == null && phoneRegex.hasMatch(text)) {
      result[ContactProperties.mobile] = phoneRegex.firstMatch(text)!.group(0)!;
    }

    // Email
    else if (result[ContactProperties.email] == null && emailRegex.hasMatch(text)) {
      result[ContactProperties.email] = emailRegex.firstMatch(text)!.group(0)!;
    }

    // Website
    else if (result[ContactProperties.website] == null && websiteRegex.hasMatch(text)) {
      result[ContactProperties.website] = websiteRegex.firstMatch(text)!.group(0)!;
    }

    // Socials
    else if (lower.contains('linkedin') || lower.contains('linkedin.com')) {
      result[ContactProperties.linkedin] ??= text;
    } else if (lower.contains('twitter') || lower.contains('@') && lower.contains('tw')) {
      result[ContactProperties.twitter] ??= text;
    } else if (lower.contains('facebook')) {
      result[ContactProperties.facebook] ??= text;
    } else if (lower.contains('instagram')) {
      result[ContactProperties.instagram] ??= text;
    }

    // Designation detection by keyword
    else if (RegExp(r'(ceo|founder|director|manager|engineer|consultant|executive|head)', caseSensitive: false).hasMatch(lower)) {
      result[ContactProperties.designation] ??= text;
    }

    // Company - if short and uppercase or has known suffix
    else if (result[ContactProperties.company] == null &&
        (text.length < 40 && (text == text.toUpperCase() || text.contains('Pvt') || text.contains('LLC')))) {
      result[ContactProperties.company] = text;
    }

    // Address - keyword based
    else if (result[ContactProperties.address] == null &&
        addressKeywords.any((k) => lower.contains(k)) &&
        text.length > 15) {
      result[ContactProperties.address] = text;
    }

    // Name - assume topmost reasonable string
    else if (result[ContactProperties.firstName] == null &&
        RegExp(r'^[A-Z][a-z]+(?:\s[A-Z][a-z]+)+$').hasMatch(text)) {
      final words = text.split(' ');
      result[ContactProperties.firstName] = words[0];
      result[ContactProperties.lastName] = words.length > 1 ? words.sublist(1).join(' ') : '';
    }
  }

  return result;
}

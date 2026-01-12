// Stub implementation for non-web platforms
// This file provides a minimal interface matching dart:html for mobile platforms

class Window {
  final Document document = Document();
}

class Document {
  Element? getElementById(String id) {
    // No-op for non-web platforms
    return null;
  }
}

class CssStyleDeclaration {
  String display = '';
}

class Element {
  String innerHtml = '';
  final CssStyleDeclaration style = CssStyleDeclaration();
}

final window = Window();

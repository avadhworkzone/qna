import 'dart:html' as html;

class WebRedirect {
  static void go(String path) {
    html.window.location.assign(path);
  }
}

/// Data model for a DAW shortcut entry.
/// Keep lightweight: in-memory only, no persistence.
class ShortcutModel {
  final String command;
  final String shortcutMac;
  final String shortcutWindows;
  final String primaryCategory;
  final List<String> tags;
  final String functionType;
  final String description;

  const ShortcutModel({
    required this.command,
    required this.shortcutMac,
    required this.shortcutWindows,
    required this.primaryCategory,
    required this.tags,
    required this.functionType,
    required this.description,
  });

  @override
  String toString() =>
      'ShortcutModel(command: '+command+', mac: '+shortcutMac+', win: '+shortcutWindows+')';
}

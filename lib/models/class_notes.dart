// Armazenam classes que não geram elementos visuais

class Note {
  final int id;
  final String title;
  final String content;
  final String modificationDate;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.modificationDate,
  });

  @override
  String toString() {
    return '{id: $id, title: $title, content: $content, modificationDate: $modificationDate}';
  }
}

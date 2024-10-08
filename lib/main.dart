import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'models/notes.dart';

const double fontSize = 23.5;
Color mainColor = const Color(0xff193838);
Color mainColor2 = const Color(0x36363636);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yet Another Note App',
      themeMode: ThemeMode.system,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: mainColor, brightness: Brightness.light),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
            toolbarHeight: 70.0,
            backgroundColor: mainColor,
            foregroundColor: Colors.white,
            centerTitle: true,
            titleTextStyle: const TextStyle(fontSize: fontSize)),
        textSelectionTheme: const TextSelectionThemeData(
            cursorColor: (Color.fromARGB(255, 2, 7, 41)), selectionHandleColor: Color.fromARGB(255, 40, 53, 147)),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: mainColor2, brightness: Brightness.dark),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
            toolbarHeight: 70.0,
            backgroundColor: mainColor2,
            foregroundColor: Colors.white,
            centerTitle: true,
            titleTextStyle: const TextStyle(fontSize: fontSize)),
        textSelectionTheme: const TextSelectionThemeData(
            cursorColor: (Color.fromARGB(255, 159, 162, 182)),
            selectionHandleColor: Color.fromARGB(255, 123, 127, 129)),
      ),
      home: const MainPage(),
    );
  }
}

void showToast(String message) {
  Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: const Color.fromARGB(134, 0, 0, 0),
      textColor: Colors.white,
      fontSize: 14.0);
}

// Pega a última nota editada
Future<String> getLastEditedNote() async {
  final Directory directory = await getApplicationDocumentsDirectory();
  final List<FileSystemEntity> entities = directory.listSync();

  final List<File> files = entities.whereType<File>().toList();

  files.sort((a, b) {
    return b.statSync().modified.compareTo(a.statSync().modified);
  });

  if (files.isNotEmpty) {
    return files[0].path.split('/').last;
  } else {
    return '';
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  MainPageState createState() => MainPageState();
}

// Converte Note em Map
Map<String, dynamic> toMap(Note note) {
  return {
    'id': note.id,
    'title': note.title,
    'content': note.content,
    'modification_date': note.modificationDate,
  };
}

// Converte Map em Note
Note toNote(Map<String, dynamic> note) {
  return Note(
    id: note['id'],
    title: note['title'],
    content: note['content'],
    modificationDate: note['modification_date'],
  );
}

/*

// Classe Principal */
class MainPageState extends State<MainPage> {
  // chave do scaffold
  static GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  // variaveis estáticas
  static const String appBarTitle = 'Yet Another Note App';
  static const String defaultTitle = 'Untitled';

  // controladoras
  final TextEditingController titleController = TextEditingController();
  final TextEditingController textController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final List<bool> visiblePage = [true, false]; // Controladora das páginas visíveis
  String unchangedTitle = ''; // Controladora de alteracoes no título
  String unchangedText = ''; // Controladora de alteracoes no texto

  // database contents
  DatabaseHelper dbHelper = DatabaseHelper();

  // armazenamento das notas
  List<Note> notes = [];
  Note? actualNote;

  String lastEditedNote = '';
  int totalOfNotes = 0;

  // controladora de novas notas
  bool isNewNote = false;

  @override
  void initState() {
    super.initState();
    // _loadFiles();
    loadNotes();
  }

  void switchVisiblePage(int page) {
    // Altera a página visível de acordo com o número passado

    // saveLogic();

    setState(() {
      visiblePage[page] = true;
      if (page == 0) {
        visiblePage[1] = false;
        actualNote = null;
      } else {
        visiblePage[0] = false;
      }
      if (searchController.text.isNotEmpty) {
        searchController.text = '';
        loadNotes();
      }
    });
  }

  void createNewNote() async {
    await saveLogic();
    actualNote = null;
    switchVisiblePage(1);
    titleController.text = _getNewTitleName();
    textController.text = '';
  }

  Future<void> loadNotes({String searchText = ''}) async {
    List<Map<String, dynamic>> dbNotes = await dbHelper.getNote();
    List<Note> tempNotes = [];

    if (searchText.isEmpty) {
      for (Map<String, dynamic> note in dbNotes) {
        tempNotes.add(toNote(note));
      }
    } else {
      for (Map<String, dynamic> note in dbNotes) {
        Note _note = toNote(note);
        if (_note.title.toLowerCase().trim().contains(searchText) ||
            _note.content.toLowerCase().trim().contains(searchText)) {
          tempNotes.add(_note);
        }
      }
    }

    tempNotes.sort((b, a) => DateTime.parse(a.modificationDate).compareTo(DateTime.parse(b.modificationDate)));
    setState(() {
      notes.clear();
      notes = tempNotes;
      lastEditedNote = notes.isNotEmpty ? notes.first.title : '';
    });
  }

  // Funções de salvamento

  Future<void> saveLogic() async {
    if (actualNote == null) {
      if ((titleController.text.isNotEmpty && titleController.text != defaultTitle) || textController.text.isNotEmpty) {
        Note newNote = Note(
          id: await dbHelper.getLastId() + 1,
          title: titleController.text,
          content: textController.text,
          modificationDate: DateTime.now().toString(),
        );

        dbHelper.addNote(toMap(newNote));
      }
    } else if (titleController.text != actualNote!.title || textController.text != actualNote!.content) {
      Map<String, dynamic> editedNote = {
        'title': titleController.text,
        'content': textController.text,
        'modification_date': DateTime.now().toString(),
      };

      dbHelper.modifyNote(actualNote!.id, editedNote);
    }

    loadNotes();
  }

  String _getNewTitleName() {
    return defaultTitle;
  }

  Future<void> getNoteContent({int noteId = 0}) async {
    await saveLogic();
    if (noteId != 0) {
      List<Map<String, dynamic>> data = await dbHelper.getNote(id: noteId);
      actualNote = toNote(data[0]);
    }

    titleController.text = actualNote!.title;
    textController.text = actualNote!.content;
  }

  Future<bool?> deleteConfirmation(BuildContext context) {
    return showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirmation'),
            content: const Text('Note Will be deleted!'),
            actions: <Widget>[
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('No')),
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Yes')),
            ],
          );
        });
  }

  Future<void> deleteLogic(int noteId) async {
    bool? confirmation = await deleteConfirmation(context);

    if (confirmation!) {
      if (actualNote != null && noteId == actualNote!.id) {
        switchVisiblePage(0);
      }
      await dbHelper.removeNote(noteId);
      loadNotes();
    }
  }

  // Fim das funções de salvamento

  // Método build
  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final bool isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
    late Color primaryColors;
    late Color secondaryColors;

    if (!isDarkMode) {
      primaryColors = mainColor;
      secondaryColors = const Color.fromARGB(255, 173, 173, 173);
    } else {
      primaryColors = mainColor2;
      secondaryColors = const Color.fromARGB(255, 68, 68, 68);
    }

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Stack(children: [
          Visibility(visible: visiblePage[0], child: const Text(appBarTitle)),
          Visibility(
              visible: visiblePage[1],
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 52.5),
                  child: TextField(
                    maxLength: 27,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: null,
                    controller: titleController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: fontSize,
                    ),
                  ),
                ),
              ))
        ]),
      ),
      drawer: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: Drawer(
          shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 200.0,
                child: DrawerHeader(
                  padding: EdgeInsets.only(top: statusBarHeight),
                  decoration: BoxDecoration(
                    color: primaryColors,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const Spacer(
                        flex: 1,
                      ),
                      const Align(
                          alignment: Alignment(-0.195, 0.0),
                          child: Icon(IconData(0xE801, fontFamily: 'CustomIcon'), size: 65.0, color: Colors.white)),
                      const Spacer(
                        flex: 1,
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4.0, left: 4.0),
                          child: TextFormField(
                            // SEARCH BAR

                            onChanged: (_) async {
                              await loadNotes(searchText: searchController.text.trim().toLowerCase());
                            },
                            controller: searchController,
                            expands: false,
                            decoration: InputDecoration(
                              hintText: 'Search note...',
                              contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(flex: 1)
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: <Widget>[
                    ...notes.map((note) {
                      return GestureDetector(
                        onTap: () async {
                          if (scaffoldKey.currentState!.isDrawerOpen) {
                            setState(() {
                              scaffoldKey.currentState!.closeDrawer();
                            });
                          }
                          await saveLogic();
                          await getNoteContent(noteId: note.id);
                          switchVisiblePage(1);
                        },
                        onLongPress: () async {
                          if (scaffoldKey.currentState!.isDrawerOpen) {
                            setState(() {
                              scaffoldKey.currentState!.closeDrawer();
                            });
                          }
                          await saveLogic();
                          await deleteLogic(note.id);
                        },
                        child: FileCard(title: note.title, content: note.content),
                      );
                    })
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                color: primaryColors,
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Center(
                    child: ElevatedButton(
                        onPressed: () async {
                          if (scaffoldKey.currentState!.isDrawerOpen) {
                            setState(() {
                              scaffoldKey.currentState!.closeDrawer();
                            });
                          }
                          createNewNote();
                        },
                        style: ButtonStyle(
                          backgroundColor: isDarkMode
                              ? WidgetStatePropertyAll(primaryColors)
                              : const WidgetStatePropertyAll(Color.fromARGB(255, 16, 37, 37)),
                          foregroundColor: const WidgetStatePropertyAll(Colors.white),
                        ),
                        child: const Text('New Note')),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
      body: Stack(children: [
        PopScope(
          canPop: visiblePage[0],
          onPopInvoked: (_) async {
            if (scaffoldKey.currentState!.isDrawerOpen & visiblePage[1]) {
              setState(() {
                scaffoldKey.currentState!.closeDrawer();
              });
            } else {
              await saveLogic();
              switchVisiblePage(0);
              titleController.text = '';
              textController.text = '';
            }
          },
          child: Visibility(
            visible: visiblePage[0],
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: ElevatedButton(
                style: const ButtonStyle(
                    shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                    backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                    elevation: WidgetStatePropertyAll(0.0)),
                onPressed: () async {
                  createNewNote();
                },
                child: Center(
                    child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      const IconData(0xE800, fontFamily: 'CustomIcon'),
                      size: 150.0,
                      color: secondaryColors,
                    ),
                    const SizedBox(height: 20.0),
                    Text(
                      'Saved notes',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: secondaryColors,
                        fontSize: 16.0,
                      ),
                    ),
                    Text(
                      '${notes.length}',
                      style: TextStyle(
                        color: secondaryColors,
                        fontSize: 16.0,
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Text(
                      'Last edited node',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: secondaryColors,
                        fontSize: 16.0,
                      ),
                    ),
                    Text(
                      lastEditedNote,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: secondaryColors,
                        fontSize: 16.0,
                      ),
                    ),
                    const SizedBox(height: 25.0),
                    Text(
                      'Click anywhere to create\n a new note',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: secondaryColors,
                        fontSize: 16.0,
                      ),
                    ),
                  ],
                )),
              ),
            ),
          ),
        ),
        Visibility(
          visible: visiblePage[1],
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: textController,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              expands: true,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Write something...', border: InputBorder.none),
            ),
          ),
        ),
      ]),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Visibility(
        visible: visiblePage[0],
        child: FloatingActionButton.extended(
          onPressed: () async {
            await loadNotes();
            if (notes.isNotEmpty) {
              await getNoteContent(noteId: notes.first.id);
              switchVisiblePage(1);
            } else {
              createNewNote();
            }
          },
          heroTag: null,
          foregroundColor: Colors.white,
          backgroundColor: primaryColors,
          label: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              notes.isNotEmpty
                  ? const Text(
                      'Open last edited note',
                    )
                  : const Text('Write a new Note'),
              const SizedBox(
                width: 7.0,
              ),
              notes.isNotEmpty
                  ? const Icon(
                      Icons.timelapse,
                      semanticLabel: 'Open last edited note',
                    )
                  : const Icon(
                      Icons.edit,
                      semanticLabel: 'Write a new Note',
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class FileCard extends StatelessWidget {
  final String title;
  final String content;

  const FileCard({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    String firstLine = content.replaceAll('\n', ' ');

    if (firstLine.length > 40) {
      firstLine = '${firstLine.substring(0, 40)}...';
    } else if (content.length > firstLine.length) {
      firstLine = '$firstLine...';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(
                fontSize: 17.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              firstLine,
              style: const TextStyle(
                fontSize: 16.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

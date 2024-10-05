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

// Verifica se o arquivo existe
Future<bool> doesFileExists(String fileName) async {
  try {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String filePath = '${appDocDir.path}/$fileName';

    final File file = File(filePath);
    return await file.exists();
  } catch (e) {
    return false;
  }
}

// Deleta o arquivo, caso exista
Future<void> deleteFile(String fileName) async {
  try {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String filePath = '${appDocDir.path}/$fileName';

    final File file = File(filePath);

    if (await file.exists()) {
      await file.delete();
    }
  } catch (e) {
    print('Erro ao deletar o arquivo: $e');
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

  // armazenamento de nome dos arquivos
  List<String> _files = []; // Lista que armazena o nome dos arquivos
  List<String> _filesTexts = [];

  // armazenamento das notas
  List<Note> _notes = [];

  String lastEditedNote = '';
  int totalOfNotes = 0;

  Map<String, dynamic> note = {
    'title': 'Untitled 1',
    'content': 'Teste',
    'modification_date': DateTime.now().toString()
  };
  Map<String, dynamic> newNote = {'id': 1, 'title': 'Teste', 'content': 'Brabo dms'};

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Map<String, dynamic> toMap(Note note) {
    return {
      'id': note.id,
      'title': note.title,
      'content': note.content,
      'modification_date': note.modificationDate,
    };
  }

  Note toNote(Map<String, dynamic> note) {
    return Note(
      id: note['id'],
      title: note['title'],
      content: note['content'],
      modificationDate: note['modification_date'],
    );
  }

  void switchVisiblePage(int page) {
    // Altera a página visível de acordo com o número passado

    setState(() {
      visiblePage[page] = true;
      if (page == 0) {
        visiblePage[1] = false;
      } else {
        visiblePage[0] = false;
      }
      if (searchController.text.isNotEmpty) {
        searchController.text = '';
        _loadFiles();
      }
    });
  }

  Future<void> _loadNotes() async {
    _notes.clear();

    List<Map<String, dynamic>> notes = await dbHelper.getNote();
    for (Map<String, dynamic> n in notes) {
      _notes.add(toNote(n));
    }

    // print(_notes);
  }

  Future<void> _loadFiles() async {
    // Função que carrega os arquivos de forma ordenada pela data de alteração
    final Directory directory = await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> entities = directory.listSync();
    final List<File> files = entities.whereType<File>().toList();

    files.sort((a, b) {
      return b.statSync().modified.compareTo(a.statSync().modified);
    });

    List<String> titleList = [];
    List<String> textList = [];

    for (File file in files) {
      final String text = await file.readAsString();
      if (text.isNotEmpty) {
        textList.add(text);
      } else {
        textList.add('');
      }
      titleList.add(file.path.split('/').last);
    }

    // final String tempFileName = files[0].path.split('/').last;
    setState(() {
      lastEditedNote = files[0].path.split('/').last;
      totalOfNotes = files.length;
    });

    if (searchController.text.isEmpty) {
      setState(() {
        _files = files.map((file) => file.path.split('/').last).toList();
        _filesTexts = textList.map((text) => text).toList();
      });
    } else {
      setState(() {
        _files = [];
        _filesTexts = [];
        for (int i = 0; i < files.length; i++) {
          if ((titleList[i].toLowerCase().contains(searchController.text.toLowerCase()) ||
              (textList[i].toLowerCase().contains(searchController.text.toLowerCase())))) {
            _files.add(titleList[i]);
            _filesTexts.add(textList[i]);
          }
        }
      });
    }
  }

  Future<void> showDeleteConfirmationDialog(BuildContext context, String fileName) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('You sure?'),
          content: Text.rich(
            TextSpan(text: 'The note ', children: <TextSpan>[
              TextSpan(text: fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: ' will be deleted!')
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel')),
            TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  //showMessage(context, 'Note $fileName deleted.');
                  await deleteFile(fileName);
                  await _loadFiles();
                  showToast('Note $fileName deleted.');
                },
                child: const Text('Confirm'))
          ],
        );
      },
    );
  }

  // Funções de salvamento
  //
  //

  Future<void> saveLogic() async {
    /*  Função que trata o salvamento do arquivo

    casos:
      Arquvio novo {
      unchangedtitle é vazio;
      unchangedtext é vazio;
      [title não faz match com regex, text não é vazio]
      }

      Arquivo alterado {
      
      }
    
    */

    // define as expressões regulares que serão utilizadas
    const String pattern = '^$defaultTitle( [0-9]+)?\$';

    // Variaveis que armazenam o conteúdo das controladoras
    String title = titleController.text.trim();
    String text = textController.text;

    //
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$title';

    if (((unchangedTitle.isEmpty) & (unchangedText.isEmpty)) &
        ((!RegExp(pattern).hasMatch(title)) || (text.isNotEmpty))) {
      //
      print('ARQUIVO NOVO');

      if (await File(filePath).exists()) {
        titleController.text = await _getNewTitleName(newTitle: title);
      }
      await _saveToFile();
    } else if ((title == unchangedTitle) & (text != unchangedText)) {
      //ARQUIVO ALTERADO
      print('ARQUIVO ALTERADO');

      await _saveToFile();
    } else if ((title != unchangedTitle) & (unchangedTitle.isNotEmpty)) {
      // ARQUIVO RENOMEADO
      print('ARQUIVO RENOMEADO');

      if (await File(filePath).exists() || filePath.isEmpty) {
        //
        print('FILE ALREADY EXISTS');

        titleController.text = await _getNewTitleName(newTitle: title);
      }
      await renameFile();
      await _saveToFile();
    }
  }

  Future<void> _saveToFile() async {
    // Função que salva as alterações

    String title = titleController.text;
    String text = textController.text;

    if (title.isEmpty) {
      title = await _getNewTitleName();
    }

    final directory = await getApplicationDocumentsDirectory();
    final fileName = title;
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(text);
    _loadFiles();
    showToast('Note $fileName saved');
  }

  Future<String> _getNewTitleName({String newTitle = defaultTitle}) async {
    /* Função que gera um novo nome para o arquivo 
    
    casos:
      newTitle é vazio {
        usa o nome padrão 
      }
      newTitle não é vazio {
        uso o nome passado
      }
    
    retona uma String com o título + número
    */

    // armazena o número da cópia do aplicativo
    int newFileNumber = 0;

    final Directory directory = await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> entities = directory.listSync();
    final List<File> files = entities.whereType<File>().toList();
    final List<String> allNames = files.map((file) => file.path.split('/').last).toList();

    // verifica se o título possui números em seu final
    if (RegExp(r'[0-9]$').hasMatch(newTitle.trim())) {
      newTitle = newTitle.replaceAll(RegExp(r'(\d+)$'), '').trim();
    }

    // verifica se o título já editado está presente nos arquivos
    if (allNames.contains(newTitle)) {
      ++newFileNumber;
      while (allNames.contains('$newTitle ${newFileNumber.toString()}')) {
        ++newFileNumber;
      }
    }

    // retorna o novo título com o número, caso seja maior do que 0
    if (newFileNumber > 0) {
      return '$newTitle ${newFileNumber.toString()}';
    } else {
      return newTitle;
    }
  }

  Future<void> renameFile() async {
    // renomeia o arquivo
    final String oldFileName = unchangedTitle;
    final String newFileName = titleController.text;

    final Directory directory = await getApplicationDocumentsDirectory();
    final String oldFilePath = '${directory.path}/$oldFileName';
    final String newFilePath = '${directory.path}/$newFileName';

    final File oldFile = File(oldFilePath);

    if (await oldFile.exists()) {
      showToast('Note "$oldFileName" renamed to "$newFileName"');
      await oldFile.rename(newFilePath);
      await _loadFiles();
    }
  }

  Future<void> getFileContent({String fileName = ''}) async {
    // pega o conteúdo de um arquivo
    late List<String> fileContent = [];

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');

    if (fileName.isNotEmpty) {
      fileContent.add(fileName);
      fileContent.add(await file.readAsString());
      unchangedTitle = fileName;
    } else {
      fileContent.add(await _getNewTitleName());
      fileContent.add('');
    }
    unchangedText = fileContent[1];

    setState(() {
      titleController.text = fileContent[0];
      textController.text = fileContent[1];
    });
  }

  Future<String> getFileText(String fileName) async {
    // pega o conteúdo de um arquivo

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');

    return await file.readAsString();
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
                            /*
                            
                            SEARCH BAR

                             */

                            onChanged: (_) async {
                              await _loadFiles();
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
                              //fillColor: Colors.white,
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
                    ..._files.map((file) {
                      return GestureDetector(
                        onTap: () async {
                          // Função do ListTile que

                          if (scaffoldKey.currentState!.isDrawerOpen) {
                            setState(() {
                              scaffoldKey.currentState!.closeDrawer();
                            });
                          }
                          if (unchangedTitle.isNotEmpty || textController.text.isNotEmpty) {
                            await saveLogic();
                          }
                          await getFileContent(fileName: file);
                          switchVisiblePage(1);
                        },
                        onLongPress: () async {
                          if ((unchangedTitle == file) || (titleController.text == file)) {
                            switchVisiblePage(0);
                          }
                          if (scaffoldKey.currentState!.isDrawerOpen) {
                            setState(() {
                              scaffoldKey.currentState!.closeDrawer();
                            });
                          }
                          await showDeleteConfirmationDialog(context, file);
                        },
                        child: FileCard(
                          title: file,
                          content: _filesTexts[_files.indexOf(file)],
                        ),
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
                          if (visiblePage[1]) {
                            await saveLogic();
                            titleController.text = '';
                            textController.text = '';
                            unchangedTitle = '';
                            unchangedText = '';
                          }
                          switchVisiblePage(1);
                          getFileContent();
                          if (scaffoldKey.currentState!.isDrawerOpen) {
                            setState(() {
                              scaffoldKey.currentState!.closeDrawer();
                            });
                          }
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
              unchangedTitle = '';
              unchangedText = '';
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
                  // switchVisiblePage(1);
                  // getFileContent();
                  dbHelper.addNote(note);
                },
                child: Center(
                    child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // SvgPicture.asset(
                    //   'assets/images/background.svg',
                    // ),
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
                      '$totalOfNotes',
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
            String lastEditedNote = await getLastEditedNote();
            if (lastEditedNote.isNotEmpty) {
              await dbHelper.modifyNote(newNote['id'], newNote);
              await _loadNotes();
              print('conteudo da lista:\n\n');
              print(_notes);
              print('\n\n:conteudo da lista');
            }
          },
          heroTag: null,
          foregroundColor: Colors.white,
          backgroundColor: primaryColors,
          label: const Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Text(
                'Open last edited note',
              ),
              SizedBox(
                width: 7.0,
              ),
              Icon(
                Icons.timelapse,
                semanticLabel: 'Open last edited note',
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

  String toString() {
    return '{id: $id, title: $title, content: $content, modificationDate: $modificationDate}';
  }
}

// Import required built in libraries.
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

// Import required external libraries.
import 'package:file_picker/file_picker.dart'; // File picker.

void main() => runApp(const Main());

class _MainState extends State<Main> {
  String _location = 'null';

  late String _current = ''; // DONE: Implement directory navigation.
  late List _currentData;

  List _branches = [];

  String _sidebarContentState = "";

  void _currentUpdate() {
    _currentData = [];

    List i = Directory("$_location$_current").listSync(
      recursive: false,
      followLinks: false,
    );

    for (var j = 0; j < i.length; j++) {
      _currentData.add(i[j].toString());
      _currentData[j] = _currentData[j].replaceAll("File: '", "").replaceAll("Directory: '", "");
      _currentData[j] = _currentData[j].substring(0, _currentData[j].length-1);
    }

    _currentData.remove("$_location$_current/.git");
    _currentData.sort();

    if (_current != "") {
      _currentData.insert(0, "$_location$_current/..");
    }
  }

  final GlobalKey<ScaffoldState> _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Feta',
      home: Scaffold(
        key: _key,
        appBar: AppBar(
          title: Text(_location.split("/").last),
          leading: GestureDetector(
            onTap: () async {
              // TODO: Find the directory for a new project.
              String? result = await FilePicker.platform.getDirectoryPath();
              if (result != 'null') {
                bool resultExists = await Directory(result!).exists();
                bool resultIsGit = await Directory("$result/.git").exists();
                if (resultExists) {
                  if (resultIsGit) {
                    setState(() {
                      _location = result;
                      _current = '';
                      _currentUpdate();
                    });
                  }
                }
              }
            },
            child: const Icon(Icons.add),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () {
                  // TODO: On click, launch a context menu for more options.
                },
                child: const Icon(Icons.more_horiz),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () {
                  _key.currentState!.openEndDrawer();
                  // TODO: Show the commit history on click.
                },
                child: const Icon(Icons.history),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () async {
                  var branchResult = await Process.start(
                      "git", ["branch", "-a"],
                      workingDirectory: _location);

                  branchResult.stdout
                      .transform(utf8.decoder)
                      .forEach((String out) => {
                    setState(() {
                      _branches = const LineSplitter().convert(out);
                    }),
                  });

                  setState(() {_sidebarContentState = "branches";});
                  _key.currentState!.openEndDrawer();
                  // DONE: Show the branch list on click.
                  // TODO: Implement branch switching and simplification.
                },
                child: const Icon(Icons.account_tree_outlined),
              ),
            ),
          ],
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            child: Column(
                children: [
                  if (_location != 'null') ...[
                    for (var i = 0; i < _currentData.length; i++)
                      GestureDetector(
                        onTap: () async {
                          if (await Directory(_currentData[i]).exists()) {
                            Directory(_currentData[i]).listSync();

                            setState(() {
                              _current =
                                  _currentData[i].replaceAll(_location, "");

                              if (_current.split("/").last == "..") {
                                _current =
                                    _current.substring(0, _current.length - 3);
                                _current = _current.replaceAll(_current
                                    .split("/").last, "");
                                _current =
                                    _current.substring(0, _current.length - 1);
                              }

                              _currentUpdate();
                            });
                          }
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(width: 1.5, color: Colors.black),
                              left: BorderSide(width: 1.5, color: Colors.black),
                              right: BorderSide(width: 1.5, color: Colors.black),
                            ),
                          ),
                          padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(right: 8.0),
                                        child: Icon(Icons.circle_outlined, size: 16.0),
                                        // circle_outlined, add_circle, remove_circle
                                      ),
                                      Text(_currentData[i].split("/").last),
                                    ],
                                  ),
                                ),
                                const Align(
                                    alignment: Alignment.centerRight,
                                    child: Text('*LAST COMMIT*') // TODO: Fill text with the file's last commit.
                                ),
                              ]
                          ),
                        ),
                      ),
                    Container( // (Bottom border for decorations sake...)
                      height: 1.5,
                      decoration: const BoxDecoration(color: Colors.black),
                    ),
                  ]
                ]
            ),
          ),
        ),
        endDrawer: Sidebar(_sidebarContentState, _branches, _location),
      ),
    );
  }
}

class Main extends StatefulWidget {
  const Main({super.key});

  @override
  State<Main> createState() => _MainState();
}

class _SidebarState extends State<Sidebar> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SingleChildScrollView(
        child: Column(
            children: [
              if (widget.sidebarContent == "branches") ...[
                const Padding(
                  padding: EdgeInsets.only(left: 10.0, right: 10.0, top: 20.0, bottom: 15.0),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Text("Branches"),
                  ),
                ),
                for (var i = 0; i < widget.sidebarBranches.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 5.0, bottom: 5.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: GestureDetector(
                        onTap: () {
                          void checkoutBranch() async {
                            await Process.start(
                                "git", ["checkout", "master"],
                                workingDirectory: widget.targetLocation);
                          }

                          checkoutBranch();
                          Navigator.pop(context);
                        },
                        child: Text(widget.sidebarBranches[i]),
                      ),
                    ),
                  ),
              ],
            ]
        ),
      ),
    ); // TODO: Extend sidebar for branches and commit history.
  }
}

class Sidebar extends StatefulWidget {
  final String sidebarContent;
  final List sidebarBranches;
  final String targetLocation;
  const Sidebar(this.sidebarContent, this.sidebarBranches, this.targetLocation);

  @override
  State<Sidebar> createState() => _SidebarState();
}
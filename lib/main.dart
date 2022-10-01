// Import required built in libraries.
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

// Import required external libraries.
import 'package:collection/collection.dart'; // List manipulation.
import 'package:file_picker/file_picker.dart'; // File picker.

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Feta',
      home: Main(),
    );
  }
}

class _MainState extends State<Main> {
  String _location = 'null';

  late String _current = '';
  late List _currentData;
  late List _currentDataAndDeleted;
  List _currentDataStaged = [];
  List _currentDataUnstaged = [];
  List _currentDeleted = [];

  List _branches = [];
  List _history = [];

  String _sidebarContentState = "";

  void _currentUpdate(
      var deletedResult, var stagedResult, var unstagedResult) async {
    _currentData = [];

    List i = Directory("$_location$_current").listSync(
      recursive: false,
      followLinks: false,
    );

    setState(() {
      for (var j = 0; j < i.length; j++) {
        _currentData.add(i[j].toString());
        _currentData[j] = _currentData[j]
            .replaceAll("File: '", "")
            .replaceAll("Directory: '", "");
        _currentData[j] =
            _currentData[j].substring(0, _currentData[j].length - 1);
      }

      _currentData.remove("$_location$_current/.git");
      if (_current != "") {
        _currentData.insert(0, "$_location$_current/..");
      }

      _currentData.sort();
    });

    await deletedResult.stdout.transform(utf8.decoder).forEach((String out) => {
          _currentDeleted = const LineSplitter().convert(out),
        });

    await stagedResult.stdout.transform(utf8.decoder).forEach((String out) => {
          _currentDataStaged = const LineSplitter().convert(out),
          // TODO: Include deleted files when staged.
        });

    await unstagedResult.stdout
        .transform(utf8.decoder)
        .forEach((String out) => {
              _currentDataUnstaged = const LineSplitter().convert(out),
            });

    setState(() {
      for (var i = _currentDeleted.length - 1; i >= 0; i--) {
        var j = _currentDeleted[i].split("/");
        j.remove(_currentDeleted[i].split("/").last);

        var k = _current.split("/");
        k.remove("");

        if (const ListEquality().equals(j, k)) {
          var l = _currentDeleted[i];
          _currentDeleted[i] = "$_location/$l";
        } else {
          _currentDeleted.removeAt(i);
        }
      }

      for (var i = 0; i < _currentDataStaged.length; i++) {
        var l = _currentDataStaged[i];
        _currentDataStaged[i] = "$_location/$l";
      }

      for (var i = 0; i < _currentDataUnstaged.length; i++) {
        var l = _currentDataUnstaged[i];
        _currentDataUnstaged[i] = "$_location/$l";
      }

      _currentDataAndDeleted = List.from(_currentData)..addAll(_currentDeleted);
      _currentDataAndDeleted.sort();
    });

    //print(_currentDataAndDeleted);
  }

  void _refresh() async {
    var deletedResult = await Process.start("git", ["ls-files", "--deleted"],
        workingDirectory: _location);

    var stagedResult = await Process.start(
        "git", ["diff", "--name-only", "--staged"],
        workingDirectory: _location);

    var unstagedResult = await Process.start(
        "git", ["ls-files", "--exclude-standard", "--others", "-m"],
        workingDirectory: _location);

    _currentUpdate(deletedResult, stagedResult, unstagedResult);
  }

  final GlobalKey<ScaffoldState> _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    Color deletedColor(var item) {
      if (_currentDeleted.contains(_currentDataAndDeleted[item])) {
        return Colors.grey;
      } else {
        return Colors.black;
      }
    }

    IconData stagingIcon(var item) {
      if (_currentDataStaged.contains(_currentDataAndDeleted[item]) &&
          _currentDataUnstaged.contains(_currentDataAndDeleted[item])) {
        return Icons
            .swap_vert_circle; // build_circle, change_circle, playlist_add_circle, swap_horiz_circle, swap_vert_circle
      } else if (_currentDataStaged.contains(_currentDataAndDeleted[item])) {
        return Icons.add_circle;
      } else if (_currentDataUnstaged.contains(_currentDataAndDeleted[item])) {
        return Icons.remove_circle;
      } else {
        return Icons.circle_outlined;
      }
    }

    Color stagingIconColor(int item) {
      if (_currentDataStaged.contains(_currentDataAndDeleted[item]) &&
          _currentDataUnstaged.contains(_currentDataAndDeleted[item])) {
        return Colors.deepPurple;
      } else if (_currentDataStaged.contains(_currentDataAndDeleted[item])) {
        return Colors.green;
      } else if (_currentDataUnstaged.contains(_currentDataAndDeleted[item])) {
        return Colors.red;
      } else {
        return Colors.black;
      }
    }

    String typeName(int item) {
      if (_currentDeleted.contains(_currentDataAndDeleted[item])) {
        return "Deleted";
      } else if (Directory(_currentDataAndDeleted[item]).existsSync()) {
        return "Directory";
        // NOTE: This also includes '..', noting for future reference.
      } else {
        return "File";
      }
    }

    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Text(_location.split("/").last),
        leading: SizedBox(
          width: 24,
          height: 24,
          child: IconButton(
            padding: const EdgeInsets.all(0.0),
            icon: const Icon(
              Icons.add,
              size: 24.0,
            ),
            tooltip: "Open Project",
            onPressed: () async {
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
                    });

                    _refresh();
                  } else {
                    var alert = AlertDialog(
                      title: const Text("New Repository"),
                      content: const Text(
                          "The following directory is not a Git repository. Would you like to initialize one here?"),
                      actions: [
                        TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("No")),
                        TextButton(
                            onPressed: () async {
                              Navigator.of(context).pop();

                              await Process.run("git", ["init"],
                                  workingDirectory: result);

                              setState(() {
                                _location = result;
                                _current = '';
                              });
                              _refresh();
                            },
                            child: const Text("Yes")),
                      ],
                    );

                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return alert;
                        });
                  }
                }
              }
            },
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: PopupMenuButton<int>(
              padding: const EdgeInsets.all(0.0),
              icon: const Icon(
                Icons.more_horiz,
                size: 24.0,
              ),
              tooltip: "Options",
              itemBuilder: (context) => [
                PopupMenuItem<int>(
                  child: const Text("New Commit"),
                  onTap: () {
                    TextEditingController commitMessage =
                        TextEditingController();
                    String commitChanges =
                        _currentDataStaged.join("\n").replaceAll(_location, "");
                    Future.delayed(
                        const Duration(seconds: 0),
                        () => showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('New Commit'),
                                content: SizedBox(
                                  height: 200,
                                  child: Column(
                                    children: [
                                      TextField(
                                        controller: commitMessage,
                                        decoration: const InputDecoration(
                                          hintText: "Message",
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.only(
                                            top: 30.0, bottom: 5.0),
                                        child: Align(
                                          alignment: Alignment.topLeft,
                                          child: Text("Items to be committed:"),
                                        ),
                                      ),
                                      Container(
                                        width: 240,
                                        constraints: const BoxConstraints(
                                          minHeight: 80,
                                        ),
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                          color: Colors.black,
                                          width: 1,
                                        )),
                                        child: SingleChildScrollView(
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(4.0),
                                              child: Text(
                                                commitChanges,
                                                style: const TextStyle(
                                                  fontSize: 12.0,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text("Cancel")),
                                  TextButton(
                                      onPressed: () async {
                                        Navigator.of(context).pop();

                                        await Process.run(
                                            "git",
                                            [
                                              "commit",
                                              "-m",
                                              commitMessage.text
                                            ],
                                            workingDirectory: _location);

                                        _refresh();
                                      },
                                      child: const Text("Apply")),
                                ],
                              );
                            }));
                  },
                ),
                PopupMenuItem<int>(
                  child: const Text("Revert Commit"),
                  onTap: () {
                    TextEditingController revertMessage =
                        TextEditingController();
                    TextEditingController revertCommit =
                        TextEditingController();
                    Future.delayed(
                        const Duration(seconds: 0),
                        () => showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Revert Commit'),
                                content: SizedBox(
                                  height: 100,
                                  child: Column(
                                    children: [
                                      TextField(
                                        controller: revertCommit,
                                        decoration: const InputDecoration(
                                          hintText: "Commit (ex: f668902)",
                                        ),
                                      ),
                                      TextField(
                                        controller: revertMessage,
                                        decoration: const InputDecoration(
                                          hintText: "Message",
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text("Cancel")),
                                  TextButton(
                                      onPressed: () async {
                                        Navigator.of(context).pop();

                                        await Process.run(
                                            "git",
                                            [
                                              "revert",
                                              "--no-commit",
                                              revertCommit.text
                                            ],
                                            workingDirectory: _location);

                                        await Process.run(
                                            "git",
                                            [
                                              "commit",
                                              "-m",
                                              revertMessage.text
                                            ],
                                            workingDirectory: _location);

                                        _refresh();
                                      },
                                      child: const Text("Apply")),
                                ],
                              );
                            }));
                  },
                ),
                const PopupMenuDivider(),
                PopupMenuItem<int>(
                  child: const Text("Pull Commits"),
                  onTap: () async {
                    await Process.run("git", ["pull"],
                        workingDirectory: _location);
                    _refresh();
                  },
                ),
                PopupMenuItem<int>(
                  child: const Text("Push Commits"),
                  onTap: () async {
                    await Process.run("git", ["push"],
                        workingDirectory: _location);
                    // Unneeded to refresh since nothing local is affected.
                  },
                ),
                PopupMenuItem<int>(
                  child: const Text("Refresh"),
                  onTap: () {
                    _refresh();
                  },
                ),
                const PopupMenuDivider(),
                PopupMenuItem<int>(
                  child: const Text("Preferences"),
                  onTap: () {},
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: IconButton(
              padding: const EdgeInsets.all(0.0),
              icon: const Icon(
                Icons.history,
                size: 24.0,
              ),
              tooltip: "Commit History",
              onPressed: () async {
                var historyResult = await Process.start(
                    "git", ["log", "--oneline"], // TODO: Split into pages.
                    workingDirectory: _location);

                var pipeHead = await Process.start("head", ["-n", "25"]);
                // This contains the number of entries from start before getting cut.
                historyResult.stdout.pipe(pipeHead.stdin);

                var pipeTail = await Process.start("tail", ["-n", "25"]);
                // This cuts out the entries at the end, returning a certain number of entries at a certain point.
                pipeHead.stdout.pipe(pipeTail.stdin);

                pipeTail.stdout
                    .transform(utf8.decoder)
                    .forEach((String out) => {
                          setState(() {
                            List i = const LineSplitter().convert(out);

                            _history = [];
                            for (var j = 0; j < i.length; j++) {
                              var k = i[j].split(" ").first;
                              _history.add([k, i[j].replaceAll("$k ", "")]);
                            }

                            //print(_history);
                          }),
                        });

                setState(() {
                  _sidebarContentState = "history";
                });
                _key.currentState!.openEndDrawer();
                // TODO: Show the commit history on click.
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: IconButton(
              padding: const EdgeInsets.all(0.0),
              icon: const Icon(
                Icons.account_tree_outlined,
                size: 24.0,
              ),
              tooltip: "Branches",
              onPressed: () async {
                var branchResult = await Process.start("git", ["branch", "-a"],
                    workingDirectory: _location);

                branchResult.stdout
                    .transform(utf8.decoder)
                    .forEach((String out) => {
                          setState(() {
                            _branches = const LineSplitter().convert(out);
                          }),
                        });

                setState(() {
                  _sidebarContentState = "branches";
                });
                _key.currentState!.openEndDrawer();
                // DONE: Show the branch list on click.
              },
            ),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: Column(children: [
            if (_location != 'null') ...[
              for (var i = 0; i < _currentDataAndDeleted.length; i++) ...[
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(width: 1.5, color: Colors.black),
                      left: BorderSide(width: 1.5, color: Colors.black),
                      right: BorderSide(width: 1.5, color: Colors.black),
                    ),
                  ),
                  padding: const EdgeInsets.only(
                      left: 10, right: 10, top: 10, bottom: 10),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: IconButton(
                                      padding: const EdgeInsets.all(0.0),
                                      icon: Icon(stagingIcon(i),
                                          color: stagingIconColor(i),
                                          size: 16.0),
                                      onPressed: !_currentDataStaged.contains(
                                                  _currentDataAndDeleted[i]) &&
                                              !_currentDataUnstaged.contains(
                                                  _currentDataAndDeleted[i])
                                          ? null
                                          : () async {
                                              if (_currentDataUnstaged.contains(
                                                      _currentDataAndDeleted[
                                                          i]) ||
                                                  (_currentDataStaged.contains(
                                                          _currentDataAndDeleted[
                                                              i]) &&
                                                      _currentDataUnstaged.contains(
                                                          _currentDataAndDeleted[
                                                              i]))) {
                                                await Process.run(
                                                    "git",
                                                    [
                                                      "add",
                                                      _currentDataAndDeleted[i]
                                                          .replaceAll(
                                                              "$_location/", "")
                                                    ],
                                                    workingDirectory:
                                                        _location);
                                              } else if (_currentDataStaged
                                                  .contains(
                                                      _currentDataAndDeleted[
                                                          i])) {
                                                await Process.run(
                                                    "git",
                                                    [
                                                      "reset",
                                                      "--",
                                                      _currentDataAndDeleted[i]
                                                          .replaceAll(
                                                              "$_location/", "")
                                                    ],
                                                    workingDirectory:
                                                        _location);
                                              }

                                              _refresh();
                                            },
                                    )),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  if (await Directory(_currentData[i])
                                      .exists()) {
                                    Directory(_currentData[i]).listSync();

                                    setState(() {
                                      _current = _currentData[i]
                                          .replaceAll(_location, "");

                                      if (_current.split("/").last == "..") {
                                        _current = _current.substring(
                                            0, _current.length - 3);
                                        _current = _current.replaceAll(
                                            _current.split("/").last, "");
                                        _current = _current.substring(
                                            0, _current.length - 1);
                                      }
                                    });

                                    _refresh();
                                  }
                                },
                                child: Text(
                                  _currentDataAndDeleted[i].split("/").last,
                                  style: TextStyle(
                                    color: deletedColor(i),
                                    //color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text(typeName(i)),
                              ),
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: PopupMenuButton<int>(
                                  padding: const EdgeInsets.all(0.0),
                                  icon: const Icon(
                                    Icons.more_vert,
                                    size: 16.0,
                                  ),
                                  itemBuilder: (context) => [
                                    PopupMenuItem<int>(
                                      child: const Text("Stage"),
                                      onTap: () async {
                                        await Process.run(
                                            "git",
                                            [
                                              "add",
                                              _currentDataAndDeleted[i]
                                                  .replaceAll("$_location/", "")
                                            ],
                                            workingDirectory: _location);
                                        _refresh();
                                      },
                                    ),
                                    PopupMenuItem<int>(
                                      child: const Text("Unstage"),
                                      onTap: () async {
                                        await Process.run(
                                            "git",
                                            [
                                              "reset",
                                              "--",
                                              _currentDataAndDeleted[i]
                                                  .replaceAll("$_location/", "")
                                            ],
                                            workingDirectory: _location);
                                        _refresh();
                                      },
                                    ),
                                    const PopupMenuDivider(),
                                    PopupMenuItem<int>(
                                      child: const Text("Restore"),
                                      onTap: () async {
                                        await Process.run(
                                            "git",
                                            [
                                              "restore",
                                              _currentDataAndDeleted[i]
                                                  .replaceAll("$_location/", "")
                                            ],
                                            workingDirectory: _location);
                                        _refresh();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]),
                ),
              ],
              Container(
                // (Bottom border for decorations sake...)
                height: 1.5,
                decoration: const BoxDecoration(color: Colors.black),
              ),
            ]
          ]),
        ),
      ),
      endDrawer: Sidebar(_sidebarContentState, _branches, _history, _location),
      onEndDrawerChanged: (isOpen) async {
        if (!isOpen) {
          _refresh();
        }
      },
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
    Color selectedColor(String i) {
      if (i[0] == '*') {
        if (i.contains("detached")) {
          return Colors.red;
        } else {
          return Colors.blue;
        }
      } else {
        return Colors.black;
      }
    }

    return Drawer(
      child: SingleChildScrollView(
        child: Column(children: [
          if (widget.sidebarContent == "branches") ...[
            const Padding(
              padding: EdgeInsets.only(
                  left: 10.0, right: 10.0, top: 20.0, bottom: 15.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: Text("Local"),
              ),
            ),
            for (var i = 0; i < widget.sidebarBranches.length; i++) ...[
              if (!widget.sidebarBranches[i]
                  .substring(2, widget.sidebarBranches[i].length)
                  .split(" -> ")
                  .last
                  .startsWith("remotes/")) ...[
                Padding(
                  padding: const EdgeInsets.only(
                      left: 10.0, right: 10.0, top: 5.0, bottom: 5.0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () {
                        void checkoutBranch() async {
                          await Process.start(
                              "git",
                              [
                                "checkout",
                                widget.sidebarBranches[i]
                                    .substring(
                                        2, widget.sidebarBranches[i].length)
                                    .split(" -> ")
                                    .last
                              ],
                              workingDirectory: widget
                                  .targetLocation); // TODO: Fix branching system.
                        }

                        if (!widget.sidebarBranches[i]
                            .substring(2, widget.sidebarBranches[i].length)
                            .startsWith("(")) {
                          checkoutBranch();
                        }
                        Navigator.pop(context);
                      },
                      child: Stack(
                        children: [
                          Text(
                            /*widget.sidebarBranches[i]
                                .substring(2, widget.sidebarBranches[i].length)
                                .split(" -> ")
                                .last,*/
                            (() {
                              if (widget.sidebarBranches[i].contains("(")) {
                                return widget.sidebarBranches[i]
                                    .substring(
                                        2, widget.sidebarBranches[i].length - 1)
                                    .split(" ")
                                    .last;
                              } else {
                                return widget.sidebarBranches[i]
                                    .substring(
                                        2, widget.sidebarBranches[i].length)
                                    .split(" -> ")
                                    .last;
                              }
                            }()),
                            style: TextStyle(
                                color:
                                    selectedColor(widget.sidebarBranches[i])),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
            GestureDetector(
              child: const Text("+ Add New"),
              onTap: () {
                TextEditingController branchName = TextEditingController();
                Future.delayed(
                    const Duration(seconds: 0),
                    () => showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('New Branch'),
                            content: TextField(
                              controller: branchName,
                              decoration: const InputDecoration(
                                hintText: "Branch Name (ex: 'master')",
                              ),
                            ),
                            actions: [
                              TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text("Cancel")),
                              TextButton(
                                  onPressed: () async {
                                    Navigator.of(context).pop();

                                    Process.run("git",
                                        ["checkout", "-b", branchName.text],
                                        workingDirectory:
                                            widget.targetLocation);
                                  },
                                  child: const Text("Add")),
                            ],
                          );
                        }));
              },
            ),
            const Padding(
              padding: EdgeInsets.only(
                  left: 10.0, right: 10.0, top: 20.0, bottom: 15.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: Text("Remote"),
              ),
            ),
            for (var i = 0; i < widget.sidebarBranches.length; i++) ...[
              if (widget.sidebarBranches[i]
                  .substring(2, widget.sidebarBranches[i].length)
                  .split(" -> ")
                  .last
                  .startsWith("remotes/")) ...[
                Padding(
                  padding: const EdgeInsets.only(
                      left: 10.0, right: 10.0, top: 5.0, bottom: 5.0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () {
                        void checkoutBranch() async {
                          await Process.start(
                              "git",
                              [
                                "checkout",
                                widget.sidebarBranches[i]
                                    .substring(
                                        2, widget.sidebarBranches[i].length)
                                    .split(" -> ")
                                    .last
                              ],
                              workingDirectory: widget
                                  .targetLocation); // TODO: Fix branching system.
                        }

                        checkoutBranch();
                        Navigator.pop(context);
                      },
                      child: Text(
                        widget.sidebarBranches[i]
                            .substring(2, widget.sidebarBranches[i].length)
                            .split(" -> ")
                            .last,
                        style: TextStyle(
                            color: selectedColor(widget.sidebarBranches[i])),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ] else if (widget.sidebarContent == "history") ...[
            Column(
              children: [
                for (var i = 0; i < widget.sidebarHistory.length; i++) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(widget.sidebarHistory[i][0]),
                      ),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(widget.sidebarHistory[i][1],
                              textAlign: TextAlign.right),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ]),
      ),
    ); // TODO: Extend sidebar for commit history.
  }
}

class Sidebar extends StatefulWidget {
  final String sidebarContent;
  final List sidebarBranches;
  final List sidebarHistory;
  final String targetLocation;

  const Sidebar(this.sidebarContent, this.sidebarBranches, this.sidebarHistory,
      this.targetLocation);

  @override
  State<Sidebar> createState() => _SidebarState();
}

// Import required built in libraries.
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

// Import required external libraries.
import 'package:collection/collection.dart'; // List manipulation.
import 'package:file_picker/file_picker.dart'; // File picker.

// Import the created scripts.
import 'package:gitbang/dialogs/clone_repository.dart';
import 'package:gitbang/dialogs/new_repository.dart';
import 'package:gitbang/dialogs/new_commit.dart';
import 'package:gitbang/dialogs/revert_commit.dart';
import 'package:gitbang/sidebar/main.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GitBang',
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
  late List _currentDataStagedFilesOnly;
  List _currentDataUnstaged = [];
  List _currentDeleted = [];

  List _branches = [];

  String _sidebarContentState = "";

  void _currentUpdate(var deletedUnstagedResult, var deletedStagedResult,
      var stagedResult, var unstagedResult) async {
    // TODO: Possibility of using 'git status --short' over running each command for optimization.
    // Refer to Renzix' comment.

    _currentData = [];
    _currentDataAndDeleted = [];
    _currentDataStaged = [];
    _currentDataUnstaged = [];
    _currentDeleted = [];

    List i = Directory("$_location$_current").listSync(
      recursive: false,
      followLinks: false,
    );

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

    await deletedUnstagedResult.stdout
        .transform(utf8.decoder)
        .forEach((String out) => {
              _currentDeleted = const LineSplitter().convert(out),
            });

    await deletedStagedResult.stdout
        .transform(utf8.decoder)
        .forEach((String out) => {
              _currentDeleted.addAll(const LineSplitter().convert(out)),
            });

    await stagedResult.stdout.transform(utf8.decoder).forEach((String out) => {
          _currentDataStaged = const LineSplitter().convert(out),
          // DONE: Include deleted files when staged.
        });

    await unstagedResult.stdout
        .transform(utf8.decoder)
        .forEach((String out) => {
              _currentDataUnstaged = const LineSplitter().convert(out),
            });

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

    var filesOnly = List.from(_currentDataStaged);

    for (var i = 0; i < _currentDataStaged.length; i++) {
      var j = _currentDataStaged[i].split("/");
      var k = "";

      while (j.length != 1) {
        j.remove(j.last);

        for (var l = 0; l < j.length; l++) {
          if (l == 0) {
            k = j[l];
          } else {
            var m = j[l];
            k = "$k/$m";
          }
        }

        _currentDataStaged.add(k);
      }
    }

    for (var i = 0; i < _currentDataUnstaged.length; i++) {
      var j = _currentDataUnstaged[i].split("/");
      var k = "";

      while (j.length != 1) {
        j.remove(j.last);

        for (var l = 0; l < j.length; l++) {
          if (l == 0) {
            k = j[l];
          } else {
            var m = j[l];
            k = "$k/$m";
          }
        }

        _currentDataUnstaged.add(k);
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
    setState(() {
      _currentDataAndDeleted.sort();
    });

    _currentDataStagedFilesOnly = filesOnly;
  }

  Future<void> _refresh() async {
    var deletedUnstagedResult = await Process.start(
        "git", ["ls-files", "--deleted"],
        workingDirectory: _location);

    var deletedStagedResult = await Process.start(
        "git", ["diff", "--name-only", "--cached", "--diff-filter=D"],
        workingDirectory: _location);

    var stagedResult = await Process.start(
        "git", ["diff", "--name-only", "--staged"],
        workingDirectory: _location);

    var unstagedResult = await Process.start(
        "git", ["ls-files", "--exclude-standard", "--others", "-m"],
        workingDirectory: _location);

    _currentUpdate(deletedUnstagedResult, deletedStagedResult, stagedResult,
        unstagedResult);
  }

  Future<void> _cloneRepository(
      String repositoryToClone, String locationToCloneTo) async {
    await Process.run("git", ["clone", repositoryToClone],
        workingDirectory: locationToCloneTo);

    var i = repositoryToClone.split("/").last;
    var j = locationToCloneTo;

    _location = "$j/$i";
    _current = '';

    _refresh();
  }

  void _newRepository(String result) async {
    await Process.run("git", ["init"], workingDirectory: result);

    _location = result;
    _current = '';
    _refresh();
  }

  void _newCommit(String commitMessage) async {
    await Process.run("git", ["commit", "-m", commitMessage],
        workingDirectory: _location);

    _refresh();
  }

  void _revertCommit(String revertCommit, String revertMessage) async {
    await Process.run("git", ["revert", "--no-commit", revertCommit],
        workingDirectory: _location);

    await Process.run("git", ["commit", "-m", revertMessage],
        workingDirectory: _location);

    _refresh();
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
          child: PopupMenuButton<int>(
            padding: const EdgeInsets.all(0.0),
            icon: const Icon(
              Icons.add,
              size: 24.0,
            ),
            tooltip: "Load",
            itemBuilder: (context) => [
              PopupMenuItem<int>(
                child: const Text("Clone Repository"),
                onTap: () async {
                  Future.delayed(
                      const Duration(seconds: 0),
                      () => showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return cloneRepositoryDialog(
                                context, _cloneRepository);
                          }));
                },
              ),
              PopupMenuItem<int>(
                child: const Text("Open Directory"),
                onTap: () async {
                  String? result = await FilePicker.platform.getDirectoryPath();
                  if (result != 'null') {
                    bool resultExists = await Directory(result!).exists();
                    bool resultIsGit = await Directory("$result/.git").exists();
                    if (resultExists) {
                      if (resultIsGit) {
                        _location = result;
                        _current = '';

                        await _refresh();
                      } else {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return newRepoDialog(
                                  context, _newRepository, result);
                            });
                      }
                    }
                  }
                },
              ),
              const PopupMenuDivider(),
              PopupMenuItem<int>(
                onTap: () {
                  setState(() {
                    _location = "null";
                  });
                },
                enabled: _location != "null",
                child: const Text("Close Repository"),
              ),
            ],
          ),
        ),
        actions: [
          Visibility(
            visible: _location != "null",
            child: Padding(
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
                    enabled: _currentDataStaged.isNotEmpty,
                    child: const Text("New Commit"),
                    onTap: () {
                      String commitChanges = _currentDataStagedFilesOnly
                          .join("\n")
                          .replaceAll(_location, "");

                      Future.delayed(
                          const Duration(seconds: 0),
                          () => showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return newCommitDialog(
                                    context, _newCommit, commitChanges);
                              }));
                    },
                  ),
                  PopupMenuItem<int>(
                    child: const Text("Revert Commit"),
                    onTap: () {
                      Future.delayed(
                          const Duration(seconds: 0),
                          () => showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return revertCommitDialog(
                                    context, _revertCommit);
                              }));
                    },
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<int>(
                    child: const Text("Pull Commits"),
                    onTap: () async {
                      late BuildContext loadingContext;
                      Future.delayed(
                          const Duration(seconds: 0),
                          () => showDialog(
                              barrierDismissible: false,
                              context: context,
                              builder: (BuildContext context) {
                                loadingContext = context;
                                return const Center(
                                    child: CircularProgressIndicator());
                              }));

                      await Process.run("git", ["pull"],
                          workingDirectory: _location);
                      await _refresh();

                      Navigator.of(loadingContext).pop();
                    },
                  ),
                  PopupMenuItem<int>(
                    child: const Text("Push Commits"),
                    onTap: () async {
                      late BuildContext loadingContext;
                      Future.delayed(
                          const Duration(seconds: 0),
                          () => showDialog(
                              barrierDismissible: false,
                              context: context,
                              builder: (BuildContext context) {
                                loadingContext = context;
                                return const Center(
                                    child: CircularProgressIndicator());
                              }));

                      await Process.run("git", ["push"],
                          workingDirectory: _location);
                      // Unneeded to refresh since nothing is affected locally.

                      Navigator.of(loadingContext).pop();
                    },
                  ),
                  PopupMenuItem<int>(
                    child: const Text("Refresh"),
                    onTap: () {
                      _refresh();
                    },
                  ),
                  /*const PopupMenuDivider(),
                PopupMenuItem<int>(
                  child: const Text("Preferences"),
                  onTap: () {},
                ),*/
                ],
              ),
            ),
          ),
          Visibility(
            visible: _location != "null",
            child: Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: IconButton(
                padding: const EdgeInsets.all(0.0),
                icon: const Icon(
                  Icons.history,
                  size: 24.0,
                ),
                tooltip: "Commit History",
                onPressed: () async {
                  setState(() {
                    _sidebarContentState = "history";
                  });
                  _key.currentState!.openEndDrawer();
                },
              ),
            ),
          ),
          Visibility(
            visible: _location != "null",
            child: Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: IconButton(
                padding: const EdgeInsets.all(0.0),
                icon: const Icon(
                  Icons.account_tree_outlined,
                  size: 24.0,
                ),
                tooltip: "Branches",
                onPressed: () async {
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

                  setState(() {
                    _sidebarContentState = "branches";
                  });
                  _key.currentState!.openEndDrawer();
                  // DONE: Show the branch list on click.
                },
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey,
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  if (_location != "null")
                    BoxShadow(
                      blurRadius: 5,
                      color: Colors.black.withOpacity(.4),
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Column(children: [
                  if (_location != 'null') ...[
                    if (_currentDataAndDeleted.isNotEmpty) ...[
                      for (var i = 0;
                          i < _currentDataAndDeleted.length;
                          i++) ...[
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
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
                                        padding:
                                            const EdgeInsets.only(right: 8.0),
                                        child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: IconButton(
                                              padding:
                                                  const EdgeInsets.all(0.0),
                                              icon: Icon(stagingIcon(i),
                                                  color: stagingIconColor(i),
                                                  size: 16.0),
                                              onPressed: !_currentDataStaged
                                                          .contains(
                                                              _currentDataAndDeleted[
                                                                  i]) &&
                                                      !_currentDataUnstaged
                                                          .contains(
                                                              _currentDataAndDeleted[
                                                                  i])
                                                  ? null
                                                  : () async {
                                                      if (_currentDataUnstaged
                                                              .contains(
                                                                  _currentDataAndDeleted[
                                                                      i]) ||
                                                          (_currentDataStaged
                                                                  .contains(
                                                                      _currentDataAndDeleted[
                                                                          i]) &&
                                                              _currentDataUnstaged
                                                                  .contains(
                                                                      _currentDataAndDeleted[
                                                                          i]))) {
                                                        await Process.run(
                                                            "git",
                                                            [
                                                              "add",
                                                              _currentDataAndDeleted[
                                                                      i]
                                                                  .replaceAll(
                                                                      "$_location/",
                                                                      "")
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
                                                              _currentDataAndDeleted[
                                                                      i]
                                                                  .replaceAll(
                                                                      "$_location/",
                                                                      "")
                                                            ],
                                                            workingDirectory:
                                                                _location);
                                                      }

                                                      _refresh();
                                                    },
                                            )),
                                      ),
                                      // FIXME: Refuses on certain directories.
                                      GestureDetector(
                                        onTap: () async {
                                          if (await Directory(_currentData[i])
                                              .exists()) {
                                            Directory(_currentData[i])
                                                .listSync();

                                            _current = _currentData[i]
                                                .replaceAll(_location, "");

                                            if (_current.split("/").last ==
                                                "..") {
                                              _current = _current.substring(
                                                  0, _current.length - 3);
                                              _current = _current.replaceAll(
                                                  _current.split("/").last, "");
                                              _current = _current.substring(
                                                  0, _current.length - 1);
                                            }

                                            _refresh();
                                          }
                                        },
                                        child: Text(
                                          _currentDataAndDeleted[i]
                                              .split("/")
                                              .last,
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
                                        padding:
                                            const EdgeInsets.only(right: 8.0),
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
                                                          .replaceAll(
                                                              "$_location/", "")
                                                    ],
                                                    workingDirectory:
                                                        _location);
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
                                                          .replaceAll(
                                                              "$_location/", "")
                                                    ],
                                                    workingDirectory:
                                                        _location);
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
                                                          .replaceAll(
                                                              "$_location/", "")
                                                    ],
                                                    workingDirectory:
                                                        _location);
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
                        if (i != _currentDataAndDeleted.length - 1)
                          Container(
                            // (Bottom border for decorations sake...)
                            height: 1.25,
                            decoration: const BoxDecoration(color: Colors.grey),
                          ),
                      ],
                    ] else ...[
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Flexible(
                          child: Text(
                              "The repository is empty, time to start your journey!",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                    ],
                  ] else ...[
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text("LOGO HERE",
                          style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(
                      width: 300,
                      child: Flexible(
                        child: Text(
                            "Welcome! Load or create a Git repository by clicking the + button.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ]),
              ),
            ),
          ),
        ),
      ),
      endDrawer: Sidebar(_sidebarContentState, _branches, _location),
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

// Import required built in libraries.
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

// Import required external libraries.
import 'package:file_picker/file_picker.dart'; // File picker.
import 'package:flutter_svg/flutter_svg.dart';

// Import the created scripts.
import 'package:gitbang/config.dart'; // Includes configuration options.
import 'package:gitbang/dialogs/clone_repository.dart'; // Dialog for cloning repositories.
import 'package:gitbang/dialogs/edit_gitignore.dart'; // Dialog for cloning repositories.
import 'package:gitbang/dialogs/edit_submodules.dart'; // Dialog for cloning repositories.
import 'package:gitbang/dialogs/error.dart'; // Dialog for error messages.
import 'package:gitbang/dialogs/new_repository.dart'; // Dialog for initializing a new repository.
import 'package:gitbang/dialogs/new_commit.dart'; // Dialog for new commits.
import 'package:gitbang/dialogs/revert_commit.dart'; // Dialog to revert commits.
import 'package:gitbang/sidebar.dart'; // The history and branch sidebar.

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: Config.theme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      title: 'GitBang',
      home: const Main(),
    );
  }
}

class _MainState extends State<Main> {
  String _location = 'null'; // Root location of the opened repository.

  late String _current = ''; // Current location being viewed in the repository.
  late List _currentData; // The data coming from the current location.
  late List _currentDataAndDeleted; // Likewise including deleted cached data.
  bool _currentShowBar = false;

  List _currentDataStaged = []; // Staged data.
  late List _currentDataStagedFilesOnly; // Likewise but filtered to only include existing.
  List _currentDataUnstaged = []; // Unstaged data.
  List _currentDeleted = []; // Deleted cached data.

  List _branches = []; // List of available branches.

  String _sidebarContentState = ""; // The state of the sidebar ("branches", or "history").

  // The void designed to update and internally refresh all of the current data.
  void _currentUpdate(
    var deletedUnstagedResult, var deletedStagedResult,
    var stagedResult, var unstagedResult
  ) async {
    // TODO: Possibility of using 'git status --short' over running each command for optimization.
    // Refer to Renzix' comment.

    // Reset current data.
    _currentData = [];
    _currentDataAndDeleted = [];
    _currentDataStaged = [];
    _currentDataUnstaged = [];
    _currentDeleted = [];

    // List data from directory.
    List i = Directory("$_location$_current").listSync(
      recursive: false,
      followLinks: false,
    );

    // Convert to parsable string.
    for (var j = 0; j < i.length; j++) {
      _currentData.add(i[j].toString());
      _currentData[j] = _currentData[j].replaceAll("File: '", "").replaceAll("Directory: '", "");
      _currentData[j] = _currentData[j].substring(0, _currentData[j].length - 1);
    }

    // Filter out internal Git repository configuration.
    _currentData.remove("$_location$_current/.git");
    if (_current != "") {
      _currentData.insert(0, "$_location$_current/..");
    }

    _currentData.sort(); // Sort data.

    // Await the rest of the data to be received.
    await deletedUnstagedResult.stdout.transform(utf8.decoder).forEach((String out) => {
          _currentDeleted = const LineSplitter().convert(out),
        });
    await deletedStagedResult.stdout.transform(utf8.decoder).forEach((String out) => {
          _currentDeleted.addAll(const LineSplitter().convert(out)),
        });
    await stagedResult.stdout.transform(utf8.decoder).forEach((String out) => {
          _currentDataStaged = const LineSplitter().convert(out),
        });
    await unstagedResult.stdout.transform(utf8.decoder).forEach((String out) => {
          _currentDataUnstaged = const LineSplitter().convert(out),
        });

    // Extend deleted data to include repository root, and filter based on position.
    for (var i = _currentDeleted.length - 1; i >= 0; i--) {
      var j = _current; // A version of _current that doesn't start with /.
      if (j.startsWith("/")) {
        j = j.replaceFirst("/", "");
      }

      bool m = false;
      for (var k = 0; k < _currentData.length; k++) {
        // If the current directory may include it.
        if (_currentDeleted[i].startsWith(_currentData[k].replaceAll("$_location$_current/", ""))) {
          m = true;
          break;
        }
      }

      bool n = true;
      if (j != "") {
        n = _currentDeleted[i] == "$j/${_currentDeleted[i].split("/").last}";
      }

      if (n && !m) {
        // If the current directory has been confirmed to include the item.
        var l = _currentDeleted[i];
        _currentDeleted[i] = "$_location/$l";
      } else {
        _currentDeleted.removeAt(i);
      }
    }

    // If the current directory is the root, then hide the current bar.
    if (_current.trim() == "") {
      _currentShowBar = false;
    } else {
      _currentShowBar = true;
    }
    
    // To filter, make the variable equivalent from an early point.
    var filesOnly = List.from(_currentDataStaged);

    // Filter out and bring together staged and unstaged data.
    for (var i = 0; i < _currentDataStaged.length; i++) {
      var j = _currentDataStaged[i].split("/");
      var k = "";

      while (j.length != 1) {
        j.remove(j.last);

        for (var l = 0; l < j.length; l++) {
          if (l == 0) {
            // Dialog for error messages.
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

    // Extend the staged + unstaged data to include the repository root.
    for (var i = 0; i < _currentDataStaged.length; i++) {
      var l = _currentDataStaged[i];
      _currentDataStaged[i] = "$_location/$l";
    }
    for (var i = 0; i < _currentDataUnstaged.length; i++) {
      var l = _currentDataUnstaged[i];
      _currentDataUnstaged[i] = "$_location/$l";
    }

    // Bring together the existing and deleted data.
    _currentDataAndDeleted = List.from(_currentData)..addAll(_currentDeleted);
    setState(() {
      // Also update the state.
      _currentDataAndDeleted.sort();
    });

    // Apply the earlier filter to the current.
    _currentDataStagedFilesOnly = filesOnly;
  }

  // Quick refresh void that executes all data commands.
  Future<void> _refresh() async {
    try {
      var deletedUnstagedResult = await Process.start(
        "git", ["ls-files", "--deleted"], workingDirectory: _location);
      var deletedStagedResult = await Process.start(
        "git", ["diff", "--name-only", "--cached", "--diff-filter=D"], workingDirectory: _location);
      var stagedResult = await Process.start(
        "git", ["diff", "--name-only", "--staged"], workingDirectory: _location);
      var unstagedResult = await Process.start(
        "git", ["ls-files", "--exclude-standard", "--others", "-m"], workingDirectory: _location);

      _currentUpdate(deletedUnstagedResult, deletedStagedResult, stagedResult, unstagedResult);
    } catch (e) {
      Future.delayed(
          const Duration(seconds: 0),
          () => showDialog(
              context: context,
              builder: (BuildContext context) {
                return errorMessageDialog(context, "Failed to refresh repository contents.");
              }));
    }
  }

  // Void to clone a repository. Hooks into dialog.
  Future<void> _cloneRepository(
    String repositoryToClone, String locationToCloneTo, bool cloneRecursively
  ) async {
    late List<String> commandToRun;

    if (cloneRecursively) {
      commandToRun = ["clone", "--recursive", repositoryToClone];
    } else {
      commandToRun = ["clone", repositoryToClone];
    }

    await Process.run("git", commandToRun, workingDirectory: locationToCloneTo);

    var i = repositoryToClone.split("/").last;
    var j = locationToCloneTo;

    _location = "$j/$i";
    _current = '';

    _refresh();
  }

  // Void to initialize a new repository. Hooks into dialog.
  void _newRepository(String result) async {
    await Process.run("git", ["init"], workingDirectory: result);

    _location = result;
    _current = '';
    _refresh();
  }

  // Void to create a new commit. Hooks into dialog and repository data.
  void _newCommit(String commitMessage) async {
    await Process.run("git", ["commit", "-m", commitMessage], workingDirectory: _location);

    _refresh();
  }

  // Void to revert an existing commit. Hooks into dialog.
  void _revertCommit(String revertCommit, String revertMessage) async {
    await Process.run("git", ["revert", "--no-commit", revertCommit], workingDirectory: _location);
    await Process.run("git", ["commit", "-m", revertMessage], workingDirectory: _location);

    _refresh();
  }

  final GlobalKey<ScaffoldState> _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    // Returns a normal or deleted color.
    Color? deletedColor(var item) {
      if (_currentDeleted.contains(_currentDataAndDeleted[item])) {
        return Config.grayedForegroundColor;
      } else {
        return Config.foregroundColor;
      }
    }

    // Returns an icon for staging for each item.
    IconData stagingIcon(var item) {
      if (
        _currentDataStaged.contains(_currentDataAndDeleted[item]) &&
        _currentDataUnstaged.contains(_currentDataAndDeleted[item])
      ) {
        return Icons.swap_vert_circle; // build_circle, change_circle, playlist_add_circle, swap_horiz_circle, swap_vert_circle
      } else if (_currentDataStaged.contains(_currentDataAndDeleted[item])) {
        return Icons.add_circle;
      } else if (_currentDataUnstaged.contains(_currentDataAndDeleted[item])) {
        return Icons.remove_circle;
      } else {
        return Icons.circle_outlined;
      }
    }

    // Returns a color for the icon function above.
    Color stagingIconColor(int item) {
      if (
        _currentDataStaged.contains(_currentDataAndDeleted[item]) &&
        _currentDataUnstaged.contains(_currentDataAndDeleted[item])
      ) {
        return Config.stateColors[2]; // Partially staged color, refer to config.dart.
      } else if (_currentDataStaged.contains(_currentDataAndDeleted[item])) {
        return Config.stateColors[1]; // Staged color. ^
      } else if (_currentDataUnstaged.contains(_currentDataAndDeleted[item])) {
        return Config.stateColors[0]; // Unstaged color. ^
      } else {
        return Config.foregroundColor;
      }
    }

    // Returns the name of the type of item.
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(40),
        child: AppBar(
          // The top bar.
          title: SelectableText(
            _location.split("/").last,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w400)),
          titleSpacing: 0,
          // Includes the name of the project.
          leading: SizedBox(
            width: 20,
            height: 20,
            /* Context menu below gives options for cloning,
          * initializing, or closing repository. */
            child: PopupMenuButton<int>(
              padding: const EdgeInsets.all(0),
              icon: const Icon(
                Icons.add,
                size: 20.0,
              ),
              tooltip: "Load",
              itemBuilder: (context) => [
                PopupMenuItem<int>(
                  height: 32,
                  onTap: () async {
                    Future.delayed(
                        const Duration(seconds: 0),
                        () => showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return cloneRepositoryDialog(context, _cloneRepository);
                            }));
                  },
                  child: const Text("Clone Repository"),
                ),
                PopupMenuItem<int>(
                  height: 32,
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
                                return newRepoDialog(context, _newRepository, result);
                              });
                        }
                      }
                    }
                  },
                  child: const Text("Open Directory"),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<int>(
                  height: 32,
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
            /* Below gives actions for GitBang to handle, including
          * new commits, reverting a commit, pulling and pushing
          * commits, as well as simply refreshing manually. */
            Visibility(
              visible: _location != "null",
              child: Padding(
                padding: const EdgeInsets.only(right: 18),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: PopupMenuButton<int>(
                    padding: const EdgeInsets.all(0),
                    icon: const Icon(
                      Icons.more_horiz,
                      size: 20.0,
                    ),
                    tooltip: "Options",
                    itemBuilder: (context) => [
                      PopupMenuItem<int>(
                        height: 32,
                        enabled: _currentDataStaged.isNotEmpty,
                        child: const Text("New Commit"),
                        onTap: () {
                          String commitChanges =
                            _currentDataStagedFilesOnly.join("\n").replaceAll(_location, "");

                          Future.delayed(
                              const Duration(seconds: 0),
                              () => showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return newCommitDialog(context, _newCommit, commitChanges);
                                  }));
                        },
                      ),
                      PopupMenuItem<int>(
                        height: 32,
                        child: const Text("Revert Commit"),
                        onTap: () {
                          Future.delayed(
                              const Duration(seconds: 0),
                              () => showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return revertCommitDialog(context, _revertCommit);
                                  }));
                        },
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem<int>(
                        height: 32,
                        child: const Text("Pull Commits"),
                        onTap: () async {
                          late BuildContext loadingContext;

                          void pop() {
                            Navigator.of(loadingContext).pop();
                          }

                          void work() async {
                            Future.delayed(
                                const Duration(seconds: 0),
                                () => showDialog(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (BuildContext context) {
                                      loadingContext = context;
                                      return const Center(child: CircularProgressIndicator());
                                    }));

                            try {
                              await Process.run("git", ["pull"], workingDirectory: _location);
                            } catch (e) {
                              Future.delayed(
                                  const Duration(seconds: 0),
                                  () => showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return errorMessageDialog(context,
                                          "Could not pull new commits from repository.");
                                      }));
                            }
                            await _refresh();
                            pop();
                          }

                          work();
                        },
                      ),
                      PopupMenuItem<int>(
                        height: 32,
                        child: const Text("Push Commits"),
                        onTap: () {
                          late BuildContext loadingContext;

                          void pop() {
                            Navigator.of(loadingContext).pop();
                          }

                          void work() async {
                            Future.delayed(
                                const Duration(seconds: 0),
                                () => showDialog(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (BuildContext context) {
                                      loadingContext = context;
                                      return const Center(child: CircularProgressIndicator());
                                    }));

                            try {
                              await Process.run("git", ["push"], workingDirectory: _location);
                            } catch (e) {
                              Future.delayed(
                                  const Duration(seconds: 0),
                                  () => showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return errorMessageDialog(context,
                                          "Could not push local commits to repository.");
                                      }));
                            }

                            await _refresh();
                            pop();
                          }

                          work();
                        },
                      ),
                      PopupMenuItem<int>(
                        height: 32,
                        child: const Text("Refresh"),
                        onTap: () {
                          _refresh();
                        },
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem<int>(
                        height: 32,
                        child: const Text("Edit Gitignore"),
                        onTap: () {
                          Future.delayed(
                              const Duration(seconds: 0),
                              () => showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return EditGitignoreDialog(_location, _current, _refresh);
                                  }));
                        },
                      ),
                      PopupMenuItem<int>(
                        height: 32,
                        child: const Text("Edit Submodules"),
                        onTap: () {
                          Future.delayed(
                              const Duration(seconds: 0),
                              () => showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return EditSubmodulesDialog(_location, _current, _refresh);
                                  }));
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
            ),
            // Below launches the sidebar with the commit history state.
            Visibility(
              visible: _location != "null",
              child: Padding(
                padding: const EdgeInsets.only(right: 18),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: IconButton(
                    padding: const EdgeInsets.all(0),
                    icon: const Icon(
                      Icons.history,
                      size: 20.0,
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
            ),
            Visibility(
              visible: _location != "null",
              child: Padding(
                padding: const EdgeInsets.only(right: 18),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: IconButton(
                    padding: const EdgeInsets.all(0),
                    icon: const Icon(
                      Icons.move_to_inbox_sharp,
                      size: 20.0,
                    ),
                    tooltip: "View Stash",
                    onPressed: () async {
                      setState(() {
                        _sidebarContentState = "stash";
                      });
                      _key.currentState!.openEndDrawer();
                    },
                  ),
                ),
              ),
            ),
            // Below launches the sidebar with the branches view state.
            Visibility(
              visible: _location != "null",
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: IconButton(
                    padding: const EdgeInsets.all(0),
                    icon: const Icon(
                      Icons.account_tree_sharp,
                      size: 20,
                    ),
                    tooltip: "Branches",
                    onPressed: () async {
                      _branches = [];

                      var branchResult = await Process.start(
                        "git", ["branch", "-a"], workingDirectory: _location);

                      await branchResult.stdout.transform(utf8.decoder).forEach((String out) => {
                            setState(() {
                              _branches = const LineSplitter().convert(out);
                              _branches.sort();
                            }),
                          });

                      setState(() {
                        _sidebarContentState = "branches";
                      });
                      _key.currentState!.openEndDrawer();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Visibility(
        visible: _currentShowBar,
        child: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: BottomAppBar(
            color: Theme.of(context).primaryColor,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                height: 30,
                child: Padding(
                  padding: EdgeInsets.only(left: 8, right: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        child: Text(_location.split("/").last,
                          style: Theme.of(context).textTheme.bodyText1),
                        /*child: Icon(Icons.my_location,
                          color: Config.foregroundColor,
                          size: 20),*/
                        onTap: () {
                          setState(() {
                              _current = "";
                              _refresh();
                          });
                        },
                      ),
                      if (_current.split("/").length != 1)
                      Icon(Icons.chevron_right,
                        color: Config.foregroundColor, size: 16),
                      for (int i = 0; i < _current.split("/").length; i++) ...[
                        if (i != 0) ...[
                          GestureDetector(
                            child: Text(_current.split("/")[i],
                              style: Theme.of(context).textTheme.bodyText1),
                            onTap: () {
                              var newCurrent = "";
                              for (int j = 0; j < _current.split("/").length; j++) {
                                if (j <= i && _current.split("/")[j].trim() != "") {
                                  newCurrent = "$newCurrent/${_current.split('/')[j]}";
                                }
                              }
                              //print(newCurrent);
                              _current = newCurrent;
                              _refresh();
                            }
                          ),
                          if (i != _current.split("/").length-1)
                          Icon(Icons.chevron_right,
                            color: Config.foregroundColor, size: 16),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      backgroundColor: Theme.of(context).backgroundColor,
      body: Align(
        alignment: _location != "null" && _currentDataAndDeleted.isNotEmpty ?
          Alignment.topCenter : Alignment.center,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              // Contains the foundation for the list of items.
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  if (_location != "null" && _currentDataAndDeleted.isNotEmpty)
                    BoxShadow(
                      blurRadius: 5,
                      color: const Color.fromARGB(255, 0, 0, 0).withOpacity(.4),
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_location != 'null') ...[
                        // Checking if a project is open,
                        if (_currentDataAndDeleted.isNotEmpty) ...[
                          // and if there are existing items in the repository.
                          for (var i = 0; i < _currentDataAndDeleted.length; i++) ...[
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                              ),
                              padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
                              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Flexible(
                                  child: Row(
                                    /*crossAxisAlignment:
                                        CrossAxisAlignment.start,*/
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        // Below has the item icon for staging status.
                                        child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: IconButton(
                                              padding: const EdgeInsets.all(0.0),
                                              icon: Icon(stagingIcon(i), color: stagingIconColor(i), size: 16.0),
                                              onPressed:
                                                !_currentDataStaged.contains(_currentDataAndDeleted[i]) &&
                                                !_currentDataUnstaged.contains(_currentDataAndDeleted[i])
                                                  ? null
                                                  : () async {
                                                      if (_currentDataUnstaged.contains(_currentDataAndDeleted[i]) ||
                                                         (_currentDataStaged.contains(_currentDataAndDeleted[i]) &&
                                                          _currentDataUnstaged.contains(_currentDataAndDeleted[i]))) {
                                                        try {
                                                          await Process.run("git", ["add", _currentDataAndDeleted[i].replaceAll(
                                                                "$_location/", "")], workingDirectory: _location);
                                                        } catch (e) {
                                                          Future.delayed(
                                                              const Duration(seconds: 0),
                                                              () => showDialog(
                                                                  context: context,
                                                                  builder: (BuildContext context) {
                                                                    return errorMessageDialog(context,
                                                                      "Error staging file.");
                                                                  }));
                                                        }
                                                      } else if (_currentDataStaged.contains(_currentDataAndDeleted[i])) {
                                                        try {
                                                          await Process.run("git", ["reset", "--",
                                                              _currentDataAndDeleted[i].replaceAll("$_location/", "")],
                                                            workingDirectory: _location);
                                                        } catch (e) {
                                                          Future.delayed(
                                                              const Duration(seconds: 0),
                                                              () => showDialog(
                                                                  context: context,
                                                                  builder: (BuildContext context) {
                                                                    return errorMessageDialog(context,
                                                                      "Error unstaging file.");
                                                                  }));
                                                        }
                                                      }

                                                      _refresh();
                                                    },
                                            )),
                                      ),
                                      // Below is the name of the item.
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () async {
                                            if (await Directory(_currentDataAndDeleted[i]).exists()) {
                                              try {
                                                Directory(_currentDataAndDeleted[i]).listSync();

                                                _current = _currentDataAndDeleted[i].replaceAll(_location, "");

                                                if (_current.split("/").last == "..") {
                                                  _current = _current.substring(0, _current.length - 3);
                                                  _current = _current.replaceAll(_current.split("/").last, "");
                                                  _current = _current.substring(0, _current.length - 1);
                                                }
                                              } catch (e) {
                                                Future.delayed(
                                                    const Duration(seconds: 0),
                                                    () => showDialog(
                                                        context: context,
                                                        builder: (BuildContext context) {
                                                          return errorMessageDialog(context,
                                                            "Could not jump to directory.");
                                                        }));
                                              }
                                              _refresh();
                                            }
                                          },
                                          child: Row(
                                            children: [
                                              Text(
                                                _currentDataAndDeleted[i].replaceAll("$_location$_current", "").substring(1),
                                                maxLines: 1,
                                                overflow: TextOverflow.fade,
                                                softWrap: false,
                                                textAlign: TextAlign.left,
                                                style: Theme.of(context).textTheme.bodyText1?.apply(color: deletedColor(i)),
                                              ),
                                              if (_currentDataAndDeleted[i]
                                                .replaceAll("$_location$_current", "").substring(1) == "..")
                                              ...[
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 4),
                                                  child: Icon(Icons.keyboard_double_arrow_left,
                                                    color: Config.foregroundColor, size: 16),
                                                ),
                                              ] else if (typeName(i) == "Directory") ...[
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 4),
                                                  child: Icon(Icons.keyboard_double_arrow_right,
                                                    color: Config.foregroundColor, size: 16),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  //crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Below is a text box that shows the item type.
                                    Padding(
                                        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                                        child: Text(
                                          typeName(i),
                                          style: Theme.of(context).textTheme.bodyText1,
                                        )),
                                    /* Below includes a context menu that allows you
                                  * to manually stage, unstage, or restore an item.*/
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: TooltipVisibility(
                                        visible: false,
                                        child: PopupMenuButton<int>(
                                          padding: const EdgeInsets.all(0.0),
                                          icon: Icon(
                                            Icons.more_vert,
                                            size: 16.0,
                                            color: Config.foregroundColor,
                                          ),
                                          itemBuilder: (context) => [
                                            PopupMenuItem<int>(
                                              height: 32,
                                              child: const Text("Stage"),
                                              onTap: () async {
                                                try {
                                                  await Process.run("git", ["add",
                                                      _currentDataAndDeleted[i].replaceAll("$_location/", "")],
                                                    workingDirectory: _location);
                                                } catch (e) {
                                                  Future.delayed(
                                                      const Duration(seconds: 0),
                                                      () => showDialog(
                                                          context: context,
                                                          builder: (BuildContext context) {
                                                            return errorMessageDialog(context, "Error staging file.");
                                                          }));
                                                }
                                                _refresh();
                                              },
                                            ),
                                            PopupMenuItem<int>(
                                              height: 32,
                                              child: const Text("Unstage"),
                                              onTap: () async {
                                                try {
                                                  await Process.run("git", ["reset", "--",
                                                      _currentDataAndDeleted[i].replaceAll("$_location/", "")],
                                                    workingDirectory: _location);
                                                  _refresh();
                                                } catch (e) {
                                                  Future.delayed(
                                                      const Duration(seconds: 0),
                                                      () => showDialog(
                                                          context: context,
                                                          builder: (BuildContext context) {
                                                            return errorMessageDialog(context, "Error unstaging file.");
                                                          }));
                                                }
                                              },
                                            ),
                                            const PopupMenuDivider(),
                                            PopupMenuItem<int>(
                                              height: 32,
                                              child: const Text("Restore"),
                                              onTap: () async {
                                                try {
                                                  await Process.run("git", ["checkout", "HEAD",
                                                      _currentDataAndDeleted[i].replaceAll("$_location/", "")],
                                                    workingDirectory: _location);
                                                } catch (e) {
                                                  Future.delayed(
                                                      const Duration(seconds: 0),
                                                      () => showDialog(
                                                          context: context,
                                                          builder: (BuildContext context) {
                                                            return errorMessageDialog(context, "Error restoring file.");
                                                          }));
                                                }

                                                _refresh();
                                              },
                                            ),
                                          ],
                                          tooltip: null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ]),
                            ),
                            // Quick separator for the items.
                            if (i != _currentDataAndDeleted.length - 1)
                              Container(
                                // (Bottom border for decorations sake...)
                                height: 1.25,
                                decoration: BoxDecoration(color: Config.grayedForegroundColor),
                              ),
                          ],
                        ] else ...[
                          Padding(
                            // Text box in case the repository has no items.
                            padding: const EdgeInsets.all(16),
                            child: Text("The repository is empty, time to start your journey!",
                              textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyText1),
                          ),
                        ],
                      ] else ...[
                        // Start page in case a repository isn't loaded.
                        Padding(
                          padding: const EdgeInsets.only(bottom: 32, left: 16, right: 16),
                          child: SizedBox(
                            width: 240,
                            height: 130,
                            child: SvgPicture.asset(
                              'svg/gitbanglogo.svg',
                              color: Config.foregroundColor.withOpacity(0.5),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 320,
                          child: Text("Welcome! Load or create a Git repository by clicking the + button.",
                            textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyText1),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      endDrawer: Sidebar(_sidebarContentState, _branches, _location, _refresh),
      // Sidebar and all of it's arguments.
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

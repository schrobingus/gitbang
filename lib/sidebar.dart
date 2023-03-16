import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gitbang/config.dart';
import 'package:gitbang/dialogs/error.dart';

class _SidebarState extends State<Sidebar> {
  var _historyPageNumber = 0;
  var _historyPageList = [];
  double _historyEntryAmount = 0;
  var _historyPageAmount = 0;
  bool _showHistory = false;
  bool _historyEmpty = false;

  var _stashList = [];
  bool _stashRefreshed = false;

  Future<void> _refreshHistory() async {
    setState(() {
      _showHistory = false;
    });

    var historyCommand = await Process.start(
      "git", ["log", "--oneline"],
      workingDirectory: widget.targetLocation);
    var historyPageAmountPipe = await Process.start("wc", ["-l"]);
    await historyCommand.stdout.pipe(historyPageAmountPipe.stdin);
    await historyPageAmountPipe.stdout.transform(utf8.decoder)
      .forEach((String out) => setState(() {
          _historyEntryAmount = double.parse(out);
    }));
    setState(() {
      _historyPageAmount = (_historyEntryAmount / 25).ceil();
    });

    if (_historyPageAmount == 0) {
      setState(() {
        _showHistory = true;
        _historyEmpty = true;
      });
    } else {
      double historyPageTailEnsure = 0;
      if (_historyPageNumber == _historyPageAmount - 1 &&
        _historyEntryAmount / 25 != (_historyEntryAmount / 25).ceil()) {
        historyPageTailEnsure = _historyEntryAmount % 25;
      } else {
        historyPageTailEnsure = 25;
      }

      var historyCommandNext = await Process.start("git", ["log", "--oneline",
          "-${((_historyPageNumber + 1) * 25).toString()}"],
        workingDirectory: widget.targetLocation);
      var historyPageTail = await Process.start("tail", ["-n",
          historyPageTailEnsure.toInt().toString()]);
      historyCommandNext.stdout.pipe(historyPageTail.stdin);

      _historyPageList = [];
      late List<String> x;
      await historyPageTail.stdout.transform(utf8.decoder).forEach(
            (String out) => x = const LineSplitter().convert(out),
          );
      for (var i = 0; i < x.length; i++) {
        var j = x[i].split(" ").first;
        _historyPageList.add([j, x[i].replaceAll("$j ", "")]);
      }

      setState(() {
        _historyPageList = _historyPageList;
        _showHistory = true;
      });
    }
  }

  Future<void> _refreshStashList() async {
    setState(() {
      _stashRefreshed = false;
    });

    var stashListEarly = [];

    var stashListProcess = await Process.start("git", ["stash", "list"],
      workingDirectory: widget.targetLocation);

    await stashListProcess.stdout.transform(utf8.decoder).forEach((String out) => {
          setState(() {
            stashListEarly = const LineSplitter().convert(out);
            stashListEarly.sort();
          }),
        });

    _stashList = [];
    for (var i = 0; i < stashListEarly.length; i++) {
      if (stashListEarly[i].trim() != "") {
        _stashList.add([
          stashListEarly[i].split(": ")[0], // Stash ID
          stashListEarly[i].split(": ")[1], // Stash Status
          // Stash Description
          stashListEarly[i]
            .replaceAll("${stashListEarly[i].split(": ")[0]}: ", "")
            .replaceAll("${stashListEarly[i].split(": ")[1]}: ", "")
        ]);
      }
    }

    setState(() {
      _stashRefreshed = true;
    });
  }

  bool _includesLocals(var n) => !(n.substring(2, n.length)
    .split(" -> ").last.startsWith("remotes/"));

  bool _includesRemotes(var n) => (n.substring(2, n.length)
    .split(" -> ").last.startsWith("remotes/"));

  @override
  void initState() {
    super.initState();
    if (widget.sidebarContent == "history") {
      _refreshHistory();
    } else if (widget.sidebarContent == "stash") {
      _refreshStashList();
    }
  }

  @override
  Widget build(BuildContext context) {
    Color selectedColor(String i) {
      if (i[0] == '*') {
        if (i.contains("detached")) {
          return Config.stateColors[4]; // Selected detached color, refer to config.dart.
        } else {
          return Config.stateColors[3]; // Selected color. ^
        }
      } else {
        return Config.foregroundColor;
      }
    }

    return Drawer(
      backgroundColor: Theme.of(context).backgroundColor,
      child: SingleChildScrollView(
        child: Column(children: [
            if (widget.sidebarContent == "branches") ...[
              Padding(
                padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Local", style: Theme.of(context).textTheme.bodyText1),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        child: Text("+ Make New", style: Theme.of(context).textTheme.bodyText1),
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
                                    style: Config.theme.textTheme.bodyText1,
                                    controller: branchName,
                                    decoration: Config.inputDecoration.copyWith(
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
                                        
                                        try {
                                          Process.run("git", ["checkout", "-b", branchName.text],
                                            workingDirectory: widget.targetLocation);
                                        } catch (e) {
                                          Future.delayed(
                                            const Duration(seconds: 0),
                                            () => showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return errorMessageDialog(context, "Could not create branch.");
                                          }));
                                        }
                                        setState(() {});
                                      },
                                      child: const Text("Add")),
                                  ],
                                );
                          }));
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.sidebarBranches.any(_includesLocals)) ...[
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 5,
                          color: Colors.black.withOpacity(.4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Column(
                        children: [
                          for (var i = 0; i < widget.sidebarBranches.length; i++) ...[
                            if (!widget.sidebarBranches[i]
                              .substring(2, widget.sidebarBranches[i].length)
                              .split(" -> ").last
                              .startsWith("remotes/"))
                            ...[
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 7.5, bottom: 7.5),
                                  child: Align(
                                    alignment: Alignment.topLeft,
                                    child: GestureDetector(
                                      onTap: () {
                                        void checkoutBranch() async {
                                          try {
                                            await Process.start("git", ["checkout",
                                                widget.sidebarBranches[i]
                                                .substring(2, widget.sidebarBranches[i].length)
                                                .split(" -> ").last],
                                              workingDirectory: widget.targetLocation);
                                          } catch (e) {
                                            var branchName = widget.sidebarBranches[i]
                                            .substring(2, widget.sidebarBranches[i].length).split(" -> ").last;

                                            Future.delayed(
                                              const Duration(seconds: 0),
                                              () => showDialog(
                                                context: context,
                                                builder: (BuildContext context) {
                                                  return errorMessageDialog(context,
                                                    "Could not switch to branch ($branchName).");
                                            }));
                                          }
                                        }

                                        if (!widget.sidebarBranches[i].substring(2, widget.sidebarBranches[i].length)
                                          .startsWith("(")) {
                                          checkoutBranch();
                                        }
                                        Navigator.pop(context);
                                      },
                                      // TODO: Forgot why the values are different for text widgets, check later.
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: Text(
                                          (() {
                                              if (widget.sidebarBranches[i].contains("(")) {
                                                return widget.sidebarBranches[i].substring(2,
                                                  widget.sidebarBranches[i].length - 1).split(" ").last;
                                              } else {
                                                return widget.sidebarBranches[i].substring(2,
                                                  widget.sidebarBranches[i].length).split(" -> ").last;
                                              }
                                            }()),
                                          style: Theme.of(context).textTheme.bodyText1?.apply(color:
                                            selectedColor(widget.sidebarBranches[i])),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (!widget.sidebarBranches[i].substring(2, widget.sidebarBranches[i].length)
                                .split(" -> ").last.startsWith("remotes/") &&
                                widget.sidebarBranches[i] !=
                                widget.sidebarBranches.lastWhere((j) => !j.contains("remotes/"))) ...[
                                Container(
                                  height: 1.25,
                                  decoration: BoxDecoration(color: Config.grayedForegroundColor),
                                ),
                              ],
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text("No local branches found.", style: Theme.of(context).textTheme.bodyText1),
                ),
              ],
              Padding(
                padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 15.0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text("Remote", style:
                    Theme.of(context).textTheme.bodyText1?.apply(color: Config.foregroundColor)),
                ),
              ),
              if (widget.sidebarBranches.any(_includesRemotes)) ...[
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 5,
                          color: Colors.black.withOpacity(.4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Column(
                        children: [
                          for (var i = 0; i < widget.sidebarBranches.length; i++) ...[
                            if (widget.sidebarBranches[i].substring(2, widget.sidebarBranches[i].length)
                              .split(" -> ").last.startsWith("remotes/"))
                            ...[
                              Padding(
                                padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 7.5, bottom: 7.5),
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: GestureDetector(
                                    onTap: () {
                                      void checkoutBranch() async {
                                        try {
                                          await Process.start("git", ["checkout",
                                              widget.sidebarBranches[i].substring(2,
                                                widget.sidebarBranches[i].length).split(" -> ").last],
                                            workingDirectory: widget.targetLocation);
                                        } catch (e) {
                                          var branchName =
                                          widget.sidebarBranches[i].substring(2,
                                            widget.sidebarBranches[i].length).split(" -> ").last;

                                          Future.delayed(
                                            const Duration(seconds: 0),
                                            () => showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return errorMessageDialog(context,
                                                  "Could not switch to branch ($branchName).");
                                          }));
                                        }
                                      }

                                      checkoutBranch();
                                      Navigator.pop(context);
                                    },
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: Text(
                                        widget.sidebarBranches[i].substring(2,
                                          widget.sidebarBranches[i].length).split(" -> ").last,
                                        style: Theme.of(context).textTheme.bodyText1?.apply(
                                          color: selectedColor(widget.sidebarBranches[i])),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (widget.sidebarBranches[i]
                                .substring(2, widget.sidebarBranches[i].length).split(" -> ").last
                                .startsWith("remotes/") &&
                                widget.sidebarBranches[i] !=
                                widget.sidebarBranches.lastWhere((j) => j.contains("remotes/")))
                              ...[
                                Container(
                                  height: 1.25,
                                  decoration: BoxDecoration(color: Config.grayedForegroundColor),
                                ),
                              ],
                            ],
                          ]
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text("No remote branches found.",
                    style: Theme.of(context).textTheme.bodyText1),
                ),
              ],
            ] else if (widget.sidebarContent == "history") ...[
              Column(
                children: [
                  if (_showHistory) ...[
                    if (!_historyEmpty) ...[
                      for (var i = 0; i < _historyPageList.length; i++) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(8.0),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 5,
                                  color: Colors.black.withOpacity(.4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: SelectableText(_historyPageList[i][0],
                                    style: Theme.of(context).textTheme.bodyText1),
                                ),
                                Flexible(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: SelectableText(_historyPageList[i][1],
                                      textAlign: TextAlign.right,
                                      style: Theme.of(context).textTheme.bodyText1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text("No commits found.", style: Theme.of(context).textTheme.bodyText1),
                      ),
                    ],
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Config.foregroundColor,
                    ))),
                  ],
                  if (_historyPageAmount > 1) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 5,
                              color: Colors.black.withOpacity(.4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: IconButton(
                                icon: Icon(Icons.keyboard_double_arrow_left, color: Config.foregroundColor),
                                padding: const EdgeInsets.all(0.0),
                                onPressed: () {
                                  setState(() {
                                      _historyPageNumber = 0;
                                  });
                                  _refreshHistory();
                                },
                              ),
                            ),
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: IconButton(
                                icon: Icon(Icons.keyboard_arrow_left, color: Config.foregroundColor),
                                padding: const EdgeInsets.all(0.0),
                                onPressed: () {
                                  if (_historyPageNumber > 0) {
                                    setState(() {
                                        _historyPageNumber--;
                                    });
                                  }
                                  _refreshHistory();
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                "${_historyPageNumber + 1}/$_historyPageAmount",
                                style: TextStyle(color: Config.foregroundColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: IconButton(
                                icon: Icon(Icons.keyboard_arrow_right, color: Config.foregroundColor),
                                padding: const EdgeInsets.all(0.0),
                                onPressed: () {
                                  if (_historyPageNumber < _historyPageAmount - 1) {
                                    setState(() {
                                        _historyPageNumber++;
                                    });
                                  }

                                  _refreshHistory();
                                },
                              ),
                            ),
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: IconButton(
                                icon: Icon(Icons.keyboard_double_arrow_right, color: Config.foregroundColor),
                                padding: const EdgeInsets.all(0.0),
                                onPressed: () {
                                  setState(() {
                                      _historyPageNumber = _historyPageAmount - 1;
                                  });
                                  _refreshHistory();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ] else if (widget.sidebarContent == "stash") ...[
              if (_stashRefreshed) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Stashes", style: Theme.of(context).textTheme.bodyText1),
                      // TODO: Add a button to refresh the stash entries.
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          child: Text("+ Make New", style: Theme.of(context).textTheme.bodyText1),
                          onTap: () {
                            TextEditingController stashName = TextEditingController();
                            Future.delayed(
                              const Duration(seconds: 0),
                              () => showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text("New Stash"),
                                    content: TextField(
                                      style: Config.theme.textTheme.bodyText1,
                                      controller: stashName,
                                      decoration: Config.inputDecoration.copyWith(
                                        hintText: "Stash Description (optional)",
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text("Cancel")),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();

                                          List<String> stashArgs = ["stash", "save"];
                                          if (stashName.text != "") {
                                            stashArgs.add(stashName.text);
                                          }

                                          Process.run("git", stashArgs, workingDirectory:
                                            widget.targetLocation);

                                          widget.targetRefresh();
                                          _refreshStashList();
                                        },
                                        child: const Text("Apply")),
                                    ],
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _stashList.isNotEmpty ?
                      Theme.of(context).primaryColor : Colors.black.withOpacity(0),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 5,
                          color: _stashList.isNotEmpty ?
                          Colors.black.withOpacity(.4) : Colors.black.withOpacity(0),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Column(
                        children: [
                          if (_stashList.isNotEmpty) ...[
                            for (var i = 0; i < _stashList.length; i++) ...[
                              Padding(
                                padding: const EdgeInsets.only(left: 10, right: 10, top: 7.5, bottom: 7.5),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Flexible(
                                      child: SelectableText.rich(TextSpan(
                                          children: [
                                            TextSpan(text: "${_stashList[i][2]}  ",
                                              style: Theme.of(context).textTheme.bodyText1),
                                            TextSpan(text: _stashList[i][0],
                                              style: Theme.of(context).textTheme.bodyText1?.apply(
                                                color: Config.grayedForegroundColor)),
                                          ],
                                    ))),
                                    Row(
                                      children: [
                                        SelectableText(_stashList[i][1],
                                          style: Theme.of(context).textTheme.bodyText1),
                                        SizedBox(
                                          width: 20,
                                          height: 16,
                                          child: IconButton(
                                            icon: Icon(
                                              Icons.check,
                                              color: Config.foregroundColor,
                                              size: 16,
                                            ),
                                            padding: const EdgeInsets.all(0),
                                            onPressed: () {
                                              Process.run("git", ["stash", "apply", _stashList[i][0]],
                                                workingDirectory: widget.targetLocation);

                                              widget.targetRefresh();
                                            },
                                          ),
                                        ),
                                        SizedBox(
                                          width: 20,
                                          height: 16,
                                          child: IconButton(
                                            icon: Icon(
                                              Icons.close,
                                              color: Config.foregroundColor,
                                              size: 16,
                                            ),
                                            padding: const EdgeInsets.all(0),
                                            onPressed: () {
                                              Process.run("git", ["stash", "drop", _stashList[i][0]],
                                                workingDirectory: widget.targetLocation);

                                              widget.targetRefresh();
                                              _refreshStashList();
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (i != _stashList.length - 1) ...[
                                Container(
                                  height: 1.25,
                                  color: Config.grayedForegroundColor,
                                ),
                              ]
                            ],
                          ] else ...[
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text("No stashes found.",
                                style: Theme.of(context).textTheme.bodyText1),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class Sidebar extends StatefulWidget {
  final String sidebarContent;
  final List sidebarBranches;
  final String targetLocation;
  final VoidCallback targetRefresh;

  const Sidebar(
    this.sidebarContent,
    this.sidebarBranches,
    this.targetLocation,
    this.targetRefresh);

  @override
  State<Sidebar> createState() => _SidebarState();
}

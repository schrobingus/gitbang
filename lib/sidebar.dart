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

  Future<void> _refreshPage() async {
    setState(() {
      _showHistory = false;
    });

    var historyCommand = await Process.start("git", ["log", "--oneline"],
        workingDirectory: widget.targetLocation);
    var historyPageAmountPipe = await Process.start("wc", ["-l"]);
    await historyCommand.stdout.pipe(historyPageAmountPipe.stdin);
    await historyPageAmountPipe.stdout
        .transform(utf8.decoder)
        .forEach((String out) => setState(() {
              _historyEntryAmount = double.parse(out);
            }));
    setState(() {
      _historyPageAmount = (_historyEntryAmount / 25).ceil();
    });

    double historyPageTailEnsure = 0;
    if (_historyPageNumber == _historyPageAmount - 1 &&
        _historyEntryAmount / 25 != (_historyEntryAmount / 25).ceil()) {
      historyPageTailEnsure = _historyEntryAmount % 25;
    } else {
      historyPageTailEnsure = 25;
    }

    var historyCommandNext = await Process.start("git", ["log", "--oneline"],
        workingDirectory: widget.targetLocation);
    var historyPageHead = await Process.start(
        "head", ["-n", ((_historyPageNumber + 1) * 25).toString()]);
    historyCommandNext.stdout.pipe(historyPageHead.stdin);
    var historyPageTail = await Process.start(
        "tail", ["-n", historyPageTailEnsure.toInt().toString()]);
    historyPageHead.stdout.pipe(historyPageTail.stdin);

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

  @override
  void initState() {
    super.initState();
    if (widget.sidebarContent == "history") {
      _refreshPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    Color selectedColor(String i) {
      if (i[0] == '*') {
        if (i.contains("detached")) {
          return colorSidebarItemDetach;
        } else {
          return colorSidebarItemSel;
        }
      } else {
        return colorSidebarItemFg;
      }
    }

    return Drawer(
      backgroundColor: colorSidebarBg,
      child: SingleChildScrollView(
        child: Column(children: [
          if (widget.sidebarContent == "branches") ...[
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Local",
                        style: TextStyle(color: colorSidebarFg)),
                    GestureDetector(
                      child: const Text("+ Add New",
                          style: TextStyle(color: colorSidebarFg)),
                      onTap: () {
                        TextEditingController branchName =
                            TextEditingController();
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

                                            try {
                                              Process.run(
                                                  "git",
                                                  [
                                                    "checkout",
                                                    "-b",
                                                    branchName.text
                                                  ],
                                                  workingDirectory:
                                                      widget.targetLocation);
                                            } catch (e) {
                                              Future.delayed(
                                                  const Duration(seconds: 0),
                                                  () => showDialog(
                                                      context: context,
                                                      builder: (BuildContext
                                                          context) {
                                                        return errorMessageDialog(
                                                            context,
                                                            "Could not create branch.");
                                                      }));
                                            }
                                          },
                                          child: const Text("Add")),
                                    ],
                                  );
                                }));
                      },
                    ),
                  ]),
            ),
            Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                    decoration: BoxDecoration(
                      color: colorSidebarItemBg,
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
                        child: Column(children: [
                          for (var i = 0;
                              i < widget.sidebarBranches.length;
                              i++) ...[
                            if (!widget.sidebarBranches[i]
                                .substring(2, widget.sidebarBranches[i].length)
                                .split(" -> ")
                                .last
                                .startsWith("remotes/")) ...[
                              Container(
                                decoration: const BoxDecoration(
                                  color: colorSidebarItemBg,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 10.0,
                                      right: 10.0,
                                      top: 7.5,
                                      bottom: 7.5),
                                  child: Align(
                                    alignment: Alignment.topLeft,
                                    child: GestureDetector(
                                      onTap: () {
                                        void checkoutBranch() async {
                                          try {
                                            await Process.start(
                                                "git",
                                                [
                                                  "checkout",
                                                  widget.sidebarBranches[i]
                                                      .substring(
                                                          2,
                                                          widget
                                                              .sidebarBranches[
                                                                  i]
                                                              .length)
                                                      .split(" -> ")
                                                      .last
                                                ],
                                                workingDirectory:
                                                    widget.targetLocation);
                                          } catch (e) {
                                            var branchName = widget
                                                .sidebarBranches[i]
                                                .substring(
                                                    2,
                                                    widget.sidebarBranches[i]
                                                        .length)
                                                .split(" -> ")
                                                .last;

                                            Future.delayed(
                                                const Duration(seconds: 0),
                                                () => showDialog(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
                                                      return errorMessageDialog(
                                                          context,
                                                          "Could not switch to branch ($branchName).");
                                                    }));
                                          }
                                        }

                                        if (!widget.sidebarBranches[i]
                                            .substring(
                                                2,
                                                widget
                                                    .sidebarBranches[i].length)
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
                                              if (widget.sidebarBranches[i]
                                                  .contains("(")) {
                                                return widget.sidebarBranches[i]
                                                    .substring(
                                                        2,
                                                        widget.sidebarBranches[i]
                                                                .length -
                                                            1)
                                                    .split(" ")
                                                    .last;
                                              } else {
                                                return widget.sidebarBranches[i]
                                                    .substring(
                                                        2,
                                                        widget
                                                            .sidebarBranches[i]
                                                            .length)
                                                    .split(" -> ")
                                                    .last;
                                              }
                                            }()),
                                            style: TextStyle(
                                                color: selectedColor(
                                                    widget.sidebarBranches[i])),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (!widget.sidebarBranches[i]
                                      .substring(
                                          2, widget.sidebarBranches[i].length)
                                      .split(" -> ")
                                      .last
                                      .startsWith("remotes/") &&
                                  widget.sidebarBranches[i] ==
                                      widget.sidebarBranches.lastWhere(
                                          (j) => !j.contains("remotes/"))) ...[
                                Container(
                                  height: 1.25,
                                  decoration: const BoxDecoration(
                                      color: colorSidebarSeparator),
                                ),
                              ],
                            ],
                          ],
                        ])))),
            const Padding(
              padding: EdgeInsets.only(left: 10.0, right: 10.0, top: 15.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: Text("Remote", style: TextStyle(color: colorSidebarFg)),
              ),
            ),
            Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                    decoration: BoxDecoration(
                      color: colorSidebarItemBg,
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
                        child: Column(children: [
                          for (var i = 0;
                              i < widget.sidebarBranches.length;
                              i++) ...[
                            if (widget.sidebarBranches[i]
                                .substring(2, widget.sidebarBranches[i].length)
                                .split(" -> ")
                                .last
                                .startsWith("remotes/")) ...[
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 10.0,
                                    right: 10.0,
                                    top: 7.5,
                                    bottom: 7.5),
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: GestureDetector(
                                    onTap: () {
                                      void checkoutBranch() async {
                                        try {
                                          await Process.start(
                                              "git",
                                              [
                                                "checkout",
                                                widget.sidebarBranches[i]
                                                    .substring(
                                                        2,
                                                        widget
                                                            .sidebarBranches[i]
                                                            .length)
                                                    .split(" -> ")
                                                    .last
                                              ],
                                              workingDirectory:
                                                  widget.targetLocation);
                                        } catch (e) {
                                          var branchName = widget
                                              .sidebarBranches[i]
                                              .substring(
                                                  2,
                                                  widget.sidebarBranches[i]
                                                      .length)
                                              .split(" -> ")
                                              .last;

                                          Future.delayed(
                                              const Duration(seconds: 0),
                                              () => showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return errorMessageDialog(
                                                        context,
                                                        "Could not switch to branch ($branchName).");
                                                  }));
                                        }
                                      }

                                      checkoutBranch();
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      widget.sidebarBranches[i]
                                          .substring(2,
                                              widget.sidebarBranches[i].length)
                                          .split(" -> ")
                                          .last,
                                      style: TextStyle(
                                          color: selectedColor(
                                              widget.sidebarBranches[i])),
                                    ),
                                  ),
                                ),
                              ),
                              if (widget.sidebarBranches[i]
                                      .substring(
                                          2, widget.sidebarBranches[i].length)
                                      .split(" -> ")
                                      .last
                                      .startsWith("remotes/") &&
                                  widget.sidebarBranches[i] !=
                                      widget.sidebarBranches.lastWhere(
                                          (j) => j.contains("remotes/"))) ...[
                                Container(
                                  height: 1.25,
                                  decoration: const BoxDecoration(
                                      color: colorSidebarSeparator),
                                ),
                              ],
                              // FIXME: For some reason, the function doesn't appear to be working.
                            ],
                          ]
                        ])))),
          ] else if (widget.sidebarContent == "history") ...[
            Column(
              children: [
                if (_showHistory) ...[
                  for (var i = 0; i < _historyPageList.length; i++) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorSidebarItemBg,
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
                              child: SelectableText(_historyPageList[i][0]),
                            ),
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: SelectableText(_historyPageList[i][1],
                                    textAlign: TextAlign.right),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ] else ...[
                  const Padding(
                      padding: EdgeInsets.all(8),
                      child: Center(child: CircularProgressIndicator())),
                ],
                if (_historyPageAmount != 1) ...[
                  Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Container(
                          decoration: BoxDecoration(
                            color: colorSidebarItemBg,
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
                                    icon: const Icon(
                                        Icons.keyboard_double_arrow_left),
                                    padding: const EdgeInsets.all(0.0),
                                    onPressed: () {
                                      setState(() {
                                        _historyPageNumber = 0;
                                      });
                                      _refreshPage();
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: IconButton(
                                    icon: const Icon(Icons.keyboard_arrow_left),
                                    padding: const EdgeInsets.all(0.0),
                                    onPressed: () {
                                      if (_historyPageNumber > 0) {
                                        setState(() {
                                          _historyPageNumber--;
                                        });
                                      }
                                      _refreshPage();
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    "${_historyPageNumber + 1}/$_historyPageAmount",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: IconButton(
                                    icon:
                                        const Icon(Icons.keyboard_arrow_right),
                                    padding: const EdgeInsets.all(0.0),
                                    onPressed: () {
                                      if (_historyPageNumber <
                                          _historyPageAmount - 1) {
                                        setState(() {
                                          _historyPageNumber++;
                                        });
                                      }

                                      _refreshPage();
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: IconButton(
                                    icon: const Icon(
                                        Icons.keyboard_double_arrow_right),
                                    padding: const EdgeInsets.all(0.0),
                                    onPressed: () {
                                      setState(() {
                                        _historyPageNumber =
                                            _historyPageAmount - 1;
                                      });
                                      _refreshPage();
                                    },
                                  ),
                                ),
                              ]))),
                ],
              ],
            ),
          ],
        ]),
      ),
    );
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

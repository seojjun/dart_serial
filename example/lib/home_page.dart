// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

import 'package:serial/serial.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  SerialPort? _port1;
  SerialPort? _port2;
  final _received1 = <Uint8List>[];
  final _received2 = <Uint8List>[];

  final _controller1 = TextEditingController();
  final _controller2 = TextEditingController();
  final sendMsgNode1 = FocusNode();
  final sendMsgNode2 = FocusNode();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController1 = ScrollController();
  final ScrollController _scrollController2 = ScrollController();
  bool _ctrlPressed = false;
  String binaryString = '\x03';

  Future<void> _openPort1() async {
    await _port1?.close();

    final port = await window.navigator.serial.requestPort();
    await port.open(baudRate: 9600);

    _port1 = port;

    _startReceiving1(port);

    logger.i('port1 open');
    setState(() {});
  }

  Future<void> _openPort2() async {
    await _port2?.close();

    final port = await window.navigator.serial.requestPort();
    await port.open(baudRate: 9600);

    _port2 = port;

    _startReceiving2(port);

    setState(() {});
  }

  Future<void> _writeToPort(Uint8List data, int portNum) async {
    if (data.isEmpty) {
      return;
    }

    final port = portNum == 1 ? _port1 : _port2;

    if (port == null) {
      return;
    }

    final writer = port.writable.writer;

    await writer.ready;
    await writer.write(data);
    await writer.ready;
    await writer.close();
  }

  Future<void> _stopCommand(int portNum) async {
    final port = portNum == 1 ? _port1 : _port2;

    if (port == null) {
      return;
    }

    final writer = port.writable.writer;

    await writer.ready;
    await writer.write(Uint8List.fromList(binaryString.codeUnits));
    await writer.ready;
    await writer.close();
  }

  Future<void> _startReceiving1(SerialPort port) async {
    final reader = port.readable.reader;

    while (true) {
      final result = await reader.read();
      _received1.add(result.value);

      if (_scrollController1.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback(
          (timeStamp) {
            _scrollController1.animateTo(
              _scrollController1.position.maxScrollExtent,
              duration: Duration(milliseconds: 100),
              curve: Curves.easeOut,
            );
          },
        );
      }

      setState(() {});
    }
  }

  Future<void> _startReceiving2(SerialPort port) async {
    final reader = port.readable.reader;

    while (true) {
      final result = await reader.read();
      _received2.add(result.value);

      if (_scrollController2.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback(
          (timeStamp) {
            _scrollController2.animateTo(
              _scrollController2.position.maxScrollExtent,
              duration: Duration(milliseconds: 100),
              curve: Curves.easeOut,
            );
          },
        );
      }

      setState(() {});
    }
  }

  void _sendEvent(int portNum) {
    var text =
        portNum == 1 ? '${_controller1.text}\r' : '${_controller2.text}\r';
    _writeToPort(Uint8List.fromList(text.codeUnits), portNum);
    portNum == 1 ? _controller1.clear() : _controller2.clear();
    portNum == 1
        ? FocusScope.of(context).requestFocus(sendMsgNode1)
        : FocusScope.of(context).requestFocus(sendMsgNode2);
  }

  @override
  Widget build(BuildContext context) {
    //final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Serial Port'),
        actions: [
          IconButton(
            onPressed: _openPort1,
            icon: Icon(Icons.device_hub),
            tooltip: 'Open Serial Port',
          ),
          IconButton(
            onPressed: _port1 == null
                ? null
                : () async {
                    await _port1?.close();
                    _port1 = null;

                    setState(() {});
                  },
            icon: Icon(Icons.close),
            tooltip: 'Close Serial Port',
          ),
          IconButton(
            onPressed: _openPort2,
            icon: Icon(Icons.device_hub),
            tooltip: 'Open Serial Port',
          ),
          IconButton(
            onPressed: _port2 == null
                ? null
                : () async {
                    await _port2?.close();
                    _port2 = null;

                    setState(() {});
                  },
            icon: Icon(Icons.close),
            tooltip: 'Close Serial Port',
          ),
        ],
      ),
      body: RawKeyboardListener(
        focusNode: _focusNode,
        onKey: (RawKeyEvent event) {
          int portNum = 1;
          if (sendMsgNode1.hasFocus) {
            portNum = 1;
          } else if (sendMsgNode2.hasFocus) {
            portNum = 2;
          }

          if (event is RawKeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
                event.logicalKey == LogicalKeyboardKey.controlRight) {
              _ctrlPressed = true;
            } else if (_ctrlPressed &&
                event.logicalKey == LogicalKeyboardKey.keyC) {
              _stopCommand(portNum);
              print('copy');
              print(portNum);
              _ctrlPressed = false;
            }
          } else if (event is RawKeyUpEvent) {
            if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
                event.logicalKey == LogicalKeyboardKey.controlRight) {
              _ctrlPressed = false;
            }
          }
        },
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white54),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: _received1.isNotEmpty
                            ? ListView(
                                controller: _scrollController1,
                                padding: const EdgeInsets.all(4),
                                children: _received1.map((e) {
                                  final text = String.fromCharCodes(e);
                                  return Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Text(text),
                                  );
                                }).toList(),
                              )
                            : Center(
                                child: Text(
                                  'No data received yet.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: TextField(
                            controller: _controller1,
                            focusNode: sendMsgNode1,
                            onSubmitted: (String value) {
                              _sendEvent(1);
                            },
                          ),
                        ),
                        Gap(8),
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: ElevatedButton(
                            child: const Text('Send'),
                            onPressed: () {
                              _sendEvent(1);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white54),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: _received2.isNotEmpty
                            ? ListView(
                                controller: _scrollController2,
                                padding: const EdgeInsets.all(4),
                                children: _received2.map((e) {
                                  final text = String.fromCharCodes(e);
                                  return Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Text(text),
                                  );
                                }).toList(),
                              )
                            : Center(
                                child: Text(
                                  'No data received yet.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: TextField(
                            controller: _controller2,
                            focusNode: sendMsgNode2,
                            onSubmitted: (String value) {
                              _sendEvent(2);
                            },
                          ),
                        ),
                        Gap(8),
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: ElevatedButton(
                            child: const Text('Send'),
                            onPressed: () {
                              _sendEvent(2);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

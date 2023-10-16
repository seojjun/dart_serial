// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

import 'package:serial/serial.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  SerialPort? _port;
  final _received = <Uint8List>[];

  final _controller1 = TextEditingController();
  final sendMsgNode = FocusNode();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _ctrlPressed = false;
  String binaryString = '\x03';

  Future<void> _openPort() async {
    await _port?.close();

    final port = await window.navigator.serial.requestPort();
    await port.open(baudRate: 9600);

    _port = port;

    _startReceiving(port);

    setState(() {});
  }

  Future<void> _writeToPort(Uint8List data) async {
    if (data.isEmpty) {
      return;
    }

    final port = _port;

    if (port == null) {
      return;
    }

    final writer = port.writable.writer;

    await writer.ready;
    await writer.write(data);
    await writer.ready;
    await writer.close();
  }

  Future<void> _stopCommand() async {
    final port = _port;

    if (port == null) {
      return;
    }

    final writer = port.writable.writer;

    await writer.ready;
    await writer.write(Uint8List.fromList(binaryString.codeUnits));
    await writer.ready;
    await writer.close();
  }

  Future<void> _startReceiving(SerialPort port) async {
    final reader = port.readable.reader;

    while (true) {
      final result = await reader.read();
      _received.add(result.value);

      if (_scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback(
          (timeStamp) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 100),
              curve: Curves.easeOut,
            );
          },
        );
      }

      setState(() {});
    }
  }

  void _sendEvent() {
    var text = '${_controller1.text}\r';
    _writeToPort(Uint8List.fromList(text.codeUnits));
    _controller1.clear();
    FocusScope.of(context).requestFocus(sendMsgNode);
  }

  @override
  Widget build(BuildContext context) {
    //final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Serial Port'),
        actions: [
          IconButton(
            onPressed: _openPort,
            icon: Icon(Icons.device_hub),
            tooltip: 'Open Serial Port',
          ),
          IconButton(
            onPressed: _port == null
                ? null
                : () async {
                    await _port?.close();
                    _port = null;

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
          if (event is RawKeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
                event.logicalKey == LogicalKeyboardKey.controlRight) {
              _ctrlPressed = true;
            } else if (_ctrlPressed &&
                event.logicalKey == LogicalKeyboardKey.keyC) {
              _stopCommand();
              _ctrlPressed = false;
            }
          } else if (event is RawKeyUpEvent) {
            if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
                event.logicalKey == LogicalKeyboardKey.controlRight) {
              _ctrlPressed = false;
            }
          }
        },
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
                  child: _received.isNotEmpty
                      ? ListView(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(4),
                          children: _received.map((e) {
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
                      focusNode: sendMsgNode,
                      onSubmitted: (String value) {
                        _sendEvent();
                      },
                    ),
                  ),
                  Gap(8),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ElevatedButton(
                      child: const Text('Send'),
                      onPressed: () {
                        _sendEvent();
                      },
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

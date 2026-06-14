import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mel_spectrogram_flutter/mel_sonogram_scrollable_plot.dart';
import 'dart:async';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:mel_spectrogram_flutter/mel_spectrogram_flutter.dart';
import 'package:mel_spectrogram_flutter/mel_spectrogram_plot.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _plugin = MelSpectrogramFlutter();

  String _assetFilePath = 'assets/test_large_96k.wav';
  String _error = "";
  List<List<double>>? _spectrogram;
  bool _isLoading = false;

  int _sampleRate = 44100;
  int _frameSize = 1024;
  int _hopSize = 256;
  int _numBands = 50;
  double _power = 6.0;

  int? _computeTime;
  double _playheadPosition = 0.0;

  Future<void> _computeSpectrogram() async {
    setState(() {
      _isLoading = true;
    });

    final startTime = DateTime.now();

    final outFileName = _assetFilePath.split('/').last;
    final outPath = p.join((await getTemporaryDirectory()).path, outFileName);
    final audioFile = File(outPath);
    try {
      await audioFile.writeAsBytes(
        (await rootBundle.load(_assetFilePath)).buffer.asUint8List(),
      );

      final spec = await _plugin.decodeFileAndComputeMelSpectrogram(
        filePath: outPath,
        sampleRate: _sampleRate,
        frameSize: _frameSize,
        hopSize: _hopSize,
        numBands: _numBands,
        power: _power,
      );

      setState(() {
        _spectrogram = spec;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
        _computeTime = DateTime.now().difference(startTime).inMilliseconds;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _computeSpectrogram();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Mel Spectrogram Plugin')),
        body: Column(
          children: [
            if (_error.isNotEmpty) Text(_error),

            if (_spectrogram != null && _spectrogram!.isNotEmpty)
              MelSonogramScrollablePlot(
                spectrogram: _spectrogram!,
                frameDurationSeconds: _hopSize / _sampleRate,
                visibleSeconds: 5,
                playheadPosition: _playheadPosition,
                onPlayheadPositionChanged: (pos) {
                  setState(() {
                    _playheadPosition = pos;
                  });
                },
              ),

            Text('Playhead: ${(_playheadPosition * 100).toStringAsFixed(1)}%'),

            if (_computeTime != null)
              Text('Compute time: $_computeTime ms'),

            // configuration form
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    FileSelector(
                      value: _assetFilePath,
                      onChanged: (value) {
                        setState(() {
                          _assetFilePath = value;
                        });
                      },
                    ),

                    NumericTextField(
                      label: 'Sample Rate',
                      value: _sampleRate.toString(),
                      onChanged: (value) =>
                          _sampleRate = int.tryParse(value) ?? _sampleRate,
                    ),

                    NumericTextField(
                      label: 'Frame Size',
                      value: _frameSize.toString(),
                      onChanged: (value) =>
                          _frameSize = int.tryParse(value) ?? _frameSize,
                    ),

                    NumericTextField(
                      label: 'Hop Size',
                      value: _hopSize.toString(),
                      onChanged: (value) =>
                          _hopSize = int.tryParse(value) ?? _hopSize,
                    ),
                    NumericTextField(
                      label: 'Number of Bands',
                      value: _numBands.toString(),
                      onChanged: (value) =>
                          _numBands = int.tryParse(value) ?? _numBands,
                    ),
                    NumericTextField(
                      label: 'Power',
                      value: _power.toString(),
                      onChanged: (value) =>
                          _power = double.tryParse(value) ?? _power,
                    ),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _computeSpectrogram,
                      child: const Text('Recompute Spectrogram'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FileSelector extends StatefulWidget {
  const FileSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.options = const <String>[
      'assets/test_44k.mp3',
      'assets/test_large_96k.wav',
    ],
  });

  final String value;
  final Function(String) onChanged;
  final List<String> options;

  @override
  State<FileSelector> createState() => _FileSelectorState();
}

class _FileSelectorState extends State<FileSelector> {
  String? _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: _value,
      items: widget.options
          .map(
            (option) => DropdownMenuItem(
              value: option,
              child: Text(option.split('/').last),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          _value = value;
          widget.onChanged(value);
        }
      },
    );
  }
}

class NumericTextField extends StatefulWidget {
  const NumericTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Function(String) onChanged;

  @override
  State<NumericTextField> createState() => _NumericTextFieldState();
}

class _NumericTextFieldState extends State<NumericTextField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(labelText: widget.label),
      keyboardType: TextInputType.number,
      onChanged: widget.onChanged,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:statsfl/statsfl.dart';
import 'package:resource_monitor/resource_monitor.dart';
import 'dart:math';
import 'dart:async';

import 'package:flutter/services.dart';

void main() {
  //Enable this to measure your repaint regions
  //debugRepaintRainbowEnabled = true;
  runApp(Padding(
    padding: const EdgeInsets.only(top: 40),
    child: StatsFl(
      isEnabled: true,
      align: Alignment.topRight,
      height: 20,
      child: MaterialApp(
          debugShowCheckedModeBanner: false, home: Scaffold(body: MyApp())),
    ),
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    int boxCount = 20;
    List<Widget> boxes = List.generate(
      boxCount,
      (index) => ShadowBox(),
    ).toList();

    return Stack(
      children: [
        /// Test 2nd level of nesting
        StatsFl(
            isEnabled: true,
            maxFps: 90,
            width: 200,
            height: 30,
            align: Alignment.topLeft,
            child: Center(child: ListView(children: boxes))),

        Center(
            child: IconButton(
          iconSize: 54,
          alignment: Alignment.bottomRight,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const BottomSheetExample()),
            );
          },
          icon: Text('change page'),
        )),

        /// Test floating version with no child
        Positioned.fill(
            child: Align(alignment: Alignment.bottomCenter, child: StatsFl())),
      ],
    );
  }
}

class ShadowBox extends StatelessWidget {
  const ShadowBox({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      height: 120,
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
            spreadRadius: 4,
            blurRadius: 4,
            color: Colors.redAccent.withOpacity(.2)),
      ]),
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        child: SizedBox.fromSize(
            size: Size(20, 20), child: CircularProgressIndicator()),
      ),
    );
  }
}

class SecondRoute extends StatelessWidget {
  const SecondRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Second Route'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Go back!'),
        ),
      ),
    );
  }
}

class BottomSheetExample extends StatelessWidget {
  const BottomSheetExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        child: const Text('Iniciar animação'),
        onPressed: () {
          showModalBottomSheet<void>(
            context: context,
            builder: (BuildContext context) {
              return SizedBox(
                height: 700,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text('Vim pela animação'),
                      ElevatedButton(
                        child: const Text('Fechar animação'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class CPUusage extends StatefulWidget {
  const CPUusage({Key? key}) : super(key: key);

  @override
  State<CPUusage> createState() => _CPUusageState();
}

class _CPUusageState extends State<CPUusage> {
  Resource? _data;
  static const double _defaultValue = 0.0;
  double _appCpuUsagePeak = _defaultValue, _appMemoryUsagePeak = _defaultValue;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer =
        Timer.periodic(const Duration(seconds: 1), (Timer t) => _getResource());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _getResource() async {
    try {
      final data = await ResourceMonitor.getResourceUsage;

      _appCpuUsagePeak = data.cpuInUseByApp > _appCpuUsagePeak
          ? data.cpuInUseByApp
          : _appCpuUsagePeak;
      _appMemoryUsagePeak = data.memoryInUseByApp > _appMemoryUsagePeak
          ? data.memoryInUseByApp
          : _appMemoryUsagePeak;
      setState(() => _data = data);
    } on PlatformException {
      throw PlatformException(
          code: 'Unknow-error', message: 'getResourceUsage');
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
      home: Scaffold(
          appBar: AppBar(title: const Text('Plugin example app')),
          body: Center(
              child: _data != null
                  ? Table(
                      defaultColumnWidth: const FixedColumnWidth(120.0),
                      border: TableBorder.all(
                          color: Colors.black,
                          style: BorderStyle.solid,
                          width: 2),
                      children: [
                          TableRow(children: [
                            Column(children: const [
                              Text('Resource', style: TextStyle(fontSize: 20.0))
                            ]),
                            Column(children: const [
                              Text('App', style: TextStyle(fontSize: 20.0))
                            ])
                          ]),
                          TableRow(children: [
                            Column(children: const [Text('RAM - Live')]),
                            Column(children: [
                              Text(formatBytes(
                                  _data!.memoryInUseByApp.toInt(), 2))
                            ])
                          ]),
                          TableRow(children: [
                            Column(children: const [Text('CPU - Live')]),
                            Column(children: [
                              Text('${_data?.cpuInUseByApp.floorToDouble()} %')
                            ])
                          ]),
                          TableRow(children: [
                            Column(children: const [Text('RAM - Peak')]),
                            Column(children: [
                              Text(formatBytes(_appMemoryUsagePeak.toInt(), 2))
                            ])
                          ]),
                          TableRow(children: [
                            Column(children: const [Text('CPU - Peak')]),
                            Column(children: [Text('$_appCpuUsagePeak')]),
                          ])
                        ])
                  : const CircularProgressIndicator()),
          floatingActionButton: FloatingActionButton(
              onPressed: _getResource, child: const Icon(Icons.memory))));
}

String formatBytes(int bytes, int decimals) {
  if (bytes <= 0) return "0 B";
  const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
  var i = (log(bytes) / log(1024)).floor();
  return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
}

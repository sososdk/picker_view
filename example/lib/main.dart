import 'dart:async';
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:picker_view/picker_view.dart';
import 'package:picker_view_example/district.dart';

void main() {
  runApp(DevicePreview(
    enabled: kIsWeb,
    devices: [
      ...Devices.ios.all.reversed,
      ...Devices.android.all,
      ...Devices.linux.all,
      ...Devices.windows.all,
      ...Devices.macos.all,
    ],
    builder: (context) => App(),
  ));
}

class App extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Picker View Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: PickerViewHomePage(title: 'Flutter Picker View Demo'),
    );
  }
}

class PickerViewHomePage extends StatefulWidget {
  PickerViewHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _PickerViewHomePageState createState() => _PickerViewHomePageState();
}

class _PickerViewHomePageState extends State<PickerViewHomePage> {
  PickerController _controller = PickerController(length: 3);
  Future<List<District>> _districtFuture = request();

  @override
  void initState() {
    super.initState();
    _controller = PickerController(length: 3, scrollControllers: [
      FixedExtentScrollController(initialItem: 3),
      FixedExtentScrollController(initialItem: 2),
      FixedExtentScrollController(initialItem: 2),
    ]);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FutureBuilder<List<District>>(
          future: _districtFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              var districts = snapshot.data;
              return Column(
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints.expand(height: 200),
                    child: PickerView(
                      controller: _controller,
                      padding: const EdgeInsets.all(8.0),
                      numberOfRowsAtSection: (section) {
                        if (section == 1) {
                          final index0 = _controller.selectedItems()[0];
                          return districts.tryGet(index0)?.districts?.length ??
                              0;
                        } else if (section == 2) {
                          final index0 = _controller.selectedItems()[0];
                          final index1 = _controller.selectedItems()[1];
                          return districts
                                  .tryGet(index0)
                                  ?.districts
                                  ?.tryGet(index1)
                                  ?.districts
                                  ?.length ??
                              0;
                        } else {
                          return districts.length;
                        }
                      },
                      itemBuilder: (context, section, index) {
                        District district;
                        if (section == 1) {
                          final index0 = _controller.selectedItems()[0];
                          district =
                              districts.tryGet(index0).districts.tryGet(index);
                        } else if (section == 2) {
                          final index0 = _controller.selectedItems()[0];
                          final index1 = _controller.selectedItems()[1];
                          district = districts
                              .tryGet(index0)
                              .districts
                              .tryGet(index1)
                              .districts
                              .tryGet(index);
                        } else {
                          district = districts[index];
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: AutoSizeText(
                            district.name,
                            minFontSize: 6,
                            maxLines: 1,
                          ),
                        );
                      },
                      onSelectRowChanged: (section, index) {
                        // do something
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(() {
                    var items = _controller.selectedItems();
                    var district0 = districts[items[0]];
                    var district1 = district0?.districts?.tryGet(items[1]);
                    var district2 = district1?.districts?.tryGet(items[2]);
                    return '${district0.name}${district1?.name ?? ''}${district2?.name ?? ''}';
                  }()),
                ],
              );
            } else if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasError) {
              return Center(
                child: GestureDetector(
                  child: Icon(Icons.error, size: 120),
                  onTap: () {
                    setState(() {
                      _districtFuture = request();
                    });
                  },
                ),
              );
            } else {
              return Center(child: CupertinoActivityIndicator());
            }
          }),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.wash_rounded),
        onPressed: () {
          var selectedItem = _controller.scrollControllers[0].selectedItem;
          _controller.scrollControllers[0].jumpToItem(selectedItem + 1);
          _controller.scrollControllers[1].jumpToItem(1);
          _controller.scrollControllers[2].jumpToItem(2);
        },
      ),
    );
  }
}

Future<List<District>> request() async {
  final url =
      'https://restapi.amap.com/v3/config/district?key=9ad362af520113de3f0b734b7e48cd58&subdistrict=3';
  final response = await get(url);
  List districts = jsonDecode(response.body)['districts'][0]['districts'];
  return districts.map((e) => District.fromJson(e)).toList();
}

extension IteratorExtension<T> on List<T> {
  T tryGet(int index) {
    if (index < length) return this[index];
    return firstWhere((element) => true, orElse: () => null);
  }
}

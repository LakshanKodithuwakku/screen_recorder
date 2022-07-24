import 'package:flutter/material.dart';

import 'package:flutter_floatwing/flutter_floatwing.dart';
import 'package:screen_recorder/views/assistive_touch.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState(){
     return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
  var _configs = [
    WindowConfig(
      id: "assitive_touch",
      // entry: "floatwing",
      route: "/assitive_touch",
      draggable: true,
    ),
  ];

  Map<String, WidgetBuilder> _builders = {
    "assitive_touch": (_) => AssistiveTouch(),
  };

  Map<String, Widget Function(BuildContext)> _routes = {};

  @override
  void initState() {
    super.initState();
    _routes["/"] = (_) => HomePage(configs: _configs);
    _configs.forEach((c) => {
          if (c.route != null && _builders[c.id] != null)
            {_routes[c.route!] = _builders[c.id]!.floatwing(debug: false)}
        });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/",
      routes: _routes,
    );
  }
}

class HomePage extends StatefulWidget {
  final List<WindowConfig> configs;
  const HomePage({Key? key, required this.configs}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();

    widget.configs.forEach((c) => _windows.add(c.to()));

    FloatwingPlugin().initialize();

    initAsyncState();
  }

  List<Window> _windows = [];

  Map<Window, bool> _readys = {};

  bool _ready = false;

  initAsyncState() async {
    var p1 = await FloatwingPlugin().checkPermission();
    var p2 = await FloatwingPlugin().isServiceRunning();

    // get permission first
    if (!p1) {
      FloatwingPlugin().openPermissionSetting();
      return;
    }

    // start service
    if (!p2) {
      FloatwingPlugin().startService();
    }

    _createWindows();

    setState(() {
      _ready = true;
    });
  }

  _createWindows() async {
    await FloatwingPlugin().isServiceRunning().then((v) async {
      if (!v)
        await FloatwingPlugin().startService().then((_) {
          print("start the backgroud service success.");
        });
    });

    _windows.forEach((w) {
      var _w = FloatwingPlugin().windows[w.id];
      if (null != _w) {
        // replace w with _w
        _readys[w] = true;
        return;
      }
      w.on(EventType.WindowCreated, (window, data) {
        _readys[window] = true;
        setState(() {});
      }).create();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _ready
          ? Center(
            child: ListView(
                children: _windows.map((e) => _item(e)).toList(),
              ),
          )
          : Center(
              child: ElevatedButton(
                  onPressed: () {
                    initAsyncState();
                  },
                  child: Text("Start")),
            ),
    );
  }

  Widget _item(Window w) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Card(
          margin: EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: (_readys[w] == true) ? () => w.start() : null,
                child: Text("Open"),
              ),
              TextButton(
                onPressed: (_readys[w] == true)
                    ? () => {w.close(), w.share("close")}
                    : null,
                child: Text("Close", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

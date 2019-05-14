import 'dart:async' show Future;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:vibrate/vibrate.dart';
import 'package:moment/moment.dart';
import 'package:weather/weather.dart';
import 'dart:convert';

void main() => runApp(App());

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

Future<String> getJson(String path) async {
  return await rootBundle.loadString(path);
}

class _AppState extends State<App> {
  var wS = new WeatherStation('OpenWeatherMap API here');
  var w;
  var mode = false;
  var time = '';
  var day = 0;
  var srT = 'refreshing...';
  var ssT = 'refreshing...';
  var tP = Colors.amber;
  var tw = 'TimeWatcher';
  Map<String, dynamic> a;
  var naW = 0;
  Future<void> setDelayed() {
    update();
    return Future.delayed(Duration(seconds: 1)).then((_) {
      setDelayed();
    });
  }

  Future<void> setWeather() {
    wS.currentWeather().then((result) {
      setState(() {
        w = result;
      });
    });
    return Future.delayed(Duration(hours: 1)).then((_) {
      setWeather();
    });
  }

  @override
  void initState() {
    super.initState();
    if (naW == 0)
      getJson('assets/strings.json').then((result) {
        setState(() {
          a = jsonDecode(result);
          naW = 2;
        });
      });
    setWeather();
    setDelayed();
    wS.currentWeather().then((result) {
      setState(() {
        w = result;
      });
    });
  }

  void update() {
    var core = new DateTime.now();
    var coreM = new Moment();
    var wD = core.weekday % 7;
    var fH = ((wD) * 24 + core.hour) % 28;
    var sfHr = (fH < 10) ? '0$fH' : fH.toString();
    var minSS = coreM.format(':mm:ss');
    var e = 'not available';
    var sH = ' hours';
    var iN = 'in ';
    var l1H = 'less than 1 hour';
    setState(() {
      tP = (mode) ? Colors.green : Colors.amber;
      time = (mode) ? coreM.format('HH:mm:ss') : sfHr + minSS;
      day = (mode) ? wD : (((wD) * 24 + core.hour) / 28).floor();
      if (w != null) {
        var sr = w.sunrise.difference(core);
        var ss = w.sunset.difference(core);
        var lessR = (sr.inHours == 0) ? l1H : sr.inHours.toString() + sH;
        var lessS = (ss.inHours == 0) ? l1H : ss.inHours.toString() + sH;
        srT = (!sr.isNegative) ? iN + lessR : e;
        ssT = (!ss.isNegative) ? iN + lessS : e;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var h1 = TextStyle(fontSize: 36);
    var h2 = TextStyle(fontSize: 64);
    var h3 = TextStyle(fontSize: 24);
    var h4 = TextStyle(fontSize: 22, fontWeight: FontWeight.w500);
    var e1 = EdgeInsets.only(left: 12, right: 12, top: 12);
    var e2 = EdgeInsets.all(12);
    var tPo = tP.withOpacity(0.85);
    var isR = Icons.wb_sunny;
    var isS = Icons.brightness_2;
    var mAaSe = MainAxisAlignment.spaceEvenly;
    var wL = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    var wLw = new List<Widget>();
    var scLw = new List<Widget>();
    var aLw = new List<Widget>();
    if (!mode) wL.removeLast();
    for (var i in wL)
      wLw.add(Chip(
          backgroundColor: tP.withOpacity(0.20), label: Text(i, style: h3)));
    wLw.removeAt(day);
    wLw.insert(
        day, Chip(label: Text(wL[day], style: h3), backgroundColor: tPo));
    for (int i = 1; i <= 2; i++)
      scLw.add(ListTile(
          leading: Icon((i == 1) ? isR : isS, color: tPo),
          title:
              Text((i == 1) ? 'Sunrise ' + srT : 'Sunset ' + ssT, style: h3)));
    aLw.add(Container(
        child: Text('Sleep schedule (24 hr. format)', style: h4), margin: e1));
    for (int ii = 0; ii < 2; ii++)
      for (int i = 1; i <= naW; i++)
        aLw.add(ListTileTheme(
            iconColor: (ii == 0) ? tPo : tP.withOpacity(0.40),
            child: ListTile(
                leading: Icon((i == 1) ? Icons.local_hotel : Icons.local_cafe),
                title:
                    Text(a[((ii + day) % 6).toString() + '.$i'], style: h3))));
    return GestureDetector(
      onTap: () {
        Vibrate.feedback(FeedbackType.medium);
        mode = !mode;
        update();
      },
      child: MaterialApp(
        title: tw,
        theme:
            ThemeData(scaffoldBackgroundColor: tP.shade100, primarySwatch: tP),
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          appBar: AppBar(title: Text(tw)),
          body: Center(
              child: SingleChildScrollView(
                  child: Column(children: <Widget>[
            Card(
              margin: e1,
              child: ListTile(
                  leading: Chip(
                      backgroundColor: tPo,
                      label: Text((mode) ? '24' : '28', style: h1)),
                  title: Text(time, style: h2)),
            ),
            Card(
                margin: e1,
                child: Row(mainAxisAlignment: mAaSe, children: wLw)),
            Card(margin: e1, child: Column(children: scLw)),
            Card(margin: e2, child: Column(children: aLw)),
          ]))),
        ),
      ),
    );
  }
}

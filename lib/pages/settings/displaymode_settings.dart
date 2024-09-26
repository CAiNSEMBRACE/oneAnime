import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:hive/hive.dart';
import 'package:oneanime/utils/storage.dart';
import 'package:oneanime/i18n/strings.g.dart';

class SetDiaplayMode extends StatefulWidget {
  const SetDiaplayMode({super.key});

  @override
  State<SetDiaplayMode> createState() => _SetDiaplayModeState();
}

class _SetDiaplayModeState extends State<SetDiaplayMode> {
  List<DisplayMode> modes = <DisplayMode>[];
  DisplayMode? active;
  DisplayMode? preferred;
  late Translations i18n;
  Box setting = GStorage.setting;

  final ValueNotifier<int> page = ValueNotifier<int>(0);
  late final PageController controller = PageController()
    ..addListener(() {
      page.value = controller.page!.round();
    });
  @override
  void initState() {
    super.initState();
    init();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      fetchAll();
    });
  }

  Future<void> fetchAll() async {
    preferred = await FlutterDisplayMode.preferred;
    active = await FlutterDisplayMode.active;
    await setting.put(SettingBoxKey.displayMode, preferred.toString());
    setState(() {});
  }

  Future<void> init() async {
    try {
      modes = await FlutterDisplayMode.supported;
    } on PlatformException catch (e) {
      debugPrint(e.toString());
    }
    var res = await getDisplayModeType(modes);

    preferred = modes.toList().firstWhere((el) => el == res);
    FlutterDisplayMode.setPreferredMode(preferred!);
  }

  Future<DisplayMode> getDisplayModeType(modes) async {
    var value = setting.get(SettingBoxKey.displayMode);
    DisplayMode f = DisplayMode.auto;
    if (value != null) {
      f = modes.firstWhere((e) => e.toString() == value);
    }
    return f;
  }

  @override
  Widget build(BuildContext context) {
    i18n = Translations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(i18n.my.themeSettings.refreshRate)),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (modes.isEmpty) const Text('Nothing here'),
            Padding(
              padding: const EdgeInsets.only(left: 25, top: 10, bottom: 5),
              child: Text(
                i18n.my.themeSettings.refreshRateWarning,
                style: TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: modes.length,
                itemBuilder: (_, int i) {
                  final DisplayMode mode = modes[i];
                  return RadioListTile<DisplayMode>(
                    value: mode,
                    title: mode == DisplayMode.auto
                        ? Text(i18n.my.themeSettings.refreshRateAuto)
                        : Text('$mode'),
                    groupValue: preferred,
                    onChanged: (DisplayMode? newMode) async {
                      await FlutterDisplayMode.setPreferredMode(newMode!);
                      await Future<dynamic>.delayed(
                        const Duration(milliseconds: 100),
                      );
                      await fetchAll();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Values derived from https://developer.apple.com/design/resources/ and on iOS
// simulators with "Debug View Hierarchy".
const double _kItemExtent = 32.0;
const double _kDiameterRatio = 1.07;
const bool _kUseMagnifier = true;
const double _kMagnification = 2.35 / 2.1;
// The density of a date picker is different from a generic picker.
// Eyeballed from iOS.
const double _kSqueeze = 1.25;

const TextStyle _kDefaultPickerTextStyle = TextStyle(
  letterSpacing: -0.83,
);

typedef PickerRowCallBack = int Function(int section);
typedef PickerItemBuilder = Widget Function(
    BuildContext context, int section, int row);
typedef PickerVoidCallBack = void Function(int section, int row);

class PickerView extends StatefulWidget {
  final PickerRowCallBack numberOfRowsAtSection;
  final PickerItemBuilder itemBuilder;
  final PickerVoidCallBack onSelectRowChanged;
  final double itemExtent;
  final double diameterRatio;
  final bool useMagnifier;
  final double magnification;
  final double squeeze;
  final PickerController controller;
  final double space;
  final EdgeInsets padding;

  PickerView({
    Key key,
    @required this.numberOfRowsAtSection,
    @required this.itemBuilder,
    @required this.controller,
    this.itemExtent,
    this.diameterRatio,
    this.useMagnifier,
    this.magnification,
    this.squeeze,
    this.onSelectRowChanged,
    this.space,
    this.padding,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => PickerViewState();
}

class PickerViewState extends State<PickerView> {
  PickerController _controller;
  double _squeeze;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? PickerController(length: 0);
    _squeeze = widget.squeeze ?? _kSqueeze;
  }

  @override
  void didUpdateWidget(PickerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller = widget.controller;
    }
    _squeeze = widget.squeeze ?? _kSqueeze;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
        child: DefaultTextStyle.merge(
          style: _kDefaultPickerTextStyle,
          child: Row(children: _buildPickers()),
        ),
      ),
    );
  }

  List<Widget> _buildPickers() {
    List<Widget> children = [];
    for (int section = 0; section < _controller.length; section++) {
      if (children.isNotEmpty && widget.space != null && widget.space != 0) {
        children.add(SizedBox(width: widget.space));
      }
      children.add(Expanded(child: _buildPickerSection(section: section)));
    }
    return children;
  }

  Widget _buildPickerSection({int section}) {
    final textDirectionFactor =
        Directionality.of(context) == TextDirection.ltr ? 1 : -1;
    final double offAxisFraction = (section - 1) * 0.3 * textDirectionFactor;
    final controller = _controller.scrollControllers[section];
    return PickerSection(
      controller: controller,
      itemExtent: widget.itemExtent,
      diameterRatio: widget.diameterRatio,
      offAxisFraction: offAxisFraction,
      useMagnifier: widget.useMagnifier,
      magnification: widget.magnification,
      squeeze: _squeeze,
      count: widget.numberOfRowsAtSection(section),
      changed: (row) {
        if (widget.onSelectRowChanged != null) {
          widget.onSelectRowChanged(section, row);
        }
        _controller.scrollControllers.indexWhere((e) {
          e.jumpToItem(0);
          return false;
        }, section + 1);

        // https://github.com/flutter/flutter/issues/22999
        if (_squeeze == _kSqueeze) {
          _squeeze = _kSqueeze + 0.000000000000001;
        } else {
          _squeeze = _kSqueeze;
        }
        setState(() {});
      },
      itemBuilder: (context, row) {
        return Align(
          alignment: Alignment.center,
          child: widget.itemBuilder(context, section, row),
        );
      },
    );
  }
}

class PickerController extends ChangeNotifier {
  final int length;
  final List<FixedExtentScrollController> scrollControllers;

  PickerController({
    @required this.length,
    List<FixedExtentScrollController> scrollControllers,
  })  : assert(scrollControllers == null || scrollControllers.length == length),
        scrollControllers = scrollControllers ??
            List.filled(length, 0)
                .map((e) => FixedExtentScrollController(initialItem: e))
                .toList(growable: false);

  @override
  void dispose() {
    scrollControllers.forEach((item) => item.dispose());
    super.dispose();
  }

  List<int> selectedItems() {
    return scrollControllers.map((e) {
      try {
        return e.selectedItem;
      } catch (_) {
        return e.initialItem;
      }
    }).toList(growable: false);
  }
}

class PickerSection extends StatelessWidget {
  final Key key;
  final FixedExtentScrollController controller;
  final ValueChanged<int> changed;
  final int count;
  final IndexedWidgetBuilder itemBuilder;
  final double itemExtent;
  final double diameterRatio;
  final double offAxisFraction;
  final bool useMagnifier;
  final double magnification;
  final double squeeze;

  PickerSection({
    this.key,
    this.controller,
    this.changed,
    this.count,
    this.itemBuilder,
    this.itemExtent,
    this.diameterRatio,
    this.offAxisFraction,
    this.useMagnifier,
    this.magnification,
    this.squeeze,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoPicker.builder(
      itemExtent: itemExtent ?? _kItemExtent,
      diameterRatio: diameterRatio ?? _kDiameterRatio,
      offAxisFraction: offAxisFraction ?? 0.0,
      useMagnifier: useMagnifier ?? _kUseMagnifier,
      magnification: magnification ?? _kMagnification,
      squeeze: squeeze ?? _kSqueeze,
      scrollController: controller,
      childCount: count == 0 ? 1 : count,
      onSelectedItemChanged: (index) => changed(index),
      itemBuilder: (context, index) {
        if (count == 0) {
          return const Center();
        }
        return Center(child: itemBuilder(context, index));
      },
    );
  }
}

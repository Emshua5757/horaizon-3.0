import 'package:flutter/material.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/primitives/sdui_progress_bar.dart';
import 'package:client_flutter/sdui/primitives/sdui_shimmer_loader.dart';
import 'package:client_flutter/sdui/primitives/sdui_checkbox.dart';
import 'package:client_flutter/sdui/primitives/sdui_toggle.dart';
import 'package:client_flutter/sdui/primitives/sdui_radio.dart';
import 'package:client_flutter/sdui/primitives/sdui_button.dart';
import 'package:client_flutter/sdui/primitives/sdui_chip.dart';
import 'package:client_flutter/sdui/primitives/sdui_slider.dart';
import 'package:client_flutter/sdui/primitives/sdui_ordinal_slider.dart';
import 'package:client_flutter/sdui/primitives/sdui_table.dart';
import 'package:client_flutter/sdui/primitives/sdui_text_input.dart';
import 'package:client_flutter/sdui/primitives/sdui_markdown_editor.dart';
import 'package:client_flutter/sdui/primitives/sdui_code_editor.dart';
import 'package:client_flutter/sdui/primitives/sdui_list_editor.dart';
import 'package:client_flutter/sdui/primitives/sdui_container.dart';
import 'package:client_flutter/sdui/primitives/sdui_list_view.dart';
import 'package:client_flutter/sdui/primitives/sdui_grid_view.dart';
import 'package:client_flutter/sdui/primitives/sdui_heatmap.dart';
import 'package:client_flutter/sdui/primitives/sdui_map.dart';
import 'package:client_flutter/sdui/primitives/sdui_drawing_pad.dart';
import 'package:client_flutter/sdui/primitives/sdui_audio.dart';
import 'package:client_flutter/sdui/primitives/sdui_video.dart';
import 'package:client_flutter/sdui/primitives/sdui_image.dart';
import 'package:client_flutter/sdui/primitives/sdui_stl_viewer.dart';
import 'package:client_flutter/sdui/primitives/sdui_chart.dart';
import 'package:client_flutter/sdui/primitives/sdui_gauge.dart';
import 'package:client_flutter/sdui/primitives/sdui_timeline.dart';
import 'package:client_flutter/sdui/primitives/sdui_module_card.dart';
import 'package:client_flutter/sdui/primitives/sdui_divider.dart';
import 'package:client_flutter/sdui/primitives/sdui_spacer.dart';
import 'package:client_flutter/sdui/primitives/sdui_expansion_tile.dart';
import 'package:client_flutter/sdui/primitives/sdui_wrap.dart';
import 'package:client_flutter/sdui/primitives/sdui_date_picker.dart';
import 'package:client_flutter/sdui/primitives/sdui_time_picker.dart';
import 'package:client_flutter/sdui/primitives/sdui_dropdown.dart';
import 'package:client_flutter/sdui/primitives/sdui_terminal.dart';
import 'package:client_flutter/sdui/primitives/sdui_document_viewer.dart';
import 'package:client_flutter/sdui/primitives/sdui_carousel.dart';
import 'package:client_flutter/sdui/primitives/sdui_html_viewer.dart';


typedef SduiWidgetBuilder = Widget Function(SduiNode node, SduiEventDispatcher dispatcher, BuildContext context);

/// The O(1) jump table that maps integer Type IDs to Flutter rendering functions.
class SduiTypeRegistry {
  static final Map<int, SduiWidgetBuilder> _registry = {
    1: (node, dispatcher, context) => SduiMarkdownEditor(node: node, dispatcher: dispatcher),
    2: (node, dispatcher, context) => SduiCodeEditor(node: node, dispatcher: dispatcher),
    3: (node, dispatcher, context) => SduiButton(node: node, dispatcher: dispatcher),
    4: (node, dispatcher, context) => SduiCheckbox(node: node, dispatcher: dispatcher),
    5: (node, dispatcher, context) => SduiChip(node: node, dispatcher: dispatcher),
    6: (node, dispatcher, context) => SduiContainer(node: node, dispatcher: dispatcher),
    7: (node, dispatcher, context) => SduiGridView(node: node, dispatcher: dispatcher),
    8: (node, dispatcher, context) => SduiListEditor(node: node, dispatcher: dispatcher),
    9: (node, dispatcher, context) => SduiListView(node: node, dispatcher: dispatcher),
    10: (node, dispatcher, context) => SduiOrdinalSlider(node: node, dispatcher: dispatcher),
    11: (node, dispatcher, context) => SduiSlider(node: node, dispatcher: dispatcher),
    12: (node, dispatcher, context) => SduiProgressBar(node: node, dispatcher: dispatcher),
    13: (node, dispatcher, context) => SduiRadio(node: node, dispatcher: dispatcher),
    14: (node, dispatcher, context) => SduiShimmerLoader(node: node, dispatcher: dispatcher),
    15: (node, dispatcher, context) => SduiTable(node: node, dispatcher: dispatcher),
    16: (node, dispatcher, context) => SduiTextInput(node: node, dispatcher: dispatcher),
    17: (node, dispatcher, context) => SduiToggle(node: node, dispatcher: dispatcher),
    18: (node, dispatcher, context) => SduiTerminal(node: node, dispatcher: dispatcher),
    19: (node, dispatcher, context) => SduiHeatmap(node: node, dispatcher: dispatcher),
    20: (node, dispatcher, context) => SduiMap(node: node, dispatcher: dispatcher),
    21: (node, dispatcher, context) => SduiDrawingPad(node: node, dispatcher: dispatcher),
    22: (node, dispatcher, context) => SduiAudio(node: node, dispatcher: dispatcher),
    23: (node, dispatcher, context) => SduiVideo(node: node, dispatcher: dispatcher),
    24: (node, dispatcher, context) => SduiImage(node: node, dispatcher: dispatcher),
    25: (node, dispatcher, context) => SduiStlViewer(node: node, dispatcher: dispatcher),
    26: (node, dispatcher, context) => SduiChart(node: node, dispatcher: dispatcher),
    27: (node, dispatcher, context) => SduiGauge(node: node, dispatcher: dispatcher),
    28: (node, dispatcher, context) => SduiTimeline(node: node, dispatcher: dispatcher),
    29: (node, dispatcher, context) => SduiDocumentViewer(node: node, dispatcher: dispatcher),
    30: (node, dispatcher, context) => SduiCarousel(node: node, dispatcher: dispatcher),
    31: (node, dispatcher, context) => SduiHtmlViewer(node: node, dispatcher: dispatcher),
    32: (node, dispatcher, context) => SduiDatePicker(node: node, dispatcher: dispatcher),
    33: (node, dispatcher, context) => SduiTimePicker(node: node, dispatcher: dispatcher),
    34: (node, dispatcher, context) => SduiDivider(node: node, dispatcher: dispatcher),
    35: (node, dispatcher, context) => SduiSpacer(node: node, dispatcher: dispatcher),
    36: (node, dispatcher, context) => SduiExpansionTile(node: node, dispatcher: dispatcher),
    37: (node, dispatcher, context) => SduiWrap(node: node, dispatcher: dispatcher),
    38: (node, dispatcher, context) => SduiDropdown(node: node, dispatcher: dispatcher),
    39: (node, dispatcher, context) => SduiModuleCard(node: node, dispatcher: dispatcher),
  };

  static void register(int typeId, SduiWidgetBuilder builder) {
    _registry[typeId] = builder;
  }

  static Widget buildNode(SduiNode node, SduiEventDispatcher dispatcher, BuildContext context) {
    final builder = _registry[node.typeId];
    if (builder != null) {
      return builder(node, dispatcher, context);
    }
    
    // ZLS/Graceful Fallback UI for unknown backend node types
    return Container(
      padding: const EdgeInsets.all(8),
      color: const Color(0x33F44336), // Colors.red with 20% opacity
      child: Text(
        'Missing Widget: typeId ${node.typeId}',
        style: const TextStyle(color: Colors.red, fontSize: 10),
      ),
    );
  }
}

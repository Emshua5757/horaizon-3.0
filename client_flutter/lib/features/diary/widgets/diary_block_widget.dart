import 'package:flutter/material.dart';
import '../models/diary_block_dto.dart';
import 'blocks/diary_markdown_block.dart';
import 'blocks/diary_checkbox_block.dart';
import 'blocks/diary_divider_block.dart';
import 'blocks/diary_text_input_block.dart';
import 'blocks/diary_toggle_block.dart';
import 'blocks/diary_progress_block.dart';
import 'blocks/diary_image_block.dart';
import 'blocks/diary_code_block.dart';
import 'blocks/diary_button_block.dart';
import 'blocks/diary_slider_block.dart';
import 'blocks/diary_table_block.dart';
import 'blocks/diary_date_picker_block.dart';
import 'blocks/diary_time_picker_block.dart';
import 'blocks/diary_chart_block.dart';
import 'blocks/diary_certification_block.dart';
import 'blocks/diary_chip_block.dart';
import 'blocks/diary_list_editor_block.dart';
import 'blocks/diary_drawing_block.dart';
import 'blocks/diary_heatmap_block.dart';
import 'blocks/diary_document_block.dart';
import 'blocks/diary_stub_block.dart';

/// Central widget dispatcher mapping every single block.blockType string to its concrete Flutter widget.
/// Zero SDUI blueprint/orchestrator dependency — 100% native Flutter Dart widgets.
class DiaryBlockWidget extends StatelessWidget {
  final DiaryBlockDto block;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onDelete;

  const DiaryBlockWidget({
    super.key,
    required this.block,
    this.onChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    switch (block.blockType) {
      case 'markdown':
        return DiaryMarkdownBlock(block: block, onChanged: onChanged, onDelete: onDelete);
      case 'checkbox':
        return DiaryCheckboxBlock(block: block, onChanged: onChanged, onDelete: onDelete);
      case 'divider':
        return DiaryDividerBlock(block: block, onChanged: onChanged, onDelete: onDelete);
      case 'spacer':
        return DiarySpacerBlock(block: block, onChanged: onChanged, onDelete: onDelete);
      case 'text_input':
        return DiaryTextInputBlock(block: block, onChanged: onChanged, onDelete: onDelete);
      case 'toggle':
        return DiaryToggleBlock(block: block, onChanged: onChanged, onDelete: onDelete);
      case 'progress':
        return DiaryProgressBlock(block: block, onChanged: onChanged, onDelete: onDelete);
      case 'image':
        return DiaryImageBlock(block: block, onChanged: onChanged, onDelete: onDelete);
      case 'code':
        return DiaryCodeBlock(block: block, onChanged: onChanged, onDelete: onDelete);
      case 'button':
        return DiaryButtonBlock(block: block, onChanged: onChanged, onDelete: onDelete);
      case 'slider':
        return DiarySliderBlock(block: block, onChanged: onChanged, onDelete: onDelete);
      case 'table':
        return DiaryTableBlock(block: block, onChanged: onChanged, onDelete: onDelete);
      case 'date_picker':
        return DiaryDatePickerBlock(block: block, onChanged: onChanged, onDelete: onDelete);
      case 'time_picker':
        return DiaryTimePickerBlock(block: block, onChanged: onChanged, onDelete: onDelete);
      case 'chart':
        return DiaryChartBlock(block: block, onChanged: onChanged, onDelete: onDelete);
      case 'certification':
        return DiaryCertificationBlock(block: block, onChanged: onChanged, onDelete: onDelete);

      // Group A (Controls & Content)
      case 'chip':
        return DiaryChipBlock(block: block, onChanged: onChanged, onDelete: onDelete);
      case 'container':
        return DiaryContainerBlock(block: block, onChanged: onChanged, onDelete: onDelete);
      case 'grid':
        return DiaryGridBlock(block: block, onChanged: onChanged, onDelete: onDelete);
      case 'list_editor':
        return DiaryListEditorBlock(block: block, onChanged: onChanged, onDelete: onDelete);
      case 'list_view':
        return DiaryListViewBlock(block: block, onChanged: onChanged, onDelete: onDelete);
      case 'ordinal_slider':
        return DiaryOrdinalSliderBlock(block: block, onChanged: onChanged, onDelete: onDelete);
      case 'radio':
        return DiaryRadioBlock(block: block, onChanged: onChanged, onDelete: onDelete);
      case 'shimmer':
        return DiaryShimmerBlock(block: block, onChanged: onChanged, onDelete: onDelete);

      // Group B (Interactive & Special)
      case 'heatmap':
        return DiaryHeatmapBlock(block: block, onChanged: onChanged, onDelete: onDelete);
      case 'map':
        return DiaryMapBlock(block: block, onChanged: onChanged, onDelete: onDelete);
      case 'drawing':
        return DiaryDrawingBlock(block: block, onChanged: onChanged, onDelete: onDelete);
      case 'audio':
        return DiaryAudioBlock(block: block, onChanged: onChanged, onDelete: onDelete);
      case 'video':
        return DiaryVideoBlock(block: block, onChanged: onChanged, onDelete: onDelete);
      case 'stl':
        return DiaryStlBlock(block: block, onChanged: onChanged, onDelete: onDelete);
      case 'gauge':
        return DiaryGaugeBlock(block: block, onChanged: onChanged, onDelete: onDelete);
      case 'timeline':
        return DiaryTimelineBlock(block: block, onChanged: onChanged, onDelete: onDelete);

      // Group C (Viewers & Layouts)
      case 'document':
        return DiaryDocumentBlock(block: block, onChanged: onChanged, onDelete: onDelete);
      case 'carousel':
        return DiaryCarouselBlock(block: block, onChanged: onChanged, onDelete: onDelete);
      case 'html':
        return DiaryHtmlBlock(block: block, onChanged: onChanged, onDelete: onDelete);
      case 'expansion':
        return DiaryExpansionBlock(block: block, onChanged: onChanged, onDelete: onDelete);
      case 'wrap':
        return DiaryWrapBlock(block: block, onChanged: onChanged, onDelete: onDelete);

      default:
        return DiaryStubBlock(block: block, onChanged: onChanged, onDelete: onDelete);
    }
  }
}

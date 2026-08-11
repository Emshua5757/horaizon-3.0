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
import 'blocks/diary_stub_block.dart';

/// Central widget dispatcher mapping block.blockType string to a concrete Flutter widget.
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
      default:
        return DiaryStubBlock(block: block, onChanged: onChanged, onDelete: onDelete);
    }
  }
}

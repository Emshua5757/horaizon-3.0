import 'package:flutter/material.dart';

/// O(1) HashMap registry for all icon names used in SDUI blueprints.
///
/// Covers: UI chrome, navigation, block picker (all 31 types),
/// module cards, status indicators, and sentiment icons.
/// Fallback: Icons.help_outline_rounded (the `?` you see when a name is missing).
///
/// To add a new icon: append an entry here and reference it by name in blueprints.
/// Do NOT use dynamic resolution — all names must be compile-time constants.
class SduiIconRegistry {
  static final Map<String, IconData> _icons = {
    // ── UI Chrome / Navigation ─────────────────────────────────────────────
    'dashboard':         Icons.dashboard_outlined,
    'settings':          Icons.settings_outlined,
    'person':            Icons.person_outlined,
    'home':              Icons.home_outlined,
    'chat':              Icons.chat_bubble_outline,
    'calendar':          Icons.calendar_today_outlined,
    'calendar_today':    Icons.calendar_today_outlined,
    'edit':              Icons.edit_outlined,
    'delete':            Icons.delete_outline,
    'add':               Icons.add,
    'close':             Icons.close,
    'check':             Icons.check,
    'menu':              Icons.menu,
    'search':            Icons.search,
    'arrow_forward':     Icons.arrow_forward_rounded,
    'arrow_back':        Icons.arrow_back_rounded,
    'drag_handle':       Icons.drag_handle_rounded,
    'more_vert':         Icons.more_vert,
    'more_horiz':        Icons.more_horiz,
    'folder':            Icons.folder_outlined,
    'key':               Icons.vpn_key_outlined,
    'lock':              Icons.lock_outline,
    'lock_open':         Icons.lock_open_outlined,
    'bolt':              Icons.bolt,
    'bolt_outlined':     Icons.bolt_outlined,

    // ── Status / Feedback ──────────────────────────────────────────────────
    'warning':           Icons.warning_amber_outlined,
    'error':             Icons.error_outline,
    'info':              Icons.info_outline,
    'help_outline':      Icons.help_outline_rounded,
    'check_circle':      Icons.check_circle_outline_rounded,
    'pending':           Icons.pending_outlined,
    'star':              Icons.star_border,
    'star_filled':       Icons.star_rounded,
    'heart':             Icons.favorite_border,
    'favorite':          Icons.favorite_outline,
    'trending_up':       Icons.trending_up,
    'analytics':         Icons.analytics_outlined,

    // ── Sentiment / Mood ───────────────────────────────────────────────────
    'sentiment_satisfied':    Icons.sentiment_satisfied_alt_rounded,
    'sentiment_neutral':      Icons.sentiment_neutral_rounded,
    'sentiment_dissatisfied': Icons.sentiment_dissatisfied_rounded,
    'mood':                   Icons.mood,
    'mood_bad':               Icons.mood_bad,
    'psychology':             Icons.psychology,
    'self_improvement':       Icons.self_improvement,

    // ── Block Picker: Text ─────────────────────────────────────────────────
    'title':             Icons.title,
    'text_fields':       Icons.text_fields,
    'format_quote':      Icons.format_quote,
    'subtitles':         Icons.subtitles_outlined,
    'code':              Icons.code,
    'notes':             Icons.notes,
    'article':           Icons.article_outlined,

    // ── Block Picker: Lists ────────────────────────────────────────────────
    'check_box':                  Icons.check_box_outlined,
    'check_box_outline_blank':    Icons.check_box_outline_blank,
    'format_list_bulleted':       Icons.format_list_bulleted,
    'format_list_numbered':       Icons.format_list_numbered,
    'label':                      Icons.label_outlined,
    'expand_more':                Icons.expand_more,

    // ── Block Picker: Dividers / Layout ────────────────────────────────────
    'horizontal_rule':   Icons.horizontal_rule,
    'space_bar':         Icons.space_bar,

    // ── Block Picker: Media ────────────────────────────────────────────────
    'image':             Icons.image_outlined,
    'mic':               Icons.mic_outlined,
    'videocam':          Icons.videocam_outlined,
    'gesture':           Icons.gesture,
    'picture_as_pdf':    Icons.picture_as_pdf_outlined,
    'html':              Icons.html,

    // ── Block Picker: Data / Metrics ──────────────────────────────────────
    'table_chart':       Icons.table_chart_outlined,
    'bar_chart':         Icons.bar_chart,
    'location_on':       Icons.location_on_outlined,
    'linear_scale':      Icons.linear_scale,

    // ── Block Picker: Time / Date ─────────────────────────────────────────
    'schedule':          Icons.schedule_outlined,
    'timer':             Icons.timer_outlined,

    // ── Block Picker: Input / Form ────────────────────────────────────────
    'radio_button_checked':       Icons.radio_button_checked,
    'arrow_drop_down_circle':     Icons.arrow_drop_down_circle_outlined,

    // ── Block Picker: Trackers ─────────────────────────────────────────────
    'flag':              Icons.flag_outlined,
    'checklist':         Icons.checklist_rtl,

    // ── Module Card / Governor ─────────────────────────────────────────────
    'memory':            Icons.memory_outlined,
    'cloud':             Icons.cloud_outlined,
    'cloud_upload':      Icons.cloud_upload_outlined,
    'network_check':     Icons.network_check_outlined,
    'developer_board':   Icons.developer_board_outlined,
    'speed':             Icons.speed_outlined,
    'thermostat':        Icons.thermostat_outlined,

    // ── AI / JBC ──────────────────────────────────────────────────────────
    'auto_awesome':      Icons.auto_awesome,
    'smart_toy':         Icons.smart_toy_outlined,
    'hub':               Icons.hub_outlined,
  };

  /// Resolves a string icon name in O(1) time.
  /// Falls back to help_outline_rounded if the name is missing.
  /// Add missing names to the map above rather than handling them here.
  static IconData resolve(String? name) {
    if (name == null) return Icons.help_outline_rounded;
    return _icons[name] ?? Icons.help_outline_rounded;
  }

  static bool contains(String name) => _icons.containsKey(name);
}

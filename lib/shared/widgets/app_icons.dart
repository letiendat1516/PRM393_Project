import 'package:flutter/material.dart';

/// Maps the ~45 icon names of frontend/src/components/ui/Icon.jsx to
/// Material icons so data files (features.js, workflow.js, stats.js) can keep
/// their string icon keys.
class AppIcons {
  const AppIcons._();

  static const Map<String, IconData> _map = {
    'search': Icons.search,
    'mapPin': Icons.place_outlined,
    'briefcase': Icons.work_outline,
    'clock': Icons.schedule_outlined,
    'bookmark': Icons.bookmark_border,
    'bookmarkFill': Icons.bookmark,
    'arrowRight': Icons.arrow_forward,
    'arrowLeft': Icons.arrow_back,
    'arrowUpRight': Icons.north_east,
    'check': Icons.check,
    'checkCircle': Icons.check_circle_outline,
    'star': Icons.star,
    'fileText': Icons.description_outlined,
    'sparkles': Icons.auto_awesome,
    'users': Icons.people_outline,
    'building': Icons.business_outlined,
    'trendingUp': Icons.trending_up,
    'wallet': Icons.account_balance_wallet_outlined,
    'home': Icons.home_outlined,
    'globe': Icons.language,
    'quote': Icons.format_quote,
    'upload': Icons.upload_file_outlined,
    'chevronDown': Icons.keyboard_arrow_down,
    'filter': Icons.filter_list,
    'calendar': Icons.calendar_today_outlined,
    'x': Icons.close,
    'menu': Icons.menu,
    'close': Icons.close,
    'target': Icons.gps_fixed,
    'bolt': Icons.bolt,
    'network': Icons.hub_outlined,
    'shield': Icons.shield_outlined,
    'mail': Icons.mail_outline,
    'phone': Icons.phone_outlined,
    'send': Icons.send_outlined,
    'linkedin': Icons.work_outline,
    'facebook': Icons.facebook,
    'youtube': Icons.ondemand_video,
    'settings': Icons.settings_outlined,
    'user': Icons.person_outline,
    'logout': Icons.logout,
    'bell': Icons.notifications_none,
    'chat': Icons.chat_bubble_outline,
    'eye': Icons.visibility_outlined,
    'eyeOff': Icons.visibility_off_outlined,
    'refresh': Icons.refresh,
    'trash': Icons.delete_outline,
    'edit': Icons.edit_outlined,
    'lock': Icons.lock_outline,
    'unlock': Icons.lock_open_outlined,
    'download': Icons.download_outlined,
    'graduation': Icons.school_outlined,
    'money': Icons.payments_outlined,
    'info': Icons.info_outline,
    'warning': Icons.warning_amber_outlined,
    'chart': Icons.bar_chart_outlined,
  };

  static IconData of(String name, [IconData fallback = Icons.circle_outlined]) =>
      _map[name] ?? fallback;
}

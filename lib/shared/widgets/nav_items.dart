import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/router/routes.dart';
import '../../core/utils/enums.dart';

/// Navigation copy from frontend/src/components/navbar/Navbar.jsx so the
/// desktop navbar, mobile drawer and account menu share one source.
class NavItem {
  const NavItem(this.label, this.route, {this.icon, this.danger = false});
  final String label;
  final String route;
  final IconData? icon;
  final bool danger;
}

class NavItems {
  const NavItems._();

  /// Public links (hash links open the homepage scrolled to a section).
  static const List<NavItem> public = [
    NavItem('Việc làm', AppRoutes.jobs, icon: Icons.work_outline),
    NavItem('Đề xuất', AppRoutes.recommended, icon: Icons.auto_awesome_outlined),
    NavItem('Công ty', '/?section=${AppConfig.sectionTopCompanies}', icon: Icons.business_outlined),
    NavItem('Hồ sơ & AI', '/?section=${AppConfig.sectionAiAnalysis}', icon: Icons.description_outlined),
    NavItem('Cẩm nang nghề nghiệp', '/?section=${AppConfig.sectionCareerResources}',
        icon: Icons.menu_book_outlined),
  ];

  static List<NavItem> accountMenu(UserRole role) =>
      [for (final g in accountMenuGrouped(role)) ...g.items];

  /// Role-aware menu grouped into section headers for the mobile drawer.
  /// The order of groups reflects usage frequency (dashboard first, personal
  /// settings last). Flat [accountMenu] stays for the desktop dropdown.
  static List<NavSection> accountMenuGrouped(UserRole role) => switch (role) {
        UserRole.jobSeeker => const [
            NavSection('Hồ sơ', [
              NavItem('Hồ sơ cá nhân', AppRoutes.resumeProfile,
                  icon: Icons.person_outline),
            ]),
            NavSection('Ứng tuyển', [
              NavItem('Hồ sơ đã ứng tuyển', AppRoutes.myApplications,
                  icon: Icons.description_outlined),
              NavItem('Việc đã lưu', AppRoutes.savedJobs,
                  icon: Icons.bookmarks_outlined),
            ]),
            NavSection('AI matching', [
              NavItem('Kết quả chấm điểm đã lưu', AppRoutes.recommended,
                  icon: Icons.bookmark_border),
            ]),
            NavSection('Giao tiếp', [
              NavItem('Tin nhắn', AppRoutes.chats,
                  icon: Icons.chat_bubble_outline),
              NavItem('Thông báo', AppRoutes.notifications,
                  icon: Icons.notifications_none),
            ]),
            NavSection('Cài đặt', [
              NavItem('Cài đặt', AppRoutes.settings,
                  icon: Icons.settings_outlined),
            ]),
          ],
        UserRole.employer => const [
            NavSection('Tổng quan', [
              NavItem('Tổng quan', AppRoutes.employerDashboard,
                  icon: Icons.dashboard_outlined),
            ]),
            NavSection('Công ty', [
              NavItem('Hồ sơ công ty', AppRoutes.employerCompanyProfile,
                  icon: Icons.business_outlined),
            ]),
            NavSection('Tuyển dụng', [
              NavItem('Quản lý tin tuyển dụng', AppRoutes.employerJobs,
                  icon: Icons.list_alt_outlined),
              NavItem('Đăng tin tuyển dụng', AppRoutes.createJob,
                  icon: Icons.add_box_outlined),
              NavItem('Hồ sơ ứng tuyển', AppRoutes.employerApplications,
                  icon: Icons.inbox_outlined),
            ]),
            NavSection('Giao tiếp', [
              NavItem('Tin nhắn', AppRoutes.chats,
                  icon: Icons.chat_bubble_outline),
              NavItem('Thông báo', AppRoutes.notifications,
                  icon: Icons.notifications_none),
            ]),
            NavSection('Cài đặt', [
              NavItem('Cài đặt', AppRoutes.settings,
                  icon: Icons.settings_outlined),
            ]),
          ],
        UserRole.admin => const [
            NavSection('Tổng quan', [
              NavItem('Tổng quan', AppRoutes.adminDashboard,
                  icon: Icons.dashboard_outlined),
            ]),
            NavSection('Người dùng & Doanh nghiệp', [
              NavItem('Quản lý người dùng', AppRoutes.adminUsers,
                  icon: Icons.people_outline),
              NavItem('Quản lý nhà tuyển dụng', AppRoutes.adminEmployers,
                  icon: Icons.business_outlined),
            ]),
            NavSection('Nội dung', [
              NavItem('Duyệt tin tuyển dụng', AppRoutes.adminPendingJobs,
                  icon: Icons.fact_check_outlined),
              NavItem('Hồ sơ ứng tuyển', AppRoutes.employerApplications,
                  icon: Icons.inbox_outlined),
              NavItem('Quản lý ngành nghề và kỹ năng', AppRoutes.adminCatalog,
                  icon: Icons.category_outlined),
            ]),
            NavSection('AI', [
              NavItem('Thống kê AI Logs', AppRoutes.adminAiStats,
                  icon: Icons.bar_chart_outlined),
              NavItem('AI Prompt Logs', AppRoutes.adminAiLogs,
                  icon: Icons.auto_awesome_outlined),
            ]),
            NavSection('Hệ thống', [
              NavItem('Cấu hình hệ thống', AppRoutes.adminSystemConfig,
                  icon: Icons.settings_outlined),
            ]),
            NavSection('Cá nhân', [
              NavItem('Thông báo', AppRoutes.notifications,
                  icon: Icons.notifications_none),
            ]),
          ],
      };

  /// redirectByRole.js: admin → /admin/users, others → '/'.
  static String homeFor(UserRole? role) =>
      role == UserRole.admin ? AppRoutes.adminUsers : AppRoutes.home;
}

/// A labelled group of related [NavItem]s used by [MobileDrawer].
class NavSection {
  const NavSection(this.title, this.items);
  final String title;
  final List<NavItem> items;
}

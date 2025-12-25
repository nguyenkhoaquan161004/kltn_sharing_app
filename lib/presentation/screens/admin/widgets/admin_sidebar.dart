import 'package:flutter/material.dart';

class AdminSidebar extends StatelessWidget {
  final String currentRoute;
  final VoidCallback onLogout;

  const AdminSidebar({
    Key? key,
    required this.currentRoute,
    required this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue[600],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 32,
                    color: Colors.blue[600],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Shario Management',
                  style: TextStyle(
                    color: Colors.blue[100],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          _buildMenuItem(
            context,
            icon: Icons.dashboard,
            label: 'Dashboard',
            route: '/admin-dashboard',
          ),
          _buildMenuItem(
            context,
            icon: Icons.people,
            label: 'Quản lý User',
            route: '/admin-users',
          ),
          _buildMenuItem(
            context,
            icon: Icons.category,
            label: 'Quản lý Category',
            route: '/admin-categories',
          ),
          _buildMenuItem(
            context,
            icon: Icons.star,
            label: 'Quản lý Danh hiệu',
            route: '/admin-badges',
          ),
          _buildMenuItem(
            context,
            icon: Icons.flag,
            label: 'Xử lý Report',
            route: '/admin-reports',
          ),
          _buildMenuItem(
            context,
            icon: Icons.bar_chart,
            label: 'Thống kê',
            route: '/admin-statistics',
          ),

          const Divider(margin: EdgeInsets.symmetric(vertical: 16)),

          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
  }) {
    final isSelected = currentRoute == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.blue[600] : Colors.grey[600],
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.blue[600] : Colors.black87,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.blue[50],
      onTap: () {
        Navigator.pop(context); // Close drawer
        if (route != currentRoute) {
          Navigator.of(context).pushNamed(route);
        }
      },
    );
  }
}

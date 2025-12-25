import 'package:flutter/material.dart';
import 'package:kltn_sharing_app/core/config/app_config.dart';
import 'package:kltn_sharing_app/data/services/admin/admin_api_service.dart';
import 'package:kltn_sharing_app/presentation/screens/admin/widgets/admin_sidebar.dart';

class AdminBadgesScreen extends StatefulWidget {
  const AdminBadgesScreen({Key? key}) : super(key: key);

  @override
  State<AdminBadgesScreen> createState() => _AdminBadgesScreenState();
}

class _AdminBadgesScreenState extends State<AdminBadgesScreen> {
  late AdminApiService _adminService;
  List<Map<String, dynamic>> _badges = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _adminService = AdminApiService(AppConfig.dioInstance);
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final badges = await _adminService.getAllBadges();
      setState(() {
        _badges = badges;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteBadge(String badgeId) async {
    try {
      await _adminService.deleteBadge(badgeId);
      await _loadBadges();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa danh hiệu thành công')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Danh hiệu'),
        backgroundColor: Colors.blue[600],
        actions: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () => _showCreateBadgeDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Thêm'),
              ),
            ),
          ),
        ],
      ),
      drawer: AdminSidebar(
        currentRoute: '/admin-badges',
        onLogout: () => Navigator.pushReplacementNamed(context, '/admin-login'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : _buildBadgeList(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[600]),
          const SizedBox(height: 16),
          Text(_errorMessage!),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadBadges,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeList() {
    if (_badges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.star_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Không có danh hiệu nào'),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: _badges.length,
      itemBuilder: (context, index) {
        final badge = _badges[index];
        return _buildBadgeCard(badge);
      },
    );
  }

  Widget _buildBadgeCard(Map<String, dynamic> badge) {
    final rarity = badge['rarity'] ?? 'COMMON';
    final rarityColor = _getRarityColor(rarity as String);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: rarityColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.star,
                color: rarityColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              badge['name'] ?? 'N/A',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              badge['description'] ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: rarityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                rarity,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: rarityColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (badge['pointsRequired'] != null)
              Text(
                '${badge['pointsRequired']} điểm',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _showEditBadgeDialog(badge),
                  iconSize: 18,
                ),
                IconButton(
                  icon: Icon(Icons.delete, size: 18, color: Colors.red[600]),
                  onPressed: () =>
                      _confirmDelete(badge['id'] ?? badge['badgeId']),
                  iconSize: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateBadgeDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final pointsController = TextEditingController();
    String selectedRarity = 'COMMON';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Thêm Danh hiệu'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: 'Tên danh hiệu',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    hintText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pointsController,
                  decoration: const InputDecoration(
                    hintText: 'Điểm yêu cầu',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                const Text('Độ hiếm:'),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: selectedRarity,
                  isExpanded: true,
                  items: ['COMMON', 'RARE', 'EPIC', 'LEGENDARY']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => selectedRarity = value ?? 'COMMON'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _adminService.createBadge(
                    name: nameController.text,
                    description: descriptionController.text,
                    pointsRequired:
                        int.tryParse(pointsController.text) ?? 0,
                    rarity: selectedRarity,
                  );
                  Navigator.pop(context);
                  await _loadBadges();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thêm danh hiệu thành công')),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: ${e.toString()}')),
                  );
                }
              },
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBadgeDialog(Map<String, dynamic> badge) {
    final nameController = TextEditingController(text: badge['name'] ?? '');
    final descriptionController =
        TextEditingController(text: badge['description'] ?? '');
    final pointsController =
        TextEditingController(text: badge['pointsRequired']?.toString() ?? '');
    String selectedRarity = badge['rarity'] ?? 'COMMON';
    final badgeId = badge['id'] ?? badge['badgeId'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Chỉnh sửa Danh hiệu'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: 'Tên danh hiệu',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    hintText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pointsController,
                  decoration: const InputDecoration(
                    hintText: 'Điểm yêu cầu',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                const Text('Độ hiếm:'),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: selectedRarity,
                  isExpanded: true,
                  items: ['COMMON', 'RARE', 'EPIC', 'LEGENDARY']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => selectedRarity = value ?? 'COMMON'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _adminService.updateBadge(
                    badgeId,
                    name: nameController.text,
                    description: descriptionController.text,
                    pointsRequired:
                        int.tryParse(pointsController.text) ?? 0,
                    rarity: selectedRarity,
                  );
                  Navigator.pop(context);
                  await _loadBadges();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Cập nhật danh hiệu thành công')),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: ${e.toString()}')),
                  );
                }
              },
              child: const Text('Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'RARE':
        return Colors.blue;
      case 'EPIC':
        return Colors.purple;
      case 'LEGENDARY':
        return Colors.amber;
      case 'COMMON':
      default:
        return Colors.green;
    }
  }

  void _confirmDelete(String badgeId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa Danh hiệu'),
        content: const Text(
            'Bạn chắc chắn muốn xóa danh hiệu này? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteBadge(badgeId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

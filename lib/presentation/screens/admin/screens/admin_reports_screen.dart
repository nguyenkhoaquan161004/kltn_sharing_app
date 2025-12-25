import 'package:flutter/material.dart';
import 'package:kltn_sharing_app/presentation/screens/admin/widgets/admin_sidebar.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({Key? key}) : super(key: key);

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final List<Map<String, dynamic>> _reports = [
    {
      'id': 'RPT001',
      'type': 'Spam',
      'reason': 'Nội dung spam',
      'reporter': 'user123',
      'target': 'user456',
      'status': 'Chờ xử lý',
      'date': '12/26',
    },
    {
      'id': 'RPT002',
      'type': 'Inappropriate',
      'reason': 'Nội dung không phù hợp',
      'reporter': 'user789',
      'target': 'user101',
      'status': 'Đã xử lý',
      'date': '12/25',
    },
    {
      'id': 'RPT003',
      'type': 'Scam',
      'reason': 'Lừa đảo',
      'reporter': 'user202',
      'target': 'user303',
      'status': 'Chờ xử lý',
      'date': '12/24',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xử lý Report'),
        backgroundColor: Colors.blue[600],
      ),
      drawer: AdminSidebar(
        currentRoute: '/admin-reports',
        onLogout: () => Navigator.pushReplacementNamed(context, '/admin-login'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reports.length,
        itemBuilder: (context, index) {
          final report = _reports[index];
          return _buildReportCard(report);
        },
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final isResolved = report['status'] == 'Đã xử lý';
    final typeColor = _getTypeColor(report['type']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    report['type'],
                    style: TextStyle(
                      color: typeColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isResolved
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    report['status'],
                    style: TextStyle(
                      color: isResolved ? Colors.green[700] : Colors.orange[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'ID: ${report['id']}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lý do: ${report['reason']}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Người báo cáo', report['reporter']),
                  const SizedBox(height: 8),
                  _buildDetailRow('Người bị báo cáo', report['target']),
                  const SizedBox(height: 8),
                  _buildDetailRow('Ngày báo cáo', report['date']),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (!isResolved)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleApprove(report['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                      ),
                      child: const Text('Phê duyệt'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleReject(report['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                      ),
                      child: const Text('Từ chối'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Spam':
        return Colors.orange;
      case 'Inappropriate':
        return Colors.red;
      case 'Scam':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _handleApprove(String reportId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Report $reportId đã được phê duyệt')),
    );
  }

  void _handleReject(String reportId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Report $reportId đã bị từ chối')),
    );
  }
}

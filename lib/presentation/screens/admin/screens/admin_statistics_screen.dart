import 'package:flutter/material.dart';
import 'package:kltn_sharing_app/presentation/screens/admin/widgets/admin_sidebar.dart';

class AdminStatisticsScreen extends StatefulWidget {
  const AdminStatisticsScreen({Key? key}) : super(key: key);

  @override
  State<AdminStatisticsScreen> createState() => _AdminStatisticsScreenState();
}

class _AdminStatisticsScreenState extends State<AdminStatisticsScreen> {
  String _selectedMonth = 'Tháng ${DateTime.now().month}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê'),
        backgroundColor: Colors.blue[600],
      ),
      drawer: AdminSidebar(
        currentRoute: '/admin-statistics',
        onLogout: () => Navigator.pushReplacementNamed(context, '/admin-login'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('Chọn tháng:'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedMonth,
                        isExpanded: true,
                        items: List.generate(12, (index) {
                          final month = index + 1;
                          return DropdownMenuItem(
                            value: 'Tháng $month',
                            child: Text('Tháng $month'),
                          );
                        }),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedMonth = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Transaction Statistics
            const Text(
              'Thống kê giao dịch',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatBox(
                  title: 'Tổng giao dịch',
                  value: '1,234',
                  icon: Icons.swap_horiz,
                  color: Colors.blue,
                ),
                _buildStatBox(
                  title: 'Giao dịch thành công',
                  value: '1,180',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                _buildStatBox(
                  title: 'Giao dịch thất bại',
                  value: '54',
                  icon: Icons.cancel,
                  color: Colors.red,
                ),
                _buildStatBox(
                  title: 'Tỷ lệ thành công',
                  value: '95.6%',
                  icon: Icons.trending_up,
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Revenue Statistics
            const Text(
              'Thống kê doanh thu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatBox(
                  title: 'Tổng doanh thu',
                  value: '₫45.2M',
                  icon: Icons.attach_money,
                  color: Colors.amber,
                ),
                _buildStatBox(
                  title: 'TB/Giao dịch',
                  value: '₫36.7K',
                  icon: Icons.calculate,
                  color: Colors.orange,
                ),
                _buildStatBox(
                  title: 'Doanh thu tối cao',
                  value: '₫125.5K',
                  icon: Icons.trending_up,
                  color: Colors.green,
                ),
                _buildStatBox(
                  title: 'Doanh thu tối thấp',
                  value: '₫500',
                  icon: Icons.trending_down,
                  color: Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Charts
            const Text(
              'Biểu đồ chi tiết',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildChartPlaceholder(
              title: 'Giao dịch theo ngày',
              height: 250,
            ),
            const SizedBox(height: 16),
            _buildChartPlaceholder(
              title: 'Doanh thu theo ngày',
              height: 250,
            ),
            const SizedBox(height: 16),
            _buildChartPlaceholder(
              title: 'Tỷ lệ thành công/thất bại',
              height: 200,
            ),
            const SizedBox(height: 24),

            // Detailed Table
            const Text(
              'Chi tiết giao dịch',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildTransactionTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Icon(icon, color: color, size: 24),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartPlaceholder({
    required String title,
    required double height,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 48,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Biểu đồ sẽ hiển thị tại đây',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '(Sử dụng package fl_chart)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTable() {
    final transactions = [
      {'id': 'TXN001', 'amount': '₫45,000', 'status': 'Thành công', 'date': '12/26'},
      {'id': 'TXN002', 'amount': '₫32,500', 'status': 'Thành công', 'date': '12/25'},
      {'id': 'TXN003', 'amount': '₫58,000', 'status': 'Thành công', 'date': '12/25'},
      {'id': 'TXN004', 'amount': '₫1,200', 'status': 'Thất bại', 'date': '12/24'},
      {'id': 'TXN005', 'amount': '₫41,000', 'status': 'Thành công', 'date': '12/24'},
    ];

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Số tiền')),
            DataColumn(label: Text('Trạng thái')),
            DataColumn(label: Text('Ngày')),
          ],
          rows: transactions
              .map((txn) => DataRow(cells: [
                    DataCell(Text(txn['id']!)),
                    DataCell(Text(txn['amount']!)),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: txn['status'] == 'Thành công'
                              ? Colors.green[50]
                              : Colors.red[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          txn['status']!,
                          style: TextStyle(
                            color: txn['status'] == 'Thành công'
                                ? Colors.green[700]
                                : Colors.red[700],
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(txn['date']!)),
                  ]))
              .toList(),
        ),
      ),
    );
  }
}

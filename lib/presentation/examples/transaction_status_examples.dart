import 'package:flutter/material.dart';
import 'package:kltn_sharing_app/data/models/transaction_status.dart';
import 'package:kltn_sharing_app/data/models/transaction_status_helper.dart';

/// Example Usage of Transaction Status System

class TransactionDetailExample extends StatelessWidget {
  final transactionStatus = TransactionStatus.pending;

  const TransactionDetailExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Example 1: Simple Status Badge
            const Text('Status Badge:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TransactionStatusHelper.buildStatusBadge(transactionStatus),
            const SizedBox(height: 24),

            // Example 2: Compact Status Badge
            const Text('Compact Status Badge:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TransactionStatusHelper.buildStatusBadge(
              transactionStatus,
              compact: true,
            ),
            const SizedBox(height: 24),

            // Example 3: Status Description
            const Text('Status Description:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TransactionStatusHelper.getBackgroundColor(
                    transactionStatus),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                TransactionStatusHelper.getDescription(transactionStatus),
                style: TextStyle(
                  color: TransactionStatusHelper.getColor(transactionStatus),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Example 4: Timeline View
            const Text('Transaction Timeline:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTimelineExample(),
            const SizedBox(height: 24),

            // Example 5: Action Buttons Based on Status
            const Text('Available Actions:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildActionButtonsExample(),
            const SizedBox(height: 24),

            // Example 6: Status List
            const Text('All Transaction Statuses:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildStatusListExample(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineExample() {
    final allStatuses = [
      TransactionStatus.pending,
      TransactionStatus.accepted,
      TransactionStatus.inProgress,
      TransactionStatus.completed,
    ];

    final currentStatusIndex = allStatuses.indexOf(transactionStatus);

    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: allStatuses.length,
        separatorBuilder: (context, index) {
          if (index == allStatuses.length - 1) return SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Icon(
                index < currentStatusIndex ? Icons.check : Icons.arrow_right,
                color: index < currentStatusIndex ? Colors.green : Colors.grey,
              ),
            ),
          );
        },
        itemBuilder: (context, index) {
          final status = allStatuses[index];
          final isCompleted = index < currentStatusIndex;
          final isCurrent = index == currentStatusIndex;

          return SizedBox(
            width: 100,
            child: TransactionStatusHelper.buildTimelineStep(
              status,
              isCompleted: isCompleted,
              isCurrent: isCurrent,
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtonsExample() {
    // Get next possible statuses based on current status
    final nextStatuses =
        TransactionStatusHelper.getNextPossibleStatuses(transactionStatus);

    return Column(
      children: [
        // Cancel option
        if (TransactionStatusHelper.canCancelTransaction(transactionStatus))
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.block),
            label: const Text('Cancel Transaction'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),

        // Accept/Reject options
        if (TransactionStatusHelper.canAcceptRejectTransaction(
            transactionStatus)) ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.cancel),
                  label: const Text('Reject'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],

        // Start delivery
        if (TransactionStatusHelper.canStartDelivery(transactionStatus))
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.local_shipping),
            label: const Text('Start Delivery'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),

        // Complete transaction
        if (TransactionStatusHelper.canCompleteTransaction(transactionStatus))
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.done_all),
            label: const Text('Mark as Completed'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),

        if (nextStatuses.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'No actions available for this status',
              style: TextStyle(color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusListExample() {
    final allStatuses = TransactionStatus.values;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allStatuses.length,
      itemBuilder: (context, index) {
        final status = allStatuses[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TransactionStatusHelper.getBackgroundColor(status),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: TransactionStatusHelper.getColor(status),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  TransactionStatusHelper.getIcon(status),
                  color: TransactionStatusHelper.getColor(status),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TransactionStatusHelper.getLabel(status),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: TransactionStatusHelper.getColor(status),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Backend: ${status.toBackendString()}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (status.isFinalState())
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Final',
                      style: TextStyle(fontSize: 10, color: Colors.black54),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// More Usage Examples

// Example 1: Convert backend string to enum
void convertBackendStatus(String backendStatus) {
  final status = TransactionStatusExtension.fromBackendString(backendStatus);
  print('Backend: $backendStatus -> Enum: $status');
  // Output: Backend: PENDING -> Enum: TransactionStatus.pending
}

// Example 2: Check if transition is valid
void checkTransition(TransactionStatus from, TransactionStatus to) {
  if (from.canTransitionTo(to)) {
    print('Can transition from $from to $to');
  } else {
    print('Cannot transition from $from to $to');
  }
}

// Example 3: Get next possible statuses
void showNextStatuses(TransactionStatus current) {
  final nextStatuses = TransactionStatusHelper.getNextPossibleStatuses(current);
  for (final status in nextStatuses) {
    print('Next possible: ${status.getDisplayName()}');
  }
}

// Example 4: Build status dropdown
class StatusDropdownExample extends StatefulWidget {
  const StatusDropdownExample({super.key});

  @override
  State<StatusDropdownExample> createState() => _StatusDropdownExampleState();
}

class _StatusDropdownExampleState extends State<StatusDropdownExample> {
  late TransactionStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = TransactionStatus.pending;
  }

  @override
  Widget build(BuildContext context) {
    // Only show valid next statuses
    final nextStatuses =
        TransactionStatusHelper.getNextPossibleStatuses(_selectedStatus);

    return DropdownButton<TransactionStatus>(
      value: _selectedStatus,
      items: nextStatuses.map((status) {
        return DropdownMenuItem(
          value: status,
          child: Row(
            children: [
              Icon(TransactionStatusHelper.getIcon(status)),
              const SizedBox(width: 8),
              Text(TransactionStatusHelper.getLabel(status)),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedStatus = value);
        }
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_state.dart';
import '../../core/constants.dart';
import '../../core/sound_service.dart';
import '../../core/widgets/operator_badge.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _selectedStatus = 'ALL';

  void _copy(String text, String msg) {
    Clipboard.setData(ClipboardData(text: text));
    SoundService.playTap();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2), backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    final statuses = [
      {'id': 'ALL', 'name': app.isBn ? 'সকল' : 'All'},
      {'id': 'PENDING', 'name': app.isBn ? 'পেন্ডিং' : 'Pending'},
      {'id': 'PROCESSING', 'name': app.isBn ? 'প্রসেসিং' : 'Processing'},
      {'id': 'COMPLETED', 'name': app.isBn ? 'সফল' : 'Completed'},
      {'id': 'CANCELLED', 'name': app.isBn ? 'বাতিল' : 'Cancelled'},
    ];

    final filtered = app.orders.where((order) {
      if (_selectedStatus != 'ALL' && order.status.toUpperCase() != _selectedStatus) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          app.isBn ? 'আমার অর্ডারসমূহ' : 'My Orders',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: statuses.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, index) {
                  final st = statuses[index];
                  final isSelected = _selectedStatus == st['id'];

                  return InkWell(
                    onTap: () {
                      SoundService.playTap();
                      setState(() => _selectedStatus = st['id']!);
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.grey.shade300,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          st['name']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Orders List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => app.fetchOrders(),
              color: AppColors.primary,
              child: filtered.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                app.isBn ? 'কোন অর্ডার পাওয়া যায়নি' : 'No orders found',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, index) {
                        final order = filtered[index];
                        final dateStr = order.createdAt.isNotEmpty
                            ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.tryParse(order.createdAt) ?? DateTime.now())
                            : 'Recently';

                        Color statusColor;
                        Color statusBg;
                        switch (order.status.toUpperCase()) {
                          case 'COMPLETED':
                            statusColor = AppColors.success;
                            statusBg = const Color(0xFFDCFCE7);
                            break;
                          case 'PROCESSING':
                            statusColor = const Color(0xFF2563EB);
                            statusBg = const Color(0xFFDBEAFE);
                            break;
                          case 'PENDING':
                            statusColor = const Color(0xFFD97706);
                            statusBg = const Color(0xFFFEF3C7);
                            break;
                          default:
                            statusColor = AppColors.error;
                            statusBg = const Color(0xFFFEE2E2);
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top row: Operator + Title + Status Chip
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    OperatorBadge(codeOrName: order.operator, size: 38),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            order.offerTitle.isNotEmpty ? order.offerTitle : '${order.operator} Offer',
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            dateStr,
                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusBg,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        order.status,
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),

                                // Details row: Phone Number + Order Price
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    InkWell(
                                      onTap: () => _copy(order.phone, 'ফোন নম্বর কপি করা হয়েছে'),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.phone_android, size: 16, color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Text(
                                            order.phone,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.copy, size: 13, color: AppColors.textSecondary),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '৳${order.price.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Order ID
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'ID: #${order.id.length > 8 ? order.id.substring(order.id.length - 8) : order.id}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontFamily: 'monospace'),
                                    ),
                                    if (order.status.toUpperCase() == 'PENDING' || order.status.toUpperCase() == 'PROCESSING')
                                      const Row(
                                        children: [
                                          SizedBox(
                                            width: 10,
                                            height: 10,
                                            child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFFD97706)),
                                          ),
                                          SizedBox(width: 6),
                                          Text('In Progress', style: TextStyle(fontSize: 11, color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

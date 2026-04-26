import 'package:flutter/material.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import '../../core/data/service_repository.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/formatters.dart';
import '../../models/models.dart';
import 'add_service_screen.dart';
import 'service_details_screen.dart';

enum HomeServiceFilter { all, today, week, month }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ServiceRepository _repository = ServiceRepository();
  List<LoadService> _allServices = [];
  List<LoadService> _filteredServices = [];
  List<Payment> _upcomingChecks = [];
  bool _isLoading = true;
  HomeServiceFilter _activeFilter = HomeServiceFilter.all;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final services = await _repository.getAllServices();
      final allPayments = await _repository.getPayments();
      
      // فیلتر کردن چک‌های پاس نشده که سررسیدشان نزدیک است (مثلاً تا ۱۰ روز آینده)
      final now = DateTime.now();
      final upcoming = allPayments.where((p) {
        if (p.method == PaymentMethod.check && !p.isCleared && p.checkDueDate != null) {
          final difference = p.checkDueDate!.difference(now).inDays;
          return difference <= 10; // چک‌های ۱۰ روز آینده
        }
        return false;
      }).toList();

      // مرتب‌سازی بر اساس تاریخ سررسید
      upcoming.sort((a, b) => a.checkDueDate!.compareTo(b.checkDueDate!));

      setState(() {
        _allServices = services;
        _upcomingChecks = upcoming;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در بارگذاری داده‌ها: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    final now = DateTime.now();
    setState(() {
      _filteredServices = _allServices.where((service) {
        if (_activeFilter == HomeServiceFilter.today) {
          return service.date.year == now.year && service.date.month == now.month && service.date.day == now.day;
        } else if (_activeFilter == HomeServiceFilter.week) {
          final weekAgo = now.subtract(const Duration(days: 7));
          return service.date.isAfter(weekAgo);
        } else if (_activeFilter == HomeServiceFilter.month) {
          return service.date.year == now.year && service.date.month == now.month;
        }
        return true; // All
      }).toList();
    });
  }

  Future<void> _confirmClearance(Payment payment) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأیید وصول چک'),
        content: Text('آیا مطمئن هستید که چک به مبلغ ${AppFormatters.formatCurrency(payment.amount)} تومان وصول شده است؟\nبا تأیید این مورد، مبلغ از بدهی کسر خواهد شد.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('خیر')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('بله، وصول شد')),
        ],
      ),
    );

    if (res == true) {
      final updatedPayment = Payment(
        id: payment.id,
        serviceId: payment.serviceId,
        sellerId: payment.sellerId,
        customerId: payment.customerId,
        type: payment.type,
        method: payment.method,
        amount: payment.amount,
        date: payment.date,
        description: payment.description,
        receiptImagePath: payment.receiptImagePath,
        checkDueDate: payment.checkDueDate,
        checkImagePath: payment.checkImagePath,
        isCleared: true,
      );

      await DatabaseHelper.instance.insertPayment(updatedPayment);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('وضعیت چک به وصول شده تغییر یافت'), backgroundColor: Colors.green),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/khatoon_logo.png',
              height: 32,
            ),
            const SizedBox(width: 8),
            const Text('خاتون بار'),
          ],
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(theme),
                    
                    if (_upcomingChecks.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildUpcomingChecksSection(theme),
                    ],

                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'آخرین سرویس‌ها',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: _loadData,
                          child: const Text('به‌روزرسانی', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    _buildFilterChips(),
                    const SizedBox(height: 12),
                    if (_filteredServices.isEmpty) 
                      _buildEmptyState(theme)
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredServices.length > 10 ? 10 : _filteredServices.length,
                        itemBuilder: (context, index) {
                          final service = _filteredServices[index];
                          return _buildServiceCard(service, theme);
                        },
                      ),
                  ],
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddServiceScreen()),
          );
          if (result == true) _loadData();
        },
        label: const Text('ثبت سرویس جدید'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _filterChip(HomeServiceFilter.all, 'همه'),
          _filterChip(HomeServiceFilter.today, 'امروز'),
          _filterChip(HomeServiceFilter.week, 'این هفته'),
          _filterChip(HomeServiceFilter.month, 'این ماه'),
        ],
      ),
    );
  }

  Widget _filterChip(HomeServiceFilter filter, String label) {
    bool isSelected = _activeFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87)),
        selected: isSelected,
        selectedColor: Theme.of(context).primaryColor,
        onSelected: (val) {
          setState(() {
            _activeFilter = filter;
            _applyFilters();
          });
        },
      ),
    );
  }

  Widget _buildUpcomingChecksSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.notification_important_outlined, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Text(
              'چک‌های سررسید نزدیک',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.orange.shade900),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _upcomingChecks.length,
            itemBuilder: (context, index) {
              final check = _upcomingChecks[index];
              final daysLeft = check.checkDueDate!.difference(DateTime.now()).inDays;
              
              return Container(
                width: 240,
                margin: const EdgeInsets.only(left: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppFormatters.formatCurrency(check.amount),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _confirmClearance(check),
                              icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'تأیید وصول',
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: daysLeft <= 1 ? Colors.red : Colors.orange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                daysLeft <= 0 ? "امروز" : "$daysLeft روز مانده",
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      check.description ?? "بدون توضیح",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      "سررسید: ${check.checkDueDate!.toPersianDate()}",
                      style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    double totalCustomerDebt = _allServices.fold(0, (sum, s) => sum + s.remainingCustomerDebt);
    double totalSellerDebt = _allServices.fold(0, (sum, s) => sum + s.remainingDebtToSeller);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow('طلب از مشتریان', totalCustomerDebt, Colors.blue.shade800, theme),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF2F4F7)),
          ),
          _buildSummaryRow('بدهی به فروشندگان', totalSellerDebt, Colors.red.shade800, theme),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color color, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        Text(
          "${AppFormatters.formatCurrency(amount)} تومان",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard(LoadService service, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ServiceDetailsScreen(service: service)),
          );
          _loadData();
        },
        title: Text(
          "${service.customer?.fullName ?? 'بدون نام'} - ${service.loadType.name}",
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            "${service.origin} به ${service.destination}\n${service.date.toPersianDate()}", 
            style: theme.textTheme.bodySmall
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              AppFormatters.formatCurrency(service.totalServicePriceForCustomer),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              "${service.weight.toString().toPersianDigit()} تن", 
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_late_outlined, size: 64, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text('سرویسی یافت نشد', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
        ],
      ),
    );
  }
}

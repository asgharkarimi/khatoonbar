import 'package:flutter/material.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/formatters.dart';
import '../../models/models.dart';
import 'add_service_screen.dart';
import 'service_details_screen.dart';

enum ServiceFilter { all, today, week, month, custom }

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  String _searchQuery = "";
  List<LoadService> _allServices = [];
  List<LoadService> _filteredServices = [];
  bool _isLoading = true;
  ServiceFilter _activeFilter = ServiceFilter.all;
  DateTime? _customDate;

  Customer? _selectedCustomer;
  Seller? _selectedSeller;
  String? _selectedLogistics;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    try {
      final services = await DatabaseHelper.instance.getAllServices();
      setState(() {
        _allServices = services;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در بارگذاری سرویس‌ها: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    final now = DateTime.now();
    setState(() {
      _filteredServices = _allServices.where((service) {
        final searchIn = [
          service.driver.fullName,
          service.customer?.fullName ?? '',
          service.seller.name,
          service.loadType.name,
          service.origin,
          service.destination,
          service.orderCode,
          service.logisticsCo?.name ?? '',
          service.logisticsName ?? '',
        ].join(' ').toLowerCase();

        bool matchesSearch = searchIn.contains(_searchQuery.toLowerCase());

        bool matchesTime = true;
        if (_activeFilter == ServiceFilter.today) {
          matchesTime = service.date.year == now.year && service.date.month == now.month && service.date.day == now.day;
        } else if (_activeFilter == ServiceFilter.week) {
          final weekAgo = now.subtract(const Duration(days: 7));
          matchesTime = service.date.isAfter(weekAgo);
        } else if (_activeFilter == ServiceFilter.month) {
          matchesTime = service.date.year == now.year && service.date.month == now.month;
        } else if (_activeFilter == ServiceFilter.custom && _customDate != null) {
          matchesTime = service.date.year == _customDate!.year && service.date.month == _customDate!.month && service.date.day == _customDate!.day;
        }

        bool matchesCustomer = _selectedCustomer == null || service.customer?.id == _selectedCustomer!.id;
        bool matchesSeller = _selectedSeller == null || service.seller.id == _selectedSeller!.id;
        bool matchesLogistics = _selectedLogistics == null ||
            (service.logisticsCo?.name == _selectedLogistics || service.logisticsName == _selectedLogistics);

        return matchesSearch && matchesTime && matchesCustomer && matchesSeller && matchesLogistics;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لیست سرویس‌ها'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _pickCustomDate,
            tooltip: 'انتخاب تاریخ خاص',
          ),
          PopupMenuButton<String>(
            tooltip: 'جستجو و فیلتر پیشرفته',
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'date') _pickCustomDate();
              else if (val == 'customer') _showEntityPicker('customer');
              else if (val == 'seller') _showEntityPicker('seller');
              else if (val == 'logistics') _showEntityPicker('logistics');
              else if (val == 'clear') {
                setState(() {
                  _activeFilter = ServiceFilter.all;
                  _customDate = null;
                  _selectedCustomer = null;
                  _selectedSeller = null;
                  _selectedLogistics = null;
                  _searchQuery = "";
                  _applyFilters();
                });
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'date', child: ListTile(leading: Icon(Icons.calendar_month_outlined), title: Text('جستجو با تاریخ'), contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'customer', child: ListTile(leading: Icon(Icons.person_outline), title: Text('جستجو با نام گیرنده'), contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'seller', child: ListTile(leading: Icon(Icons.storefront_outlined), title: Text('جستجو با نام فرستنده'), contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'logistics', child: ListTile(leading: Icon(Icons.business_outlined), title: Text('جستجو با نام باربری'), contentPadding: EdgeInsets.zero)),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'clear', child: ListTile(leading: Icon(Icons.filter_alt_off_outlined), title: Text('حذف تمام فیلترها'), contentPadding: EdgeInsets.zero)),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredServices.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadServices,
                        child: ListView.builder(
                          itemCount: _filteredServices.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemBuilder: (context, index) {
                            final service = _filteredServices[index];
                            return _buildServiceCard(service);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(builder: (context) => const AddServiceScreen()),
          );
          if (result == true) _loadServices();
        },
        label: const Text('افزودن سرویس'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        onChanged: (v) {
          _searchQuery = v;
          _applyFilters();
        },
        decoration: InputDecoration(
          hintText: 'جستجو در راننده، مشتری، فروشنده، باربری...',
          prefixIcon: const Icon(Icons.search),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _filterChip(ServiceFilter.all, 'همه'),
          _filterChip(ServiceFilter.today, 'امروز'),
          _filterChip(ServiceFilter.week, 'یک هفته اخیر'),
          _filterChip(ServiceFilter.month, 'این ماه'),
          if (_activeFilter == ServiceFilter.custom && _customDate != null)
            _filterChip(ServiceFilter.custom, _customDate!.toPersianDate()),
          if (_selectedCustomer != null)
            _entityChip('گیرنده: ${_selectedCustomer!.fullName}', () => setState(() { _selectedCustomer = null; _applyFilters(); })),
          if (_selectedSeller != null)
            _entityChip('فرستنده: ${_selectedSeller!.name}', () => setState(() { _selectedSeller = null; _applyFilters(); })),
          if (_selectedLogistics != null)
            _entityChip('باربری: $_selectedLogistics', () => setState(() { _selectedLogistics = null; _applyFilters(); })),
        ],
      ),
    );
  }

  Widget _filterChip(ServiceFilter filter, String label) {
    bool isSelected = _activeFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
        selected: isSelected,
        selectedColor: Colors.green,
        onSelected: (val) {
          setState(() {
            _activeFilter = filter;
            if (filter != ServiceFilter.custom) _customDate = null;
            _applyFilters();
          });
        },
      ),
    );
  }

  Widget _entityChip(String label, VoidCallback onDeleted) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 10)),
        deleteIcon: const Icon(Icons.close, size: 14),
        onDeleted: onDeleted,
        backgroundColor: Colors.blue.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.all(4),
      ),
    );
  }

  void _showEntityPicker(String type) {
    List<dynamic> items = [];
    String title = "";

    if (type == 'customer') {
      title = "انتخاب گیرنده (مشتری)";
      items = _allServices.map((s) => s.customer).whereType<Customer>().toSet().toList();
    } else if (type == 'seller') {
      title = "انتخاب فرستنده (فروشنده)";
      items = _allServices.map((s) => s.seller).toSet().toList();
    } else if (type == 'logistics') {
      title = "انتخاب باربری";
      items = _allServices.map((s) => s.logisticsCo?.name ?? s.logisticsName).whereType<String>().where((s) => s.isNotEmpty).toSet().toList();
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('دیتایی برای این فیلتر یافت نشد')));
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const Divider(),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                String name = "";
                if (item is Customer) name = item.fullName;
                else if (item is Seller) name = item.name;
                else if (item is String) name = item;

                return ListTile(
                  title: Text(name),
                  onTap: () {
                    setState(() {
                      if (type == 'customer') _selectedCustomer = item;
                      else if (type == 'seller') _selectedSeller = item;
                      else if (type == 'logistics') _selectedLogistics = item;
                      _applyFilters();
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _pickCustomDate() async {
    Jalali? picked = await showPersianDatePicker(
      context: context,
      initialDate: Jalali.now(),
      firstDate: Jalali(1400),
      lastDate: Jalali.now(),
    );
    if (picked != null) {
      setState(() {
        _customDate = picked.toDateTime();
        _activeFilter = ServiceFilter.custom;
        _applyFilters();
      });
    }
  }

  Widget _buildServiceCard(LoadService service) {
    final customerDebt = service.finalBalanceCustomerDebt;
    final sellerDebt = service.finalBalanceToSeller;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          await Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(builder: (context) => ServiceDetailsScreen(service: service)),
          );
          _loadServices();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${service.customer?.fullName ?? 'بدون نام'} - ${service.loadType.name}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              "${service.origin} به ${service.destination}",
                              style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              service.date.toPersianDate(),
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.numbers_outlined, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              service.orderCode.toPersianDigit(),
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppFormatters.formatCurrency(service.totalServicePriceForCustomer),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
                      ),
                      Text(
                        "${service.weight.toString().toPersianDigit()} تن",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMiniStatusBadge(
                    label: "دریافتی از مشتری",
                    amount: service.totalCollectedFromCustomer,
                    remaining: customerDebt,
                    isPositive: true,
                  ),
                  _buildMiniStatusBadge(
                    label: "پرداختی به فروشنده",
                    amount: service.totalPaidToSeller,
                    remaining: sellerDebt,
                    isPositive: false,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStatusBadge({required String label, required double amount, required double remaining, required bool isPositive}) {
    bool isSettled = remaining <= 0;
    Color color = isSettled ? Colors.green : (isPositive ? Colors.blue : Colors.red);
    
    return Column(
      crossAxisAlignment: isPositive ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSettled) 
              const Icon(Icons.check_circle, size: 12, color: Colors.green)
            else if (amount > 0)
              const Icon(Icons.pending_actions, size: 12, color: Colors.orange),
            const SizedBox(width: 4),
            Text(
              isSettled ? "تسویه کامل" : (amount == 0 ? "بدون پرداخت" : "مانده: ${AppFormatters.formatCurrency(remaining)}"),
              style: TextStyle(
                fontSize: 11, 
                fontWeight: FontWeight.bold, 
                color: isSettled ? Colors.green.shade700 : (amount == 0 ? Colors.grey : color)
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_outlined, size: 64, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'سرویسی در این بازه یافت نشد' : 'موردی یافت نشد',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

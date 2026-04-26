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
        // فیلتر جستجو
        final searchIn = "${service.driver.fullName} ${service.customer?.fullName ?? ''} ${service.loadType.name} ${service.origin} ${service.destination}".toLowerCase();
        bool matchesSearch = searchIn.contains(_searchQuery.toLowerCase());

        // فیلتر زمانی
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

        return matchesSearch && matchesTime;
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
          )
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
                          padding: const EdgeInsets.symmetric(horizontal: 16),
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
          final result = await Navigator.push(
            context,
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
          hintText: 'جستجو در راننده، مشتری، بار یا مسیر...',
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ServiceDetailsScreen(service: service)),
          );
          _loadServices();
        },
        title: Text(
          "${service.customer?.fullName ?? 'بدون نام'} - ${service.loadType.name}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          "${service.origin} به ${service.destination}\n${service.date.toPersianDate()}",
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              AppFormatters.formatCurrency(service.totalServicePriceForCustomer),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13),
            ),
            Text("${service.weight.toString().toPersianDigit()} تن", style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
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

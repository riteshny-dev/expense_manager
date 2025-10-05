import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive/hive.dart';
import '../models/expense.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  final int? selectedMonth;
  final int? selectedYear;

  const HomeScreen({
    super.key,
    this.selectedMonth,
    this.selectedYear,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _allocatedController = TextEditingController();
  DateTime? _selectedDate;
  String _selectedCategory = 'General';

  double _allocatedAmount = 0.0;
  bool _isBudgetSet = false;
  bool _showPieChart = false;
  int? _touchedBarIndex;

  final List<String> _categories = [
    'General', 'Food', 'Medical', 'Travel', 'Shopping', 'Bills', 'EMIs', 'Savings', 'Others',
  ];

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  String get _budgetKey {
    final now = DateTime.now();
    final month = widget.selectedMonth ?? now.month;
    final year = widget.selectedYear ?? now.year;
    return 'budget_${year}_${month.toString().padLeft(2, '0')}';
  }

  void _loadBudget() {
    final settingsBox = Hive.box('settings');
    final value = settingsBox.get(_budgetKey, defaultValue: 0.0);
    setState(() {
      _allocatedAmount = value;
      _isBudgetSet = _allocatedAmount > 0;
      _allocatedController.text = value > 0 ? value.toString() : '';
    });
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: '✕',
          onPressed: () {},
        ),
      ),
    );
  }

  void _setBudget() {
    final value = double.tryParse(_allocatedController.text);
    if (value != null) {
      final settingsBox = Hive.box('settings');
      settingsBox.put(_budgetKey, value);
      setState(() {
        _allocatedAmount = value;
        _isBudgetSet = true;
      });
      _showSnackbar('Monthly budget set.');
    }
  }

  void _editBudgetPrompt() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Edit Monthly Budget', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _allocatedController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Enter new budget', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                ElevatedButton(
                  child: const Text('Save'),
                  onPressed: () {
                    final value = double.tryParse(_allocatedController.text);
                    if (value != null) {
                      final settingsBox = Hive.box('settings');
                      settingsBox.put(_budgetKey, value);
                      setState(() {
                        _allocatedAmount = value;
                      });
                      Navigator.of(ctx).pop();
                      _showSnackbar('Monthly budget updated.');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _clearForm() {
    _titleController.clear();
    _amountController.clear();
    _selectedDate = null;
    _selectedCategory = 'General';
  }

  Map<String, double> _calculateCategoryTotals(List<Expense> expenses) {
    final Map<String, double> categoryTotals = {};
    for (final expense in expenses) {
      categoryTotals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return categoryTotals;
  }

  List<PieChartSectionData> _getPieChartSections(List<Expense> expenses) {
    final data = _calculateCategoryTotals(expenses);
    final total = data.values.fold(0.0, (sum, val) => sum + val);

    final List<Color> colors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange,
      Colors.purple, Colors.teal, Colors.brown, Colors.pink,
    ];

    int colorIndex = 0;

    return data.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      final color = colors[colorIndex % colors.length];
      colorIndex++;

      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  List<BarChartGroupData> _getBarChartGroups(List<Expense> expenses) {
    final data = _calculateCategoryTotals(expenses);
    final List<Color> colors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange,
      Colors.purple, Colors.teal, Colors.brown, Colors.pink,
    ];
    int colorIndex = 0;
    int x = 0;

    return data.entries.map((entry) {
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      return BarChartGroupData(
        x: x++,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: color,
            width: 18,
            borderRadius: BorderRadius.circular(6),
            rodStackItems: [],
          ),
        ],
        showingTooltipIndicators: [0],
      );
    }).toList();
  }

  void _submitData() {
    final title = _titleController.text;
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (title.isEmpty || amount <= 0 || _selectedDate == null) return;

    final newExpense = Expense(
      title: title,
      amount: amount,
      date: _selectedDate!,
      category: _selectedCategory,
    );

    Hive.box<Expense>('expenses').add(newExpense);

    _clearForm();
    Navigator.of(context).pop();

    _showSnackbar('Expense added successfully!');

    setState(() {});
  }

  void _openAddExpenseSheet() {
    _clearForm();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Add New Expense', style: Theme.of(context).textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDate == null
                          ? 'No Date Chosen! *'
                          : 'Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: now,
                        firstDate: DateTime(now.year - 1),
                        lastDate: now,
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                    child: const Text('Choose Date'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedCategory = value);
                },
                decoration: const InputDecoration(labelText: 'Category *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitData,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Add Expense'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEditExpenseSheet(Expense expense, int index) {
    _titleController.text = expense.title;
    _amountController.text = expense.amount.toString();
    _selectedDate = expense.date;
    _selectedCategory = expense.category;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Edit Expense', style: Theme.of(context).textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDate == null
                          ? 'No Date Chosen! *'
                          : 'Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? now,
                        firstDate: DateTime(now.year - 1),
                        lastDate: now,
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                    child: const Text('Choose Date'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedCategory = value);
                },
                decoration: const InputDecoration(labelText: 'Category *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final title = _titleController.text;
                    final amount = double.tryParse(_amountController.text) ?? 0;
                    if (title.isEmpty || amount <= 0 || _selectedDate == null) return;

                    final updatedExpense = Expense(
                      title: title,
                      amount: amount,
                      date: _selectedDate!,
                      category: _selectedCategory,
                    );

                    final expenseBox = Hive.box<Expense>('expenses');
                    expenseBox.putAt(index, updatedExpense);

                    _clearForm();
                    Navigator.of(context).pop();
                    _showSnackbar('Expense updated successfully!');
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteExpense(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final expenseBox = Hive.box<Expense>('expenses');
      expenseBox.deleteAt(index);
      _showSnackbar('Expense deleted!');
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseBox = Hive.box<Expense>('expenses');
    final allExpenses = expenseBox.values.toList().reversed.toList();
    final expenses = widget.selectedMonth != null && widget.selectedYear != null
        ? allExpenses.where((e) =>
            e.date.month == widget.selectedMonth &&
            e.date.year == widget.selectedYear).toList()
        : allExpenses;

    final total = expenses.fold(0.0, (sum, item) => sum + item.amount);
    final remaining = _allocatedAmount - total;

    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            );
          },
        ),
        title: const Text('Expense Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _openAddExpenseSheet,
          ),
        ],
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 1,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: TextField(
                      controller: _allocatedController,
                      keyboardType: TextInputType.number,
                      enabled: !_isBudgetSet,
                      style: const TextStyle(fontSize: 18),
                      decoration: InputDecoration(
                        labelText: 'Monthly Budget *',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: !_isBudgetSet ? _setBudget : null,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Set'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isBudgetSet ? _editBudgetPrompt : null,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Edit'),
                ),
              ],
            ),
          ),
          if (expenses.isNotEmpty)
            SizedBox(
              height: 250,
              child: Card(
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Expenses by Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: Icon(
                              _showPieChart ? Icons.pie_chart : Icons.bar_chart,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            tooltip: _showPieChart ? 'Show Bar Chart' : 'Show Pie Chart',
                            onPressed: () {
                              setState(() {
                                _showPieChart = !_showPieChart;
                                _touchedBarIndex = null;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _showPieChart
                            ? PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 30,
                                  sections: _getPieChartSections(expenses),
                                ),
                              )
                            : BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: _calculateCategoryTotals(expenses).values.isEmpty
                                      ? 10
                                      : (_calculateCategoryTotals(expenses).values.reduce((a, b) => a > b ? a : b) * 1.2),
                                  barTouchData: BarTouchData(
                                    enabled: true,
                                    touchTooltipData: BarTouchTooltipData(
                                      tooltipBgColor: Colors.transparent,
                                      tooltipPadding: EdgeInsets.zero,
                                      tooltipMargin: 0,
                                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                        if (_touchedBarIndex == group.x) {
                                          final value = rod.toY;
                                          return BarTooltipItem(
                                            '₹ ${value.toStringAsFixed(1)}',
                                            TextStyle(
                                              color: Theme.of(context).colorScheme.onSurface,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          );
                                        }
                                        return null;
                                      },
                                    ),
                                    touchCallback: (event, response) {
                                      setState(() {
                                        if (event.isInterestedForInteractions &&
                                            response != null &&
                                            response.spot != null) {
                                          _touchedBarIndex = response.spot!.touchedBarGroupIndex;
                                        } else {
                                          _touchedBarIndex = null;
                                        }
                                      });
                                    },
                                  ),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        getTitlesWidget: (value, meta) {
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 8.0),
                                            child: Text(
                                              value == 0
                                                  ? '₹ 0'
                                                  : value >= 1000
                                                      ? '₹ ${(value ~/ 1000)}K'
                                                      : '₹ ${value.toInt()}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Theme.of(context).colorScheme.onSurface,
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    rightTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (double value, TitleMeta meta) {
                                          final categories = _calculateCategoryTotals(expenses).keys.toList();
                                          if (value.toInt() >= 0 && value.toInt() < categories.length) {
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: Text(
                                                categories[value.toInt()],
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                  color: Theme.of(context).colorScheme.onSurface,
                                                ),
                                              ),
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        },
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  barGroups: _getBarChartGroups(expenses),
                                  gridData: FlGridData(show: false),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: expenses.isEmpty
                ? const Center(child: Text('No expenses added yet.'))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: expenses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final expense = expenses[i];
                      final isCurrentMonth = expense.date.month == now.month && expense.date.year == now.year;
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(expense.title, 
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${expense.date.day.toString().padLeft(2, '0')}/${expense.date.month.toString().padLeft(2, '0')}/${expense.date.year}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary),
                              ),
                            ],
                          ),
                          subtitle: Text('${expense.category} • ₹${expense.amount.toStringAsFixed(2)}'),
                          trailing: isCurrentMonth
                              ? Wrap(
                                  spacing: 0,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _openEditExpenseSheet(expense, expenseBox.length - 1 - i),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteExpense(expenseBox.length - 1 - i),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
          Container(
            color: Colors.grey.shade300,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Expense:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                    Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Remaining Budget:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                    Text(
                      '₹${remaining.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: remaining >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }
}
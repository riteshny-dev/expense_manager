import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive/hive.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

import '../models/expense.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late int _selectedYear;
  late List<int> _availableYears;
  bool _showPieChart = true;
  int? _touchedBarIndex;

  @override
  void initState() {
    super.initState();
    final allExpenses = Hive.box<Expense>('expenses').values.toList();
    final years = allExpenses.map((e) => e.date.year).toSet().toList()..sort();
    _availableYears = years.isEmpty ? [DateTime.now().year] : years;
    _selectedYear = _availableYears.last;
  }

  Map<String, double> _calculateYearlyTotals(List<Expense> expenses) {
    final currentYearExpenses = expenses.where((e) => e.date.year == _selectedYear).toList();
    final Map<String, double> totals = {};
    for (final expense in currentYearExpenses) {
      totals.update(
        expense.category,
        (val) => val + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return totals;
  }

  List<PieChartSectionData> _getPieChartSections(Map<String, double> data) {
    final total = data.values.fold(0.0, (sum, val) => sum + val);
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.brown,
      Colors.pink,
    ];
    int colorIndex = 0;

    final List<PieChartSectionData> sections = [];

    for (final entry in data.entries) {
      final percentage = (entry.value / total) * 100;
      final color = colors[colorIndex % colors.length];
      colorIndex++;

      sections.add(
        PieChartSectionData(
          color: color,
          value: entry.value,
          title: '${entry.key}\n${percentage.toStringAsFixed(1)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return sections;
  }

  List<BarChartGroupData> _getBarChartGroups(Map<String, double> data) {
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.brown,
      Colors.pink,
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

  Widget _buildReceivablePayableSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.teal.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.teal.shade300),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                'Receivable & Payable',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Total Receivable', style: TextStyle(fontSize: 16)),
                  Text('₹ 0.00', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Total Payable', style: TextStyle(fontSize: 16)),
                  Text('₹ 0.00', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportYearlyDataToPdf() async {
    final expenseBox = Hive.box<Expense>('expenses');
    final expenses = expenseBox.values
        .where((e) => e.date.year == _selectedYear)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Expense Report - $_selectedYear',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              pw.Table.fromTextArray(
                headers: ['Date', 'Title', 'Category', 'Amount'],
                data: expenses
                    .map((e) => [
                          "${e.date.day.toString().padLeft(2, '0')}-${e.date.month.toString().padLeft(2, '0')}-${e.date.year}",
                          e.title,
                          e.category,
                          "₹${e.amount.toStringAsFixed(2)}"
                        ])
                    .toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: const pw.TextStyle(fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal100),
                border: pw.TableBorder.all(color: PdfColors.grey),
              ),
            ],
          );
        },
      ),
    );

    // Request storage permission if needed
    if (await Permission.manageExternalStorage.request().isGranted) {
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = await getExternalStorageDirectory();
      } else {
        downloadsDir = await getDownloadsDirectory();
      }
      final file = File("${downloadsDir!.path}/expense_report_$_selectedYear.pdf");
      await file.writeAsBytes(await pdf.save());

      // Share the file
      Share.shareXFiles([XFile(file.path)], text: 'Expense Report $_selectedYear');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF exported: ${file.path}'),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission denied.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseBox = Hive.box<Expense>('expenses');
    final expenses = expenseBox.values.toList();
    final yearlyData = _calculateYearlyTotals(expenses);
    final pieSections = _getPieChartSections(yearlyData);
    final barGroups = _getBarChartGroups(yearlyData);

    final months = const [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ];

    return Scaffold(
      backgroundColor: Colors.teal[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              const Text(
                'Welcome to Expense Manager',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Select Year: ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<int>(
                    value: _selectedYear,
                    items: _availableYears
                        .map((year) => DropdownMenuItem(
                              value: year,
                              child: Text(year.toString()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedYear = value);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      _showPieChart ? Icons.pie_chart : Icons.bar_chart,
                      color: Colors.teal,
                      size: 32,
                    ),
                    tooltip: _showPieChart ? "Show Bar Chart" : "Show Pie Chart",
                    onPressed: () {
                      setState(() {
                        _showPieChart = !_showPieChart;
                        _touchedBarIndex = null;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.teal, size: 28),
                    tooltip: "Export as PDF",
                    onPressed: _exportYearlyDataToPdf,
                  ),
                ],
              ),
              Expanded(
                flex: 2,
                child: yearlyData.isEmpty
                    ? const Center(child: Text('No expenses for this year.'))
                    : _showPieChart
                        ? PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections: pieSections,
                            ),
                          )
                        : BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: yearlyData.values.isEmpty
                                  ? 10
                                  : (yearlyData.values.reduce((a, b) => a > b ? a : b) * 1.2),
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
                                        value.toStringAsFixed(1),
                                        const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          backgroundColor: Colors.white,
                                        ),
                                      );
                                    }
                                    return null;
                                  },
                                ),
                                touchCallback: (event, response) {
                                  setState(() {
                                    if (event.isInterestedForInteractions && response != null && response.spot != null) {
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
                                              ? '0'
                                              : value >= 1000
                                                  ? '${(value ~/ 1000)}K'
                                                  : value.toInt().toString(),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
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
                                      final keys = yearlyData.keys.toList();
                                      if (value.toInt() >= 0 && value.toInt() < keys.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            keys[value.toInt()],
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: yearlyData.entries.toList().asMap().entries.map((entry) {
                                final i = entry.key;
                                final e = entry.value;
                                final colorList = [
                                  Colors.blue,
                                  Colors.red,
                                  Colors.green,
                                  Colors.orange,
                                  Colors.purple,
                                  Colors.teal,
                                  Colors.brown,
                                  Colors.pink,
                                ];
                                final color = colorList[i % colorList.length];
                                return BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: e.value,
                                      color: color,
                                      width: 18,
                                      borderRadius: BorderRadius.circular(6),
                                      rodStackItems: [],
                                    ),
                                  ],
                                  showingTooltipIndicators: _touchedBarIndex == i ? [0] : [],
                                );
                              }).toList(),
                              gridData: FlGridData(show: false),
                            ),
                          ),
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Month-wise View:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                flex: 2,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 3,
                  ),
                  itemCount: months.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HomeScreen(
                              selectedMonth: index + 1,
                              selectedYear: _selectedYear,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.teal[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          months[index],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              _buildReceivablePayableSection(),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
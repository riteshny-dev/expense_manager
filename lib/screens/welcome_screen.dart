import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive/hive.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import '../models/expense.dart';
import '../models/receivable_payable.dart';
import 'home_screen.dart';
import 'receivable_payable_screen.dart';
import 'tomorrow_screen.dart'; // <-- Make sure this import exists

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
          radius: 48,
          titleStyle: const TextStyle(
            fontSize: 13,
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

  Widget _buildReceivablePayableSection(
    double screenWidth,
    double screenHeight,
    Color cardColor,
    Color borderColor,
    TextStyle? titleStyle,
    TextStyle? valueStyle,
    double receivable,
    double payable,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02, vertical: screenHeight * 0.012),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
              child: Text(
                'Receivable & Payable',
                style: titleStyle,
              ),
            ),
            const Divider(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.008),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Receivable', style: valueStyle),
                  Text('₹ ${receivable.toStringAsFixed(2)}', style: valueStyle?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.008),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Payable', style: valueStyle),
                  Text('₹ ${payable.toStringAsFixed(2)}', style: valueStyle?.copyWith(fontWeight: FontWeight.w600)),
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

    Directory? dir;
    if (Platform.isAndroid) {
      dir = await getExternalStorageDirectory();
    } else {
      dir = await getDownloadsDirectory();
    }
    final file = File("${dir!.path}/expense_report_$_selectedYear.pdf");
    await file.writeAsBytes(await pdf.save());

    Share.shareXFiles([XFile(file.path)], text: 'Expense Report $_selectedYear');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF exported: ${file.path}'),
        ),
      );
    }
  }

  Map<String, double> _getReceivablePayableTotals() {
    final box = Hive.box<ReceivablePayable>('receivables_payables');
    double receivable = 0;
    double payable = 0;
    for (final item in box.values) {
      if (item.isReceivable) {
        receivable += item.amount;
      } else {
        payable += item.amount;
      }
    }
    return {
      'receivable': receivable,
      'payable': payable,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final expenseBox = Hive.box<Expense>('expenses');
    final expenses = expenseBox.values.toList();
    final yearlyData = _calculateYearlyTotals(expenses);
    final pieSections = _getPieChartSections(yearlyData);

    final months = const [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ];

    final backgroundColor = colorScheme.surface;
    final cardColor = colorScheme.surface;
    final borderColor = colorScheme.primary.withOpacity(0.3);
    final buttonColor = colorScheme.primaryContainer;
    final textColor = colorScheme.onSurface;
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: screenWidth * 0.05,
      color: textColor,
    );
    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: screenWidth * 0.042,
      color: textColor,
    );

    final totals = _getReceivablePayableTotals();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.02,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.01),
                Text(
                  'Welcome to Expense Manager',
                  style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.015),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Select Year: ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.045,
                            color: textColor,
                          ),
                    ),
                    DropdownButton<int>(
                      value: _selectedYear,
                      dropdownColor: cardColor,
                      style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
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
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        _showPieChart ? Icons.pie_chart : Icons.bar_chart,
                        color: colorScheme.primary,
                        size: screenWidth * 0.08,
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
                      icon: Icon(Icons.picture_as_pdf, color: colorScheme.primary, size: screenWidth * 0.07),
                      tooltip: "Export as PDF",
                      onPressed: _exportYearlyDataToPdf,
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.01),
                Container(
                  height: screenHeight * 0.32,
                  alignment: Alignment.center,
                  child: yearlyData.isEmpty
                      ? Center(child: Text('No expenses for this year.', style: valueStyle))
                      : _showPieChart
                          ? PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: screenWidth * 0.13,
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
                                          TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            backgroundColor: cardColor,
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
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: textColor,
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
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: textColor,
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
                                barGroups: _getBarChartGroups(yearlyData),
                                gridData: FlGridData(show: false),
                              ),
                            ),
                ),
                SizedBox(height: screenHeight * 0.02),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Month-wise View:',
                    style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.05,
                          color: textColor,
                        ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: screenWidth > 600 ? 4 : 3,
                    mainAxisSpacing: screenHeight * 0.012,
                    crossAxisSpacing: screenWidth * 0.02,
                    childAspectRatio: 2.5,
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
                          color: buttonColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          months[index],
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.045,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: screenHeight * 0.02),

                // ---- Receivable & Payable Section ----
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReceivablePayableScreen()),
                    );
                    setState(() {}); // Refresh totals after returning
                  },
                  child: _buildReceivablePayableSection(
                    screenWidth,
                    screenHeight,
                    cardColor,
                    borderColor,
                    titleStyle,
                    valueStyle,
                    totals['receivable'] ?? 0,
                    totals['payable'] ?? 0,
                  ),
                ),

                // ---- Tomorrow's Plan Button ----
                SizedBox(height: screenHeight * 0.02),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TomorrowScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.08,
                      vertical: screenHeight * 0.015,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Tomorrow's Plan",
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
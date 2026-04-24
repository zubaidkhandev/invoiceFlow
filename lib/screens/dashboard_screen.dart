import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:invoice_flow/blocs/invoice_cubit.dart';
import 'package:invoice_flow/blocs/settings_cubit.dart';
import 'package:invoice_flow/models/invoice.dart';
import 'package:invoice_flow/screens/create_invoice_screen.dart';
import 'package:invoice_flow/utils/formatters.dart';
import 'package:invoice_flow/widgets/premium_widgets.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: BlocBuilder<InvoiceCubit, InvoiceState>(
        builder: (context, state) {
          if (state is InvoiceLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is InvoiceLoaded) {
            final invoices = state.invoices;
            final settings = context.watch<SettingsCubit>().state;

            final totalBilled = invoices.fold(0.0, (sum, i) => sum + i.total);
            final totalPaid = invoices
                .where((i) => i.status == InvoiceStatus.paid)
                .fold(0.0, (sum, i) => sum + i.total);
            final totalUnpaid = invoices
                .where((i) => i.status == InvoiceStatus.unpaid)
                .fold(0.0, (sum, i) => sum + i.total);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, settings),
                  const SizedBox(height: 32),
                  _buildSummaryCards(
                      totalBilled, totalPaid, totalUnpaid, settings.currency),
                  const SizedBox(height: 48),
                  _buildRevenueChart(context, invoices, settings.currency),
                  const SizedBox(height: 48),
                  LayoutBuilder(builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 900;
                    final hasInvoices = invoices.isNotEmpty;

                    if (isMobile) {
                      return Column(
                        children: [
                          if (hasInvoices) ...[
                            _buildChartSection(context, invoices),
                            const SizedBox(height: 32),
                          ],
                          _buildRecentInvoices(
                              context, invoices, settings.currency),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasInvoices) ...[
                          Expanded(
                              flex: 2,
                              child: _buildChartSection(context, invoices)),
                          const SizedBox(width: 32),
                        ],
                        Expanded(
                            flex: 4,
                            child: _buildRecentInvoices(
                                context, invoices, settings.currency)),
                      ],
                    );
                  }),
                ],
              ),
            );
          }
          return const Center(child: Text('Start creating invoices!'));
        },
      ),
      floatingActionButton: PremiumFAB(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
        ),
        icon: Icons.add,
        label: 'New Invoice',
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SettingsState settings) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back,',
                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade500 : Colors.blueGrey.shade400, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
                settings.sender.businessName.isNotEmpty
                    ? settings.sender.businessName
                    : 'Your Financial Overview',
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
        if (settings.sender.logoData != null)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: MemoryImage(base64Decode(settings.sender.logoData!)),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryCards(
      double billed, double paid, double unpaid, String currency) {
    return LayoutBuilder(builder: (context, constraints) {
      final cardWidth = (constraints.maxWidth - 48) / 3;
      return Wrap(
        spacing: 24,
        runSpacing: 24,
        children: [
          PremiumCard(
            width: cardWidth < 300 ? constraints.maxWidth : cardWidth,
            gradientColors: const [Color(0xFFFED200), Color(0xFFD97706)],
            child: _SummaryContent(
                title: 'Total Billed',
                value: AppFormatters.formatCurrency(billed, currency),
                icon: Icons.account_balance_wallet,
                isDark: false),
          ),
          PremiumCard(
            width: cardWidth < 300 ? constraints.maxWidth : cardWidth,
            gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
            child: _SummaryContent(
                title: 'Total Paid',
                value: AppFormatters.formatCurrency(paid, currency),
                icon: Icons.check_circle,
                isDark: true),
          ),
          PremiumCard(
            width: cardWidth < 300 ? constraints.maxWidth : cardWidth,
            gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
            child: _SummaryContent(
                title: 'Outstanding',
                value: AppFormatters.formatCurrency(unpaid, currency),
                icon: Icons.pending,
                isDark: true),
          ),
        ],
      );
    });
  }

  Widget _buildRevenueChart(
      BuildContext context, List<Invoice> invoices, String currency) {
    final Map<int, double> monthlyData = {};
    for (int i = 1; i <= 6; i++) {
      final month = DateTime.now().subtract(Duration(days: 30 * (6 - i))).month;
      monthlyData[month] = 0.0;
    }

    for (var invoice in invoices) {
      if (invoice.issueDate
          .isAfter(DateTime.now().subtract(const Duration(days: 180)))) {
        final month = invoice.issueDate.month;
        if (monthlyData.containsKey(month)) {
          monthlyData[month] = (monthlyData[month] ?? 0) + invoice.total;
        }
      }
    }

    return PremiumCard(
      height: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Revenue Trend (Last 6 Months)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 32),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (monthlyData.values.isEmpty
                        ? 100
                        : monthlyData.values.reduce((a, b) => a > b ? a : b)) *
                    1.2,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final month = value.toInt();
                        if (month < 1 || month > 12) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                              DateFormat('MMM').format(DateTime(2024, month)),
                              style: TextStyle(
                                  fontSize: 10, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey : Colors.blueGrey.shade400)),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: monthlyData.entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value,
                        color: Theme.of(context).colorScheme.primary,
                        width: 40,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(BuildContext context, List<Invoice> invoices) {
    if (invoices.isEmpty) return const SizedBox.shrink();

    final paidCount =
        invoices.where((i) => i.status == InvoiceStatus.paid).length;
    final unpaidCount =
        invoices.where((i) => i.status == InvoiceStatus.unpaid).length;
    final draftCount =
        invoices.where((i) => i.status == InvoiceStatus.draft).length;

    return PremiumCard(
      isGlass: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Status Distribution',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 32),
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                      value: paidCount.toDouble(),
                      color: const Color(0xFF10B981),
                      title: 'Paid',
                      radius: 70,
                      titleStyle: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  PieChartSectionData(
                      value: unpaidCount.toDouble(),
                      color: const Color(0xFFF59E0B),
                      title: 'Unpaid',
                      radius: 70,
                      titleStyle: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  PieChartSectionData(
                      value: draftCount.toDouble(),
                      color: Colors.grey.shade400,
                      title: 'Draft',
                      radius: 70,
                      titleStyle: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentInvoices(
      BuildContext context, List<Invoice> invoices, String currency) {
    final recent = invoices.take(5).toList();

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text('Recent Invoices',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        overflow: TextOverflow.ellipsis)),
              ),
              TextButton(
                  onPressed: () =>
                      DefaultTabController.of(context).animateTo(1),
                  child: const Text('View All')),
            ],
          ),
          const SizedBox(height: 16),
          if (recent.isEmpty)
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: Text('No invoices yet')))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recent.length,
              separatorBuilder: (_, __) => Divider(
                  height: 24, color: Colors.grey.withValues(alpha: 0.1)),
              itemBuilder: (context, index) {
                final invoice = recent[index];
                final isPaid = invoice.status == InvoiceStatus.paid;

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isPaid
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            invoice.client.name[0],
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invoice.client.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              invoice.invoiceNumber,
                              style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade500 : Colors.blueGrey.shade400, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            AppFormatters.formatCurrency(
                                invoice.total, currency),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          PremiumStatusBadge(
                            status: invoice.status.name,
                            color: isPaid
                                ? Colors.green
                                : (invoice.status == InvoiceStatus.unpaid
                                    ? Colors.orange
                                    : Colors.grey),
                          ),
                        ],
                      ),
                      if (!isPaid) ...[
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => context
                              .read<InvoiceCubit>()
                              .updateStatus(invoice, InvoiceStatus.paid),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.green.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.green,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SummaryContent extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isDark;

  const _SummaryContent(
      {required this.title,
      required this.value,
      required this.icon,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 20),
        Text(title,
            style: TextStyle(
                color: isDark ? Colors.white70 : Colors.blueGrey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black)),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoice_flow/blocs/invoice_cubit.dart';
import 'package:invoice_flow/blocs/settings_cubit.dart';
import 'package:invoice_flow/models/invoice.dart';
import 'package:invoice_flow/screens/create_invoice_screen.dart';
import 'package:invoice_flow/utils/formatters.dart';
import 'package:invoice_flow/widgets/premium_widgets.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  InvoiceStatus? _filterStatus;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Invoices'),
        actions: [
          PopupMenuButton<InvoiceStatus?>(
            initialValue: _filterStatus,
            onSelected: (status) => setState(() => _filterStatus = status),
            icon: const Icon(Icons.tune),
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('All Statuses')),
              const PopupMenuDivider(),
              ...InvoiceStatus.values.map(
                (s) =>
                    PopupMenuItem(value: s, child: Text(s.name.toUpperCase())),
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: BlocBuilder<InvoiceCubit, InvoiceState>(
        builder: (context, state) {
          if (state is InvoiceLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is InvoiceLoaded) {
            final currency = context.watch<SettingsCubit>().state.currency;
            var invoices = state.invoices;

            if (_filterStatus != null) {
              invoices =
                  invoices.where((i) => i.status == _filterStatus).toList();
            }

            if (_searchQuery.isNotEmpty) {
              invoices = invoices
                  .where((i) =>
                      i.client.name
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()) ||
                      i.invoiceNumber
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()))
                  .toList();
            }

            return Column(
              children: [
                _buildSearchAndFilters(),
                Expanded(
                  child: invoices.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.all(32),
                          itemCount: invoices.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final invoice = invoices[index];
                            return _InvoiceListItem(
                                invoice: invoice, currency: currency);
                          },
                        ),
                ),
              ],
            );
          }
          return const Center(child: Text('Something went wrong'));
        },
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search clients, items or invoice IDs...',
                prefixIcon: const Icon(Icons.search, size: 20),
                fillColor: Theme.of(context).cardColor,
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PremiumCard(
            width: 300,
            child: Column(
              children: [
                Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty
                      ? 'No invoices found'
                      : 'No results for "$_searchQuery"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Try adjusting your search or filters.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.blueGrey)),
                if (_searchQuery.isEmpty) ...[
                  const SizedBox(height: 24),
                  PremiumButton(
                    label: 'Create Invoice',
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CreateInvoiceScreen())),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceListItem extends StatelessWidget {
  final Invoice invoice;
  final String currency;

  const _InvoiceListItem({required this.invoice, required this.currency});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => CreateInvoiceScreen(invoice: invoice)),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.description,
                    color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(invoice.client.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 12),
                        PremiumStatusBadge(
                          status: invoice.status.name,
                          color: invoice.status == InvoiceStatus.paid
                              ? Colors.green
                              : (invoice.status == InvoiceStatus.unpaid
                                  ? Colors.orange
                                  : Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                        '${invoice.invoiceNumber} • ${AppFormatters.formatDateShort(invoice.issueDate)}',
                        style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade500 : Colors.blueGrey.shade400, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppFormatters.formatCurrency(invoice.total, currency),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text(
                          'Due ${AppFormatters.formatDateShort(invoice.dueDate)}',
                          style: TextStyle(
                              fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade500 : Colors.blueGrey.shade400)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  if (invoice.status != InvoiceStatus.paid)
                    GestureDetector(
                      onTap: () => context
                          .read<InvoiceCubit>()
                          .updateStatus(invoice, InvoiceStatus.paid),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.green,
                          size: 18,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent),
                    onPressed: () => _showDeleteDialog(context),
                    tooltip: 'Delete Invoice',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Invoice?'),
        content: Text(
            'Are you sure you want to delete invoice #${invoice.invoiceNumber}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<InvoiceCubit>().deleteInvoice(invoice.id);
              Navigator.pop(ctx);
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

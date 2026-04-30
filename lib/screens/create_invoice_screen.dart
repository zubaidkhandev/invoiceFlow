import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoice_flow/blocs/client_cubit.dart';
import 'package:invoice_flow/blocs/invoice_cubit.dart';
import 'package:invoice_flow/blocs/settings_cubit.dart';
import 'package:invoice_flow/models/client.dart';
import 'package:invoice_flow/models/client_info.dart';
import 'package:invoice_flow/models/invoice.dart';
import 'package:invoice_flow/models/line_item.dart';
import 'package:invoice_flow/services/pdf_service.dart';
import 'package:invoice_flow/utils/formatters.dart';
import 'package:invoice_flow/widgets/premium_widgets.dart';
import 'package:uuid/uuid.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final Invoice? invoice;
  const CreateInvoiceScreen({super.key, this.invoice});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _id;
  late String _invoiceNumber;
  late DateTime _issueDate;
  late DateTime _dueDate;
  late List<LineItem> _items;
  double _taxPercentage = 0;

  final _clientNameController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _clientAddressController = TextEditingController();
  final _notesController = TextEditingController();
  final _taxController = TextEditingController(text: '0');
  bool _isGeneratingPdf = false;
  @override
  void initState() {
    super.initState();
    final editInvoice = widget.invoice;

    _id = editInvoice?.id ?? const Uuid().v4();
    _invoiceNumber =
        editInvoice?.invoiceNumber ?? AppFormatters.generateInvoiceNumber(0);
    _issueDate = editInvoice?.issueDate ?? DateTime.now();
    _dueDate =
        editInvoice?.dueDate ?? DateTime.now().add(const Duration(days: 7));
    _items = editInvoice?.items != null
        ? List.from(editInvoice!.items)
        : [LineItem.empty()];
    _taxPercentage = editInvoice?.taxPercentage ?? 0;

    _clientNameController.text = editInvoice?.client.name ?? '';
    _clientEmailController.text = editInvoice?.client.email ?? '';
    _clientAddressController.text = editInvoice?.client.address ?? '';
    _notesController.text = editInvoice?.notes ?? '';
    _taxController.text = _taxPercentage.toInt().toString();
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientEmailController.dispose();
    _clientAddressController.dispose();
    _notesController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  double get _subtotal => _items.fold(0, (sum, i) => sum + i.amount);
  double get _total => _subtotal + (_subtotal * (_taxPercentage / 100));

  void _addItem() => setState(() => _items.add(LineItem.empty()));
  void _removeItem(int index) => setState(() => _items.removeAt(index));

  Invoice _getCurrentInvoice(InvoiceStatus status) {
    final sender = context.read<SettingsCubit>().state.sender;
    return Invoice(
      id: _id,
      invoiceNumber: _invoiceNumber,
      issueDate: _issueDate,
      dueDate: _dueDate,
      sender: sender,
      client: ClientInfo(
        name: _clientNameController.text,
        email: _clientEmailController.text,
        address: _clientAddressController.text,
      ),
      items: _items,
      taxPercentage: _taxPercentage,
      notes: _notesController.text,
      status: status,
    );
  }

  Future<void> _saveInvoice(InvoiceStatus status) async {
    if (!_formKey.currentState!.validate()) return;

    final invoice = _getCurrentInvoice(status);
    await context.read<InvoiceCubit>().saveInvoice(invoice);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invoice saved as ${status.name}')));
      Navigator.pop(context);
    }
  }

  void _saveAsNewClient() {
    if (_clientNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Client name is required')));
      return;
    }
    final client = Client.newClient(
      name: _clientNameController.text,
      email: _clientEmailController.text,
      address: _clientAddressController.text,
    );
    context.read<ClientCubit>().saveClient(client);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client added to directory')));
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1100;
    final currency = context.watch<SettingsCubit>().state.currency;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        title: Text(widget.invoice == null ? 'Draft Invoice' : 'Edit Invoice',
            style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: PremiumButton(
              label: 'Generate PDF',
              icon: Icons.picture_as_pdf,
              isLoading: _isGeneratingPdf,
              gradientColors: const [Color(0xFFFED200), Color(0xFFD97706)],
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  setState(() => _isGeneratingPdf = true);
                  try {
                    await PdfService().downloadPdf(
                        _getCurrentInvoice(InvoiceStatus.draft), currency);
                  } finally {
                    if (mounted) setState(() => _isGeneratingPdf = false);
                  }
                }
              },
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildFormContent(currency)),
                        const SizedBox(width: 32),
                        Expanded(flex: 1, child: _buildSidebar(currency)),
                      ],
                    )
                  : Column(
                      children: [
                        _buildFormContent(currency),
                        const SizedBox(height: 32),
                        _buildSidebar(currency),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent(String currency) {
    return Column(
      children: [
        _buildSectionCard('Client Details', Icons.person_outline, [
          BlocBuilder<ClientCubit, ClientState>(
            builder: (context, state) {
              if (state is ClientLoaded && state.clients.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                        labelText: 'Select from Saved Clients',
                        prefixIcon: Icon(Icons.contacts_outlined)),
                    items: [
                      const DropdownMenuItem(
                          value: '', child: Text('Manual Entry')),
                      ...state.clients.map((c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.name))),
                    ],
                    onChanged: (val) {
                      if (val != null && val.isNotEmpty) {
                        final client =
                            state.clients.firstWhere((c) => c.id == val);
                        setState(() {
                          _clientNameController.text = client.name;
                          _clientEmailController.text = client.email;
                          _clientAddressController.text = client.address;
                        });
                      }
                    },
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Row(
            children: [
              Expanded(
                  child: _buildTextField('Client Name', _clientNameController,
                      isRequired: true)),
              const SizedBox(width: 16),
              Expanded(
                  child:
                      _buildTextField('Email Address', _clientEmailController)),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField('Billing Address', _clientAddressController,
              maxLines: 2),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _saveAsNewClient,
              icon: const Icon(Icons.person_add_alt, size: 18),
              label: const Text('Save to Clients Directory'),
            ),
          ),
        ]),
        const SizedBox(height: 32),
        _buildSectionCard('Invoice Items', Icons.list_alt, [
          ...List.generate(
              _items.length, (index) => _buildItemRow(index, currency)),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add New Item Line'),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary),
          ),
        ]),
        const SizedBox(height: 32),
        _buildSectionCard('Additional Notes', Icons.notes, [
          _buildTextField(
              'Terms, Conditions or Payment Instructions...', _notesController,
              maxLines: 4),
        ]),
      ],
    );
  }
  Widget _buildSidebar(String currency) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        PremiumCard(
          gradientColors: isDark 
            ? const [Color(0xFF030404), Color(0xFF1E293B)]
            : const [Color(0xFFFED200), Color(0xFFFFA000)], // Yellow gradient for light mode
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Invoice Summary',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              const SizedBox(height: 24),
              _buildSummaryRow(
                  'Subtotal', AppFormatters.formatCurrency(_subtotal, currency),
                  isDark: isDark),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tax (%)',
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: _taxController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          filled: false),
                      onChanged: (v) => setState(
                          () => _taxPercentage = double.tryParse(v) ?? 0),
                    ),
                  ),
                ],
              ),
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: Colors.white12)),
              _buildSummaryRow('Total Amount',
                  AppFormatters.formatCurrency(_total, currency),
                  isDark: isDark, isTotal: true),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PremiumCard(
          child: Column(
            children: [
              _buildDatePicker('Issue Date', _issueDate,
                  (date) => setState(() => _issueDate = date)),
              const SizedBox(height: 16),
              _buildDatePicker('Due Date', _dueDate,
                  (date) => setState(() => _dueDate = date)),
              const SizedBox(height: 32),
              PremiumButton(
                  label: 'Submit Invoice',
                  onPressed: () => _saveInvoice(InvoiceStatus.unpaid),
                  width: double.infinity),
              if (widget.invoice != null &&
                  widget.invoice!.status == InvoiceStatus.unpaid) ...[
                const SizedBox(height: 12),
                PremiumButton(
                  label: 'Mark as Paid',
                  icon: Icons.check_circle_outline,
                  gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
                  onPressed: () => _saveInvoice(InvoiceStatus.paid),
                  width: double.infinity,
                ),
              ],
              const SizedBox(height: 12),
              PremiumButton(
                  label: 'Save Draft',
                  isPrimary: false,
                  onPressed: () => _saveInvoice(InvoiceStatus.draft),
                  width: double.infinity),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isRequired = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
      validator: isRequired
          ? (v) => v?.isEmpty ?? true ? 'This field is required' : null
          : null,
    );
  }

  Widget _buildItemRow(int index, String currency) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = _items[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF030404),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('${index + 1}',
                  style: const TextStyle(
                      color: Color(0xFFFED200),
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 4,
            child: TextFormField(
              initialValue: item.description,
              decoration: InputDecoration(
                hintText: 'Item Description',
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => _items[index] = item.copyWith(description: v),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: TextFormField(
              initialValue: item.quantity.toString(),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Qty',
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _items[index] =
                  item.copyWith(quantity: double.tryParse(v) ?? 1)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: item.unitPrice.toString(),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Price',
                prefixText: AppFormatters.getCurrencySymbol(currency),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _items[index] =
                  item.copyWith(unitPrice: double.tryParse(v) ?? 0)),
            ),
          ),
          const SizedBox(width: 8),
          if (_items.length > 1)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _removeItem(index),
              style: IconButton.styleFrom(
                backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                padding: const EdgeInsets.all(8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isDark = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey,
                fontWeight: isTotal ? FontWeight.bold : null)),
        Text(value,
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: isTotal ? 22 : 16)),
      ],
    );
  }

  Widget _buildDatePicker(
      String label, DateTime current, Function(DateTime) onSelected) {
    return OutlinedButton(
      onPressed: () async {
        final date = await showDatePicker(
            context: context,
            initialDate: current,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100));
        if (date != null) onSelected(date);
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(color: Color.fromARGB(255, 211, 209, 209))),
          Text(AppFormatters.formatDateShort(current),
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

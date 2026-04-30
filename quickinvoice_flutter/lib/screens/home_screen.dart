import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/invoice_history_item.dart';
import '../services/invoice_store.dart';
import '../theme/app_theme.dart';
import 'invoice_detail_screen.dart';
import 'invoice_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _query = '';
  String _filter = 'All'; // All / Paid / Pending

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  List<InvoiceHistoryItem> _apply(List<InvoiceHistoryItem> all) {
    return all.where((it) {
      if (_filter == 'Paid' && !it.isPaid) return false;
      if (_filter == 'Pending' && it.isPaid) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return it.clientName.toLowerCase().contains(q) ||
          it.invoiceNumber.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InvoiceStore>(
      builder: (_, store, __) {
        final filtered = _apply(store.items);
        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: const Text('New Invoice'),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const InvoiceFormScreen()),
              );
              await store.reload();
            },
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: store.reload,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _header(store)),
                  SliverToBoxAdapter(child: _summaryRow(store)),
                  SliverToBoxAdapter(child: _searchAndTabs()),
                  if (store.loading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _empty(),
                    )
                  else
                    SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => Padding(
                        padding: EdgeInsets.fromLTRB(
                            AppTheme.s16,
                            0,
                            AppTheme.s16,
                            i == filtered.length - 1 ? 100 : 0),
                        child: _InvoiceTile(item: filtered[i]),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header(InvoiceStore store) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppTheme.s16, AppTheme.s16, AppTheme.s16, 0),
      padding: const EdgeInsets.all(AppTheme.s24),
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(AppTheme.rLg),
        boxShadow: AppTheme.softShadow(context),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting(),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                const Text('InovXA',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5)),
                const SizedBox(height: 2),
                const Text('Invoices made simple',
                    style:
                        TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            tooltip: isDark ? 'Light mode' : 'Dark mode',
            icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: Colors.white),
            onPressed: () => store.setThemeMode(
                isDark ? ThemeMode.light : ThemeMode.dark),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(InvoiceStore store) {
    final t = store.totals;
    final money = NumberFormat.compactCurrency(symbol: r'$').format(t.earnings);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.s16, AppTheme.s16, AppTheme.s16, 0),
      child: Row(
        children: [
          Expanded(
              child: _SummaryCard(
                  label: 'Earnings',
                  value: money,
                  icon: Icons.trending_up,
                  color: AppTheme.indigo)),
          const SizedBox(width: 10),
          Expanded(
              child: _SummaryCard(
                  label: 'Paid',
                  value: '${t.paidCount}',
                  icon: Icons.check_circle_outline,
                  color: AppTheme.success)),
          const SizedBox(width: 10),
          Expanded(
              child: _SummaryCard(
                  label: 'Pending',
                  value: '${t.pendingCount}',
                  icon: Icons.schedule,
                  color: AppTheme.warning)),
        ],
      ),
    );
  }

  Widget _searchAndTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.s16, AppTheme.s24, AppTheme.s16, AppTheme.s12),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by client or invoice #',
              prefixIcon: const Icon(Icons.search, size: 20),
            ),
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final f in const ['All', 'Paid', 'Pending'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: AppTheme.indigo,
                    labelStyle: TextStyle(
                      color: _filter == f
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined,
              size: 64, color: AppTheme.indigo),
          const SizedBox(height: 12),
          Text(
            _filter == 'All'
                ? 'No invoices yet'
                : 'No $_filter invoices',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap “New Invoice” to create your first one.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.subtle),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _SummaryCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.rMd),
        boxShadow: AppTheme.softShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.subtle)),
        ],
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  final InvoiceHistoryItem item;
  const _InvoiceTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final paid = item.isPaid;
    final color = paid ? AppTheme.success : AppTheme.warning;
    final date = DateFormat('dd MMM yyyy').format(item.date);
    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(AppTheme.rMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.rMd),
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => InvoiceDetailScreen(item: item),
          ));
          if (context.mounted) {
            await context.read<InvoiceStore>().reload();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.rMd),
            boxShadow: AppTheme.softShadow(context),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.indigo.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long,
                    color: AppTheme.indigo),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.clientName.isEmpty
                          ? 'Unknown client'
                          : item.clientName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text('${item.invoiceNumber}  •  $date',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.subtle)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${item.currency}${item.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      paid ? 'Paid' : 'Pending',
                      style: TextStyle(
                          color: color,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

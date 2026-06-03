import 'package:charms/HRmodels/schedule_exchange.dart';
import 'package:charms/HRproviders/schedule_exchanges.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PartTimerNotificationScreen extends StatefulWidget {
  final int staffId;

  const PartTimerNotificationScreen({
    super.key,
    required this.staffId,
  });

  @override
  State<PartTimerNotificationScreen> createState() =>
      _PartTimerNotificationScreenState();
}

class _PartTimerNotificationScreenState
    extends State<PartTimerNotificationScreen> {
  bool _isLoading = true;

  final Color _primary = const Color(0xFFF97316);
  final Color _bg = const Color(0xFFFFF7ED);
  final Color _cardBorder = const Color(0xFFFFE4C4);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    await Provider.of<ScheduleExchanges>(context, listen: false)
        .fetchExchangesByStaff(widget.staffId);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _respondToExchange(ScheduleExchange exchange, bool accept) async {
    final ok = await Provider.of<ScheduleExchanges>(context, listen: false)
        .targetRespond(exchange.exchangeId, accept);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? (accept
                ? 'Exchange accepted. Waiting HR approval.'
                : 'Exchange rejected.')
            : 'Failed to submit response.'),
        backgroundColor: ok ? (accept ? Colors.green : Colors.redAccent) : Colors.grey,
      ),
    );
    if (ok) {
      await _load();
      if (accept && mounted) {
        Navigator.pop(context, {'refreshDashboard': true});
      }
    }
  }

  Widget _exchangeCard(ScheduleExchange exchange) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${exchange.requesterName ?? 'Staff'} requested a schedule exchange',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Their shift: ${exchange.requesterWorkDate ?? '-'} (${exchange.requesterStartTime ?? '-'})',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            Text(
              'Your shift: ${exchange.targetWorkDate ?? '-'} (${exchange.targetStartTime ?? '-'})',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            if (exchange.requesterNote != null && exchange.requesterNote!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Note: ${exchange.requesterNote}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _respondToExchange(exchange, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Accept'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _respondToExchange(exchange, false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'NOTIFICATIONS',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<ScheduleExchanges>(
              builder: (context, exchanges, _) {
                final incoming = exchanges.exchanges
                    .where((e) => e.targetId == widget.staffId && e.status == 0)
                    .toList();

                if (incoming.isEmpty) {
                  return Center(
                    child: Text(
                      'No notifications right now',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: incoming.map(_exchangeCard).toList(),
                  ),
                );
              },
            ),
    );
  }
}

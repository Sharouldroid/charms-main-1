import 'package:charms/models/groupmembers.dart';
import 'package:charms/models/optionalitem_cart.dart';
import 'package:charms/models/specialbooking_cart.dart';
import 'package:charms/models/user.dart';
import 'package:charms/providers/events_special.dart';
import 'package:charms/widgets/cart/checkout_addon.dart';
import 'package:charms/widgets/cart/checkout_itemspecial.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/utils/responsive_helper.dart';

class SpecialCheckoutScreen extends StatefulWidget {
  const SpecialCheckoutScreen({
    super.key,
    required this.hostname,
    required this.pax,
    required this.ischecked,
    required this.user,
    required this.startdate,
    required this.enddate,
    required this.needboat,
    required this.affiliatetitle,
    required this.department,
    required this.institution,
    required this.location,
    required this.filename,
  });

  final String hostname;
  final int pax;
  final String ischecked;
  final User user;
  final String startdate;
  final String enddate;
  final int needboat;
  final String affiliatetitle;
  final String department;
  final String institution;
  final String location;
  final String filename;

  @override
  State<SpecialCheckoutScreen> createState() => _SpecialCheckoutScreenState();
}

class _SpecialCheckoutScreenState extends State<SpecialCheckoutScreen> {
  bool _isProcessing = false;

  Future<void> _submitApplication() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    final cartK = Provider.of<SpecialBookingCartOut>(context, listen: false);
    final cartI = Provider.of<OptionalItemCartOut>(context, listen: false);
    final cartG = Provider.of<GroupMembersOut>(context, listen: false);
    final eventsSpecial = Provider.of<EventsSpecial>(context, listen: false);
    final userId = int.parse(widget.user.id);
    final totalAmount = cartK.totalAmount + cartI.totalAmount;

    try {
      // Main booking
      await eventsSpecial.applyRSS(
        widget.hostname,
        userId,
        widget.pax,
        widget.startdate,
        widget.enddate,
        widget.needboat,
        totalAmount.toInt(),
      );

      // Indemnity agreement
      await eventsSpecial.indemnityRSS(
        widget.hostname,
        userId,
        'Agreed',
        0, // 0 for applicant, 1 for all members
      );

      // Process optional items
      await _processOptionalItems(cartI, eventsSpecial);

      // Process group members
      await _processGroupMembers(cartG, eventsSpecial);

      // Store affiliation information
      await eventsSpecial.storeRSSAffiliation(
        widget.hostname,
        widget.affiliatetitle,
        widget.department,
        widget.institution,
        widget.location,
        widget.filename,
        userId,
      );

      // Clear carts and navigate
      _clearCartsAndNavigate(cartK, cartI, cartG);
    } catch (error) {
      _showErrorFeedback(error);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _processOptionalItems(
    OptionalItemCartOut cartI,
    EventsSpecial eventsSpecial,
  ) async {
    if (cartI.itemCount == 0) return;

    for (final item in cartI.items.values) {
      await eventsSpecial.addonRSS(
        widget.hostname,
        item.itemname,
        item.quantity,
        int.parse(widget.user.id),
        item.price,
      );
    }
  }

  Future<void> _processGroupMembers(
    GroupMembersOut cartG,
    EventsSpecial eventsSpecial,
  ) async {
    if (cartG.itemCount == 0) return;

    for (final member in cartG.items.values) {
      await eventsSpecial.addRSSGroup(
        widget.hostname,
        member.name,
        member.idnum,
        member.email,
        int.parse(widget.user.id),
      );
    }
  }

  void _clearCartsAndNavigate(
    SpecialBookingCartOut cartK,
    OptionalItemCartOut cartI,
    GroupMembersOut cartG,
  ) {
    cartK.clear();
    cartI.clear();
    cartG.clear();

    if (mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
    }
  }

  void _showErrorFeedback(dynamic error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartK = Provider.of<SpecialBookingCartOut>(context);
    final cartI = Provider.of<OptionalItemCartOut>(context);
    final totalAmount = (cartK.totalAmount + cartI.totalAmount).toStringAsFixed(
      2,
    );
    final maxWidth = ResponsiveHelper.getMaxContentWidth(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Special Slot Confirmation')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildBookingItemsList(cartK),
                _buildOptionalItemsList(cartI),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(totalAmount),
    );
  }

  Widget _buildBookingItemsList(SpecialBookingCartOut cartK) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cartK.itemCount,
      itemBuilder:
          (_, i) => CheckoutItemSpecial(
            id: cartK.items.keys.toList()[i],
            eventname: cartK.items.values.toList()[i].eventname.toString(),
            price: cartK.totalAmount.toInt(),
            pax: cartK.items.values.toList()[i].pax,
            indemnities: cartK.items.values.toList()[i].indemnities,
            eventprice: cartK.items.values.toList()[i].eventprice,
            boatprice: cartK.items.values.toList()[i].boatprice,
            startdate: cartK.items.values.toList()[i].startdate,
            enddate: cartK.items.values.toList()[i].enddate,
          ),
    );
  }

  Widget _buildOptionalItemsList(OptionalItemCartOut cartI) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cartI.itemCount,
      itemBuilder:
          (_, i) => CheckoutAddon(
            id: cartI.items.keys.toList()[i],
            itemname: cartI.items.values.toList()[i].itemname,
            price: cartI.items.values.toList()[i].price,
            quantity: cartI.items.values.toList()[i].quantity,
          ),
    );
  }

  Widget _buildBottomBar(String totalAmount) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: Chip(
                label: Text(
                  'Total: RM $totalAmount',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _submitApplication,
                label: Text(
                  _isProcessing ? 'Processing...' : 'Apply Researcher Slot',
                ),
                icon:
                    _isProcessing
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                        : const Icon(Icons.save),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

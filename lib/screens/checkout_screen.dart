// <--- Required for Uint8List
import 'package:charms/models/booking_cart.dart';
import 'package:charms/models/groupmembers.dart';
import 'package:charms/models/optionalitem_cart.dart';
import 'package:charms/models/user.dart';
import 'package:charms/providers/bookevents.dart';
import 'package:charms/providers/events_researcher.dart';
import 'package:charms/providers/indemnities.dart';
import 'package:charms/providers/optionalitems.dart';
import 'package:charms/providers/stripe_service.dart';
import 'package:charms/widgets/cart/checkout_addon.dart';
import 'package:charms/widgets/cart/checkout_item.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:charms/utils/save_file_dialog.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart'; // Required for TapGestureRecognizer
import 'package:url_launcher/url_launcher.dart'; // Required to open the link

// Define PaymentMethod enum
enum PaymentMethod { stripe, qrCode }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.confirmnum,
    required this.hostname,
    required this.pax,
    required this.ischecked,
    required this.user,
    required this.eventid,
    required this.booktype,
    this.shirtsize = '',
    required this.staff,
    required this.volres,
  });

  final int confirmnum;
  final String hostname;
  final int pax;
  final String ischecked;
  final User user;
  final int eventid;
  final int booktype;
  final String shirtsize;
  final bool staff;
  final int volres;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isProcessing = false;
  bool _isUploadingProof = false;
  bool _hasBookingBeenCreated = false;
  XFile? _proofOfPaymentFile;
  String? _fileName;
  String? _uploadError;

  PaymentMethod _selectedPaymentMethod = PaymentMethod.stripe;

  static const String qrCodeImagePath = 'assets/images/cmsQR.jpeg';
  static String qrCodeReference = 'SEATRU-${DateTime.now().year}';

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickProofOfPayment(StateSetter setDialogState) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 30,
        maxWidth: 1080,
      );

      if (image != null) {
        _proofOfPaymentFile = image;
        _fileName = image.name;
        _uploadError = null;
        setDialogState(() {});
      }
    } catch (e) {
      setDialogState(() {
        _uploadError = 'Failed to pick file: $e';
      });
    }
  }

  Future<void> _uploadProofOfPayment(
    BuildContext dialogContext,
    StateSetter setDialogState,
  ) async {
    if (_proofOfPaymentFile == null) {
      setDialogState(() {
        _uploadError = 'Please select a proof of payment file';
      });
      return;
    }

    setDialogState(() {
      _isUploadingProof = true;
      _uploadError = null;
    });

    try {
      if (!_hasBookingBeenCreated) {
        try {
          await _processBookingWithoutPayment(navigate: false);
          _hasBookingBeenCreated = true;
        } catch (e) {
          setDialogState(() {
            _uploadError = 'Booking creation failed: $e';
            _isUploadingProof = false;
          });
          return;
        }
      }

      final cartK = Provider.of<BookingCartOut>(context, listen: false);
      final cartI = Provider.of<OptionalItemCartOut>(context, listen: false);
      final totalAmount = (cartK.totalAmount + cartI.totalAmount)
          .toStringAsFixed(2);

      var uri = Uri.parse(
        'https://devcms.com.my/charmsAPI/api/receipt/upload-receipt',
      );
      var request = http.MultipartRequest('POST', uri);

      request.fields['confirmnum'] = widget.confirmnum.toString();
      request.fields['amount'] = totalAmount;

      request.files.add(
        http.MultipartFile.fromBytes(
          'receipt',
          await _proofOfPaymentFile!.readAsBytes(),
          filename: _fileName,
        ),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.of(dialogContext).pop();
          final cartG = Provider.of<GroupMembersOut>(context, listen: false);
          _clearCartsAndNavigate(cartK, cartI, cartG);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setDialogState(() {
          _uploadError = 'Server Error: ${response.statusCode} - $responseData';
          _isUploadingProof = false;
        });
      }
    } catch (e) {
      setDialogState(() {
        _uploadError = 'Connection error: $e';
        _isUploadingProof = false;
      });
    }
  }

  void _showPaymentMethodDialog() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: const [
                Icon(Icons.payment, color: Colors.blue, size: 28),
                SizedBox(width: 12),
                Flexible(
                  child: Text('Select Payment Method'),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPaymentMethodCard(
                    ctx,
                    icon: Icons.credit_card,
                    color: Colors.blue,
                    title: 'Online Payment',
                    subtitle: 'Credit/Debit Card and FPX',
                    method: PaymentMethod.stripe,
                    onTap: () {
                      setState(() {
                        _selectedPaymentMethod = PaymentMethod.stripe;
                      });
                      Navigator.of(ctx).pop();
                      _showPaymentDeclaration(PaymentMethod.stripe);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentMethodCard(
                    ctx,
                    icon: Icons.qr_code_scanner,
                    color: Colors.green,
                    title: 'QR Code Payment',
                    subtitle: 'Scan QR code to pay',
                    method: PaymentMethod.qrCode,
                    onTap: () {
                      setState(() {
                        _selectedPaymentMethod = PaymentMethod.qrCode;
                      });
                      Navigator.of(ctx).pop();
                      _showPaymentDeclaration(PaymentMethod.qrCode);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  Widget _buildPaymentMethodCard(
    BuildContext ctx, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required PaymentMethod method,
    required VoidCallback onTap,
  }) {
    final isSelected = _selectedPaymentMethod == method;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? color.withOpacity(0.05) : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            Radio<PaymentMethod>(
              value: method,
              groupValue: _selectedPaymentMethod,
              onChanged: (value) => onTap(),
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }

  void _showQRCodePaymentDialog() {
    final cartK = Provider.of<BookingCartOut>(context, listen: false);
    final cartI = Provider.of<OptionalItemCartOut>(context, listen: false);
    final totalAmount = (cartK.totalAmount + cartI.totalAmount).toStringAsFixed(
      2,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setStateSB) {
              return AlertDialog(
                title: const Text('QR Code Payment'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Please scan the QR code below to complete your payment.',
                        style: TextStyle(fontSize: 14, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.asset(
                          qrCodeImagePath,
                          width: 200,
                          height: 200,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 200,
                              height: 200,
                              color: Colors.grey.shade200,
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.qr_code,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text('QR Code Image'),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextButton.icon(
                        onPressed:
                            _saveQrCodeToStorage, // <--- Call the new function
                        icon: const Icon(
                          Icons.save_alt_rounded,
                        ), // Changed icon to represent "Storage"
                        label: const Text('Download QR to Storage'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue[700],
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Payment Details:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Amount:'),
                                Text(
                                  'RM $totalAmount',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Reference:'),
                                Text(
                                  qrCodeReference,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Booking ID:'),
                                Text(
                                  '${widget.confirmnum}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Upload Proof of Payment:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Please upload a screenshot or photo of your payment confirmation.',
                              style: TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed:
                                  _isUploadingProof
                                      ? null
                                      : () => _pickProofOfPayment(setStateSB),
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Select Proof File'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_proofOfPaymentFile != null)
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.green.shade100,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _fileName ?? 'Proof file selected',
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _proofOfPaymentFile = null;
                                          _fileName = null;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            if (_uploadError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _uploadError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Important: After completing the payment via QR code, please upload your proof of payment above.',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed:
                        _isUploadingProof
                            ? null
                            : () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed:
                        (_proofOfPaymentFile != null && !_isUploadingProof)
                            ? () => _uploadProofOfPayment(ctx, setStateSB)
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      disabledBackgroundColor: Colors.orange.shade200,
                    ),
                    child:
                        _isUploadingProof
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text('Upload & Confirm Payment'),
                  ),
                ],
              );
            },
          ),
    );
  }

void _showPaymentDeclaration(PaymentMethod method) {
    final bool isStripe = method == PaymentMethod.stripe;

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Column(
              children: const [
                Icon(Icons.info_outline, color: Colors.blue, size: 48),
                SizedBox(height: 12),
                Text(
                  'Payment Declaration',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: const Text(
                      'UMT Sea Turtle Conservation Program is managed by Conservation Management Solutions Sdn Bhd, a commercial wing appointed by SEATRU (Sea Turtle Research Unit) to oversee the operational aspects of the volunteer program.\n\n'
                      'Our primary goal is to ensure a seamless and impactful experience for all participants while actively supporting SEATRU\'s essential sea turtle conservation mission.\n\n'
                      'If you have any inquiries, please contact us.',
                      style: TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.verified_user,
                          color: Colors.orange,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'By proceeding, you agree to this declaration',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // -------------------------------------------------------
                  // START: Added Privacy Policy Link for Stripe Users
                  // -------------------------------------------------------
                  if (isStripe) ...[
                    const SizedBox(height: 16),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Payments are securely processed by Stripe. By continuing, you agree to our ',
                          ),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                // Privacy Policy URL
                                final Uri url = Uri.parse('http://conservems.my/PrivacyPolicyCHARMs/PrivacyPolicy.html');
                                if (!await launchUrl(url)) {
                                  throw Exception('Could not launch $url');
                                }
                              },
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ],
                  // -------------------------------------------------------
                  // END: Added Privacy Policy Link
                  // -------------------------------------------------------
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  if (isStripe) {
                    _processBookingAndPayment();
                  } else if (method == PaymentMethod.qrCode) {
                    _showQRCodePaymentDialog();
                  }
                },
                icon: Icon(
                  isStripe ? Icons.payment : Icons.arrow_forward,
                  size: 18,
                ),
                label: Text(isStripe ? 'Agree & Pay' : 'Agree & Proceed'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _processBookingWithoutPayment({bool navigate = true}) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    final cartK = Provider.of<BookingCartOut>(context, listen: false);
    final cartI = Provider.of<OptionalItemCartOut>(context, listen: false);
    final cartG = Provider.of<GroupMembersOut>(context, listen: false);

    final totalAmount = (cartK.totalAmount + cartI.totalAmount).toStringAsFixed(
      2,
    );
    final userId = int.parse(widget.user.id);

    try {
      if (widget.volres == 1) {
        await _processRegularBooking(cartK, cartI, cartG, userId, totalAmount);
      } else {
        await _processResearcherBooking(
          cartK,
          cartI,
          cartG,
          userId,
          totalAmount,
        );
      }

      if (navigate) {
        _clearCartsAndNavigate(cartK, cartI, cartG);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Booking submitted! Your payment proof has been uploaded. Your booking will be confirmed once payment is verified.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (error) {
      _showErrorFeedback(error);
      rethrow;
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _processBookingAndPayment() async {
    if (_isProcessing) return;

    if (_selectedPaymentMethod != PaymentMethod.stripe) {
      _showPaymentMethodDialog();
      return;
    }

    setState(() => _isProcessing = true);

    final cartK = Provider.of<BookingCartOut>(context, listen: false);
    final cartI = Provider.of<OptionalItemCartOut>(context, listen: false);
    final cartG = Provider.of<GroupMembersOut>(context, listen: false);

    final totalAmount = (cartK.totalAmount + cartI.totalAmount).toStringAsFixed(
      2,
    );
    final userId = int.parse(widget.user.id);

    try {
      if (widget.volres == 1) {
        await _processRegularBooking(cartK, cartI, cartG, userId, totalAmount);
      } else {
        await _processResearcherBooking(
          cartK,
          cartI,
          cartG,
          userId,
          totalAmount,
        );
      }

      if (_selectedPaymentMethod == PaymentMethod.stripe) {
        await _processPayment(cartK, cartI, userId);
      }

      _clearCartsAndNavigate(cartK, cartI, cartG);
    } catch (error) {
      _showErrorFeedback(error);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _processRegularBooking(
    BookingCartOut cartK,
    OptionalItemCartOut cartI,
    GroupMembersOut cartG,
    int userId,
    String totalAmount,
  ) async {
    String diet = 'None';
    String health = 'No Health Issue';
    Uint8List? signature; // <--- Signature variable

    if (cartK.items.isNotEmpty) {
      var item = cartK.items.values.first;
      diet = item.diet;
      health = item.health;
      signature = item.signature; // <--- EXTRACT SIGNATURE
    }

    await Provider.of<BookEvents>(context, listen: false).createBooking(
      widget.hostname,
      userId,
      widget.pax,
      widget.eventid,
      widget.confirmnum,
      0,
      widget.booktype,
      widget.shirtsize,
      double.parse(totalAmount),
      diet,
      health,
    );

    // Pass signature here
    await _addIndemnities(userId, signature);
    await _processOptionalItems(cartI, userId);
    await _processGroupMembers(cartG, userId);
  }

  Future<void> _processResearcherBooking(
    BookingCartOut cartK,
    OptionalItemCartOut cartI,
    GroupMembersOut cartG,
    int userId,
    String totalAmount,
  ) async {
    Uint8List? signature; // <--- Signature variable

    if (cartK.items.isNotEmpty) {
      var item = cartK.items.values.first;
      signature = item.signature; // <--- EXTRACT SIGNATURE
    }

    final researcherEvents = Provider.of<ResearcherEvents>(
      context,
      listen: false,
    );

    await researcherEvents.createBooking(
      widget.hostname,
      userId,
      widget.pax,
      widget.eventid,
      widget.confirmnum,
      0,
      widget.booktype,
      widget.shirtsize,
      double.parse(totalAmount),
    );

    // Pass signature here
    await _addIndemnities(userId, signature);

    await _processResearcherOptionalItems(cartI, userId);
    await _processResearcherGroupMembers(cartG, userId);
  }

  Future<void> _addIndemnities(int userId, Uint8List? signature) async {
    await Provider.of<Indemnitites>(
      context,
      listen: false,
    ).addIndemnitiestoBooking(
      widget.hostname,
      userId,
      'Agreed',
      widget.confirmnum,
      signature, // <--- Pass the extracted signature
    );
  }

  Future<void> _processOptionalItems(
    OptionalItemCartOut cartI,
    int userId,
  ) async {
    if (cartI.itemCount == 0) return;

    final optionalItems = Provider.of<Optionalitems>(context, listen: false);

    for (final item in cartI.items.values) {
      await optionalItems.purchaseOptionalItem(
        widget.hostname,
        item.itemname,
        item.price,
        userId,
        item.quantity,
        widget.confirmnum,
      );
    }
  }

  Future<void> _processResearcherOptionalItems(
    OptionalItemCartOut cartI,
    int userId,
  ) async {
    if (cartI.itemCount == 0) return;

    final researcherEvents = Provider.of<ResearcherEvents>(
      context,
      listen: false,
    );

    for (final item in cartI.items.values) {
      await researcherEvents.purchaseOptionalItem(
        widget.hostname,
        item.itemname,
        item.price,
        userId,
        item.quantity,
        widget.confirmnum,
      );
    }
  }

  Future<void> _processGroupMembers(GroupMembersOut cartG, int userId) async {
    if (cartG.itemCount == 0) return;

    final bookEvents = Provider.of<BookEvents>(context, listen: false);

    for (final member in cartG.items.values) {
      await bookEvents.addBookingGroup(
        widget.hostname,
        member.name,
        member.idnum,
        member.email,
        member.eventid,
        widget.confirmnum,
        member.shirtsize,
        member.diet,
        member.health,
      );
    }
  }

  Future<void> _processResearcherGroupMembers(
    GroupMembersOut cartG,
    int userId,
  ) async {
    if (cartG.itemCount == 0) return;

    final researcherEvents = Provider.of<ResearcherEvents>(
      context,
      listen: false,
    );

    for (final member in cartG.items.values) {
      await researcherEvents.addBookingGroup(
        widget.hostname,
        member.name,
        member.idnum,
        member.email,
        member.eventid,
        widget.confirmnum,
        member.shirtsize,
      );
    }
  }

  Future<void> _processPayment(
    BookingCartOut cartK,
    OptionalItemCartOut cartI,
    int userId,
  ) async {
    if (_selectedPaymentMethod == PaymentMethod.stripe) {
      await Provider.of<StripeService>(context, listen: false).makePayment(
        widget.hostname,
        (cartK.totalAmount + cartI.totalAmount),
        widget.confirmnum,
        widget.volres,
        widget.eventid,
        userId,
      );
    }
  }

  // --- NEW FUNCTION: Save QR Code to File Storage (Downloads/Files) ---
  Future<void> _saveQrCodeToStorage() async {
    try {
      // 1. Load the image bytes from assets
      final ByteData byteData = await rootBundle.load(qrCodeImagePath);
      final Uint8List bytes = byteData.buffer.asUint8List();

      // 2. Ask the user where to save the file (native "Save As" dialog on
      // mobile/desktop; triggers a browser download on web)
      final finalPath = await saveFileWithDialog(
        bytes: bytes,
        fileName: 'cms_payment_qr.jpg',
      );

      // 3. Check if the user successfully saved the file
      if (finalPath != null && mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.folder_open, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('QR Code saved to your Storage!')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // User cancelled the dialog
        // Optional: Show a "Cancelled" message or do nothing
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error saving file: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _clearCartsAndNavigate(
    BookingCartOut cartK,
    OptionalItemCartOut cartI,
    GroupMembersOut cartG,
  ) {
    cartK.clear();
    cartI.clear();
    cartG.clear();

    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/dashboard',
        (Route<dynamic> route) => false,
        arguments: {'showReminder': true},
      );
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
    final cartK = Provider.of<BookingCartOut>(context);
    final cartI = Provider.of<OptionalItemCartOut>(context);
    final totalAmount = (cartK.totalAmount + cartI.totalAmount).toStringAsFixed(
      2,
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.shopping_cart_checkout, size: 24),
            SizedBox(width: 8),
            Text('Checkout'),
          ],
        ),
      ),
       body: SingleChildScrollView(
            child: Column(
              children: [
                _buildBookingItemsList(cartK),
                _buildOptionalItemsList(cartI),
                _buildPaymentMethodIndicator(),
              ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(totalAmount),
    );
  }

  Widget _buildPaymentMethodIndicator() {
    final methodColor =
        _selectedPaymentMethod == PaymentMethod.stripe
            ? Colors.blue
            : Colors.green;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: methodColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: methodColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _selectedPaymentMethod == PaymentMethod.stripe
                  ? Icons.credit_card
                  : Icons.qr_code_scanner,
              color: methodColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedPaymentMethod == PaymentMethod.stripe
                      ? 'Online Payment'
                      : 'QR Code Payment',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _showPaymentMethodDialog,
            icon: const Icon(Icons.swap_horiz, size: 18),
            label: const Text('Change'),
            style: ElevatedButton.styleFrom(
              backgroundColor: methodColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingItemsList(BookingCartOut cartK) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cartK.itemCount,
      itemBuilder:
          (_, i) => CheckoutItem(
            id: cartK.items.keys.toList()[i],
            eventname: cartK.items.values.toList()[i].eventname.toString(),
            price: cartK.items.values.toList()[i].price,
            confirmnum: cartK.items.values.toList()[i].confirmnum,
            pax: cartK.items.values.toList()[i].pax,
            userid: cartK.items.values.toList()[i].userid,
            booktype: cartK.items.values.toList()[i].booktype,
            indemnities: cartK.items.values.toList()[i].indemnities,
            shirtsize: cartK.items.values.toList()[i].shirtsize,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'RM $totalAmount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _showPaymentMethodDialog,
                  icon:
                      _isProcessing
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                          : const Icon(Icons.payment, size: 22),
                  label: Text(
                    _isProcessing ? 'Processing...' : 'Proceed to Payment',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

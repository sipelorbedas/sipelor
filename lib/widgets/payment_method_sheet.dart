import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentMethodSheet extends StatefulWidget {
  final String? initialMethod;
  final Function(String method)? onConfirm;

  const PaymentMethodSheet({super.key, this.initialMethod, this.onConfirm});

  @override
  State<PaymentMethodSheet> createState() => _PaymentMethodSheetState();
}

class _PaymentMethodSheetState extends State<PaymentMethodSheet> {
  String? _selectedMethod;

  final List<Map<String, String>> _bankTransfers = [
    {'name': 'BJB', 'logo': 'assets/images/logo_bjb.png'},
    {'name': 'BRI', 'logo': 'assets/images/logo_bri.png'},
    {'name': 'Mandiri', 'logo': 'assets/images/logo_mandiri.png'},
  ];

  final List<Map<String, String>> _ewallets = [
    {'name': 'OVO', 'logo': 'assets/images/logo_ovo.png'},
    {'name': 'DANA', 'logo': 'assets/images/logo_dana.png'},
    {'name': 'GOPAY', 'logo': 'assets/images/logo_gopay.png'},
    {'name': 'LINKAJA', 'logo': 'assets/images/logo_linkaja.png'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.initialMethod;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Text(
              'Pilih Metode Pembayaran',
              style: GoogleFonts.mulish(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3F414E),
              ),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // QRIS Section
                  Text(
                    'Pembayaran Digital',
                    style: GoogleFonts.mulish(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF3F414E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildQRISOption(),

                  // Divider
                  const Divider(height: 32, color: Color(0x1A000000)),

                  // Transfer Bank Section
                  Text(
                    'Transfer Bank',
                    style: GoogleFonts.mulish(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF3F414E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: _bankTransfers
                        .map(
                          (bank) =>
                              _buildPaymentOption(bank['name']!, bank['logo']!),
                        )
                        .toList(),
                  ),

                  // Divider
                  const Divider(height: 32, color: Color(0x1A000000)),

                  // Transfer E-Wallet Section
                  Text(
                    'Transfer E-Wallet',
                    style: GoogleFonts.mulish(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF3F414E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: _ewallets
                        .map(
                          (wallet) => _buildPaymentOption(
                            wallet['name']!,
                            wallet['logo']!,
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Confirm button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  offset: const Offset(0, -4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedMethod != null
                      ? () {
                          if (widget.onConfirm != null) {
                            widget.onConfirm!(_selectedMethod!);
                          }
                          Navigator.pop(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedMethod != null
                        ? const Color.fromARGB(255, 0, 113, 72)
                        : Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Pilih',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _selectedMethod != null
                          ? Colors.white
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String name, String logoPath) {
    final isSelected = _selectedMethod == name;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = name;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Logo
            Image.asset(
              logoPath,
              width: name == 'BJB' ? 70 : 51,
              height: name == 'BJB' ? 28 : 16,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 11),

            // Name
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.mulish(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF3F414E),
                ),
              ),
            ),

            // Radio button
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color.fromARGB(255, 0, 113, 72)
                      : Colors.grey[400]!,
                  width: 2,
                ),
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 0, 113, 72),
                          Color.fromARGB(255, 0, 117, 164),
                        ],
                      )
                    : null,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.check, size: 14, color: Colors.white),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRISOption() {
    final isSelected = _selectedMethod == 'QRIS';

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = 'QRIS';
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // QRIS Logo
            Image.asset(
              'assets/images/QRIS.png',
              width: 50,
              height: 40,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 11),

            // Name
            Expanded(
              child: Text(
                'QRIS',
                style: GoogleFonts.mulish(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF3F414E),
                ),
              ),
            ),

            // Radio button
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color.fromARGB(255, 0, 113, 72)
                      : Colors.grey[400]!,
                  width: 2,
                ),
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 0, 113, 72),
                          Color.fromARGB(255, 0, 117, 164),
                        ],
                      )
                    : null,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.check, size: 14, color: Colors.white),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

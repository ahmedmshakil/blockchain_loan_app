import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:blockchain_loan_app/widgets/blockchain_status_indicator.dart';

class LoanInfoCard extends StatefulWidget {
  final String interestRate;
  final String maxTerm;
  final String approvalType;
  final String maxLoanAmount;
  final bool isBlockchainVerified;
  final Function(String)? onLoanApply;
  final bool isLoading;
  final String? errorMessage;

  const LoanInfoCard({
    Key? key,
    this.interestRate = '12.5%',
    this.maxTerm = '12 months',
    this.approvalType = 'Instant Approval',
    required this.maxLoanAmount,
    this.isBlockchainVerified = false,
    this.onLoanApply,
    this.isLoading = false,
    this.errorMessage,
  }) : super(key: key);

  @override
  State<LoanInfoCard> createState() => _LoanInfoCardState();
}

class _LoanInfoCardState extends State<LoanInfoCard> {
  final TextEditingController _amountController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Loan Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
                if (widget.isBlockchainVerified)
                  const BlockchainStatusIndicator(),
              ],
            ),
            const SizedBox(height: 16),

            // Loan Terms Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildLoanTermRow('Interest Rate', widget.interestRate),
                  const SizedBox(height: 8),
                  _buildLoanTermRow('Approval', widget.approvalType),
                  const SizedBox(height: 8),
                  _buildLoanTermRow('Max Term', widget.maxTerm),
                  const SizedBox(height: 8),
                  _buildLoanTermRow('Max Amount', '৳${widget.maxLoanAmount}'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Loan Application Form
            const Text(
              'Apply For Loan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Loan Amount (৳)',
                      hintText: 'Enter amount up to ৳${widget.maxLoanAmount}',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.monetization_on),
                      errorText: widget.errorMessage,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter loan amount';
                      }
                      final amount = int.tryParse(value);
                      if (amount == null) {
                        return 'Please enter a valid amount';
                      }
                      final maxAmount = int.tryParse(
                        widget.maxLoanAmount.replaceAll(',', ''),
                      );
                      if (maxAmount != null && amount > maxAmount) {
                        return 'Amount exceeds maximum limit';
                      }
                      if (amount <= 0) {
                        return 'Amount must be greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.isLoading || widget.onLoanApply == null
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                widget.onLoanApply!(_amountController.text);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: widget.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Apply Now',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanTermRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1565C0),
          ),
        ),
      ],
    );
  }
}

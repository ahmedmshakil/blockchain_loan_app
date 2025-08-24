import 'package:flutter/material.dart';
import 'package:blockchain_loan_app/widgets/blockchain_status_indicator.dart';

class AccountCard extends StatelessWidget {
  final String accountHolderName;
  final String nid;
  final String profession;
  final String accountBalance;
  final bool isBlockchainVerified;
  final VoidCallback? onViewDetails;
  final bool isLoading;

  const AccountCard({
    Key? key,
    required this.accountHolderName,
    required this.nid,
    required this.profession,
    required this.accountBalance,
    this.isBlockchainVerified = false,
    this.onViewDetails,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Account Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
                if (isBlockchainVerified)
                  const BlockchainStatusIndicator(),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else ...[
              _buildInfoRow('Account Holder', accountHolderName),
              const SizedBox(height: 12),
              _buildInfoRow('NID', nid),
              const SizedBox(height: 12),
              _buildInfoRow('Profession', profession),
              const SizedBox(height: 12),
              _buildInfoRow('Account Balance', '৳$accountBalance'),
              const SizedBox(height: 20),
              if (onViewDetails != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onViewDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'View Full Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
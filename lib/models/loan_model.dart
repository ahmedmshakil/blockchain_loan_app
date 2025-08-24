import 'dart:math' as math;

enum LoanStatus {
  pending,
  approved,
  rejected,
  active,
  completed,
  defaulted,
}

enum LoanType {
  personal,
  business,
  emergency,
  education,
}

class LoanModel {
  final String id;
  final String borrowerNid;
  final BigInt requestedAmount;
  final BigInt approvedAmount;
  final double interestRate;
  final int termMonths;
  final LoanStatus status;
  final LoanType type;
  final DateTime applicationDate;
  final DateTime? approvalDate;
  final DateTime? disbursementDate;
  final String? transactionHash;
  final String? rejectionReason;
  final BigInt remainingBalance;
  final BigInt monthlyPayment;
  final int creditScoreAtApplication;

  const LoanModel({
    required this.id,
    required this.borrowerNid,
    required this.requestedAmount,
    required this.approvedAmount,
    required this.interestRate,
    required this.termMonths,
    required this.status,
    required this.type,
    required this.applicationDate,
    this.approvalDate,
    this.disbursementDate,
    this.transactionHash,
    this.rejectionReason,
    required this.remainingBalance,
    required this.monthlyPayment,
    required this.creditScoreAtApplication,
  });

  // Factory constructor for creating from JSON
  factory LoanModel.fromJson(Map<String, dynamic> json) {
    return LoanModel(
      id: json['id'] as String,
      borrowerNid: json['borrowerNid'] as String,
      requestedAmount: BigInt.parse(json['requestedAmount'].toString()),
      approvedAmount: BigInt.parse(json['approvedAmount'].toString()),
      interestRate: (json['interestRate'] as num).toDouble(),
      termMonths: json['termMonths'] as int,
      status: LoanStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => LoanStatus.pending,
      ),
      type: LoanType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => LoanType.personal,
      ),
      applicationDate: DateTime.parse(json['applicationDate'] as String),
      approvalDate: json['approvalDate'] != null
          ? DateTime.parse(json['approvalDate'] as String)
          : null,
      disbursementDate: json['disbursementDate'] != null
          ? DateTime.parse(json['disbursementDate'] as String)
          : null,
      transactionHash: json['transactionHash'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      remainingBalance: BigInt.parse(json['remainingBalance'].toString()),
      monthlyPayment: BigInt.parse(json['monthlyPayment'].toString()),
      creditScoreAtApplication: json['creditScoreAtApplication'] as int,
    );
  }

  // Method for converting to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'borrowerNid': borrowerNid,
      'requestedAmount': requestedAmount.toString(),
      'approvedAmount': approvedAmount.toString(),
      'interestRate': interestRate,
      'termMonths': termMonths,
      'status': status.name,
      'type': type.name,
      'applicationDate': applicationDate.toIso8601String(),
      'approvalDate': approvalDate?.toIso8601String(),
      'disbursementDate': disbursementDate?.toIso8601String(),
      'transactionHash': transactionHash,
      'rejectionReason': rejectionReason,
      'remainingBalance': remainingBalance.toString(),
      'monthlyPayment': monthlyPayment.toString(),
      'creditScoreAtApplication': creditScoreAtApplication,
    };
  }

  // Factory constructor for creating new loan application
  factory LoanModel.createApplication({
    required String borrowerNid,
    required BigInt requestedAmount,
    required int creditScore,
    LoanType type = LoanType.personal,
    double interestRate = 12.5,
    int termMonths = 12,
  }) {
    final id = _generateLoanId();
    final monthlyPayment = _calculateMonthlyPayment(
      requestedAmount,
      interestRate,
      termMonths,
    );

    return LoanModel(
      id: id,
      borrowerNid: borrowerNid,
      requestedAmount: requestedAmount,
      approvedAmount: BigInt.zero,
      interestRate: interestRate,
      termMonths: termMonths,
      status: LoanStatus.pending,
      type: type,
      applicationDate: DateTime.now(),
      remainingBalance: BigInt.zero,
      monthlyPayment: monthlyPayment,
      creditScoreAtApplication: creditScore,
    );
  }

  // Factory constructor for creating from blockchain transaction
  factory LoanModel.fromBlockchainTransaction({
    required String borrowerNid,
    required BigInt amount,
    required String transactionHash,
    required int creditScore,
    LoanType type = LoanType.personal,
    double interestRate = 12.5,
    int termMonths = 12,
  }) {
    final id = _generateLoanId();
    final monthlyPayment = _calculateMonthlyPayment(amount, interestRate, termMonths);
    final now = DateTime.now();

    return LoanModel(
      id: id,
      borrowerNid: borrowerNid,
      requestedAmount: amount,
      approvedAmount: amount,
      interestRate: interestRate,
      termMonths: termMonths,
      status: LoanStatus.approved,
      type: type,
      applicationDate: now,
      approvalDate: now,
      disbursementDate: now,
      transactionHash: transactionHash,
      remainingBalance: amount,
      monthlyPayment: monthlyPayment,
      creditScoreAtApplication: creditScore,
    );
  }

  // Calculate monthly payment using loan formula
  static BigInt _calculateMonthlyPayment(
    BigInt principal,
    double annualRate,
    int termMonths,
  ) {
    if (termMonths == 0) return BigInt.zero;
    
    final monthlyRate = annualRate / 100 / 12;
    final principalDouble = principal.toDouble();
    
    if (monthlyRate == 0) {
      return BigInt.from(principalDouble / termMonths);
    }
    
    final monthlyPayment = principalDouble *
        (monthlyRate * math.pow(1 + monthlyRate, termMonths)) /
        (math.pow(1 + monthlyRate, termMonths) - 1);
    
    return BigInt.from(monthlyPayment.round());
  }

  // Generate unique loan ID
  static String _generateLoanId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'LOAN_${timestamp}_$random';
  }

  // Check if loan is active
  bool get isActive => status == LoanStatus.active || status == LoanStatus.approved;

  // Check if loan is completed
  bool get isCompleted => status == LoanStatus.completed;

  // Check if loan is pending
  bool get isPending => status == LoanStatus.pending;

  // Get loan progress percentage
  double get progressPercentage {
    if (approvedAmount == BigInt.zero) return 0.0;
    final paidAmount = approvedAmount - remainingBalance;
    return (paidAmount.toDouble() / approvedAmount.toDouble()) * 100;
  }

  // Get formatted status string
  String get formattedStatus {
    switch (status) {
      case LoanStatus.pending:
        return 'Pending Approval';
      case LoanStatus.approved:
        return 'Approved';
      case LoanStatus.rejected:
        return 'Rejected';
      case LoanStatus.active:
        return 'Active';
      case LoanStatus.completed:
        return 'Completed';
      case LoanStatus.defaulted:
        return 'Defaulted';
    }
  }

  // Get formatted loan type string
  String get formattedType {
    switch (type) {
      case LoanType.personal:
        return 'Personal Loan';
      case LoanType.business:
        return 'Business Loan';
      case LoanType.emergency:
        return 'Emergency Loan';
      case LoanType.education:
        return 'Education Loan';
    }
  }

  // Copy with method for creating modified instances
  LoanModel copyWith({
    String? id,
    String? borrowerNid,
    BigInt? requestedAmount,
    BigInt? approvedAmount,
    double? interestRate,
    int? termMonths,
    LoanStatus? status,
    LoanType? type,
    DateTime? applicationDate,
    DateTime? approvalDate,
    DateTime? disbursementDate,
    String? transactionHash,
    String? rejectionReason,
    BigInt? remainingBalance,
    BigInt? monthlyPayment,
    int? creditScoreAtApplication,
  }) {
    return LoanModel(
      id: id ?? this.id,
      borrowerNid: borrowerNid ?? this.borrowerNid,
      requestedAmount: requestedAmount ?? this.requestedAmount,
      approvedAmount: approvedAmount ?? this.approvedAmount,
      interestRate: interestRate ?? this.interestRate,
      termMonths: termMonths ?? this.termMonths,
      status: status ?? this.status,
      type: type ?? this.type,
      applicationDate: applicationDate ?? this.applicationDate,
      approvalDate: approvalDate ?? this.approvalDate,
      disbursementDate: disbursementDate ?? this.disbursementDate,
      transactionHash: transactionHash ?? this.transactionHash,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      monthlyPayment: monthlyPayment ?? this.monthlyPayment,
      creditScoreAtApplication: creditScoreAtApplication ?? this.creditScoreAtApplication,
    );
  }

  @override
  String toString() {
    return 'LoanModel(id: $id, borrowerNid: $borrowerNid, '
        'requestedAmount: $requestedAmount, status: $status, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoanModel &&
        other.id == id &&
        other.borrowerNid == borrowerNid &&
        other.requestedAmount == requestedAmount &&
        other.approvedAmount == approvedAmount &&
        other.interestRate == interestRate &&
        other.termMonths == termMonths &&
        other.status == status &&
        other.type == type &&
        other.applicationDate == applicationDate &&
        other.approvalDate == approvalDate &&
        other.disbursementDate == disbursementDate &&
        other.transactionHash == transactionHash &&
        other.rejectionReason == rejectionReason &&
        other.remainingBalance == remainingBalance &&
        other.monthlyPayment == monthlyPayment &&
        other.creditScoreAtApplication == creditScoreAtApplication;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      borrowerNid,
      requestedAmount,
      approvedAmount,
      interestRate,
      termMonths,
      status,
      type,
      applicationDate,
      approvalDate,
      disbursementDate,
      transactionHash,
      rejectionReason,
      remainingBalance,
      monthlyPayment,
      creditScoreAtApplication,
    );
  }
}
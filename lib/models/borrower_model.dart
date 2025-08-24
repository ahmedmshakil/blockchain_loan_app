class BorrowerModel {
  final String name;
  final String nid;
  final String profession;
  final BigInt accountBalance;
  final BigInt totalTransactions;
  final BigInt onTimePayments;
  final BigInt missedPayments;
  final BigInt totalRemainingLoan;
  final BigInt creditAgeMonths;
  final BigInt professionRiskScore;
  final bool exists;

  const BorrowerModel({
    required this.name,
    required this.nid,
    required this.profession,
    required this.accountBalance,
    required this.totalTransactions,
    required this.onTimePayments,
    required this.missedPayments,
    required this.totalRemainingLoan,
    required this.creditAgeMonths,
    required this.professionRiskScore,
    required this.exists,
  });

  // Factory constructor for creating from JSON
  factory BorrowerModel.fromJson(Map<String, dynamic> json) {
    return BorrowerModel(
      name: json['name'] as String,
      nid: json['nid'] as String,
      profession: json['profession'] as String,
      accountBalance: BigInt.parse(json['accountBalance'].toString()),
      totalTransactions: BigInt.parse(json['totalTransactions'].toString()),
      onTimePayments: BigInt.parse(json['onTimePayments'].toString()),
      missedPayments: BigInt.parse(json['missedPayments'].toString()),
      totalRemainingLoan: BigInt.parse(json['totalRemainingLoan'].toString()),
      creditAgeMonths: BigInt.parse(json['creditAgeMonths'].toString()),
      professionRiskScore: BigInt.parse(json['professionRiskScore'].toString()),
      exists: json['exists'] as bool,
    );
  }

  // Method for converting to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'nid': nid,
      'profession': profession,
      'accountBalance': accountBalance.toString(),
      'totalTransactions': totalTransactions.toString(),
      'onTimePayments': onTimePayments.toString(),
      'missedPayments': missedPayments.toString(),
      'totalRemainingLoan': totalRemainingLoan.toString(),
      'creditAgeMonths': creditAgeMonths.toString(),
      'professionRiskScore': professionRiskScore.toString(),
      'exists': exists,
    };
  }

  // Factory constructor for creating from blockchain data
  factory BorrowerModel.fromBlockchainData(List<dynamic> data) {
    return BorrowerModel(
      name: data[0] as String,
      nid: data[1] as String,
      profession: data[2] as String,
      accountBalance: data[3] as BigInt,
      totalTransactions: data[4] as BigInt,
      onTimePayments: data[5] as BigInt,
      missedPayments: data[6] as BigInt,
      totalRemainingLoan: data[7] as BigInt,
      creditAgeMonths: data[8] as BigInt,
      professionRiskScore: data[9] as BigInt,
      exists: data[10] as bool,
    );
  }

  // Copy with method for creating modified instances
  BorrowerModel copyWith({
    String? name,
    String? nid,
    String? profession,
    BigInt? accountBalance,
    BigInt? totalTransactions,
    BigInt? onTimePayments,
    BigInt? missedPayments,
    BigInt? totalRemainingLoan,
    BigInt? creditAgeMonths,
    BigInt? professionRiskScore,
    bool? exists,
  }) {
    return BorrowerModel(
      name: name ?? this.name,
      nid: nid ?? this.nid,
      profession: profession ?? this.profession,
      accountBalance: accountBalance ?? this.accountBalance,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      onTimePayments: onTimePayments ?? this.onTimePayments,
      missedPayments: missedPayments ?? this.missedPayments,
      totalRemainingLoan: totalRemainingLoan ?? this.totalRemainingLoan,
      creditAgeMonths: creditAgeMonths ?? this.creditAgeMonths,
      professionRiskScore: professionRiskScore ?? this.professionRiskScore,
      exists: exists ?? this.exists,
    );
  }

  @override
  String toString() {
    return 'BorrowerModel(name: $name, nid: $nid, profession: $profession, '
        'accountBalance: $accountBalance, exists: $exists)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BorrowerModel &&
        other.name == name &&
        other.nid == nid &&
        other.profession == profession &&
        other.accountBalance == accountBalance &&
        other.totalTransactions == totalTransactions &&
        other.onTimePayments == onTimePayments &&
        other.missedPayments == missedPayments &&
        other.totalRemainingLoan == totalRemainingLoan &&
        other.creditAgeMonths == creditAgeMonths &&
        other.professionRiskScore == professionRiskScore &&
        other.exists == exists;
  }

  @override
  int get hashCode {
    return Object.hash(
      name,
      nid,
      profession,
      accountBalance,
      totalTransactions,
      onTimePayments,
      missedPayments,
      totalRemainingLoan,
      creditAgeMonths,
      professionRiskScore,
      exists,
    );
  }
}
class CreditScoreModel {
  final int score;
  final String rating;
  final BigInt maxLoanAmount;
  final Map<String, int> scoreBreakdown;
  final bool isBlockchainVerified;
  final DateTime calculatedAt;

  const CreditScoreModel({
    required this.score,
    required this.rating,
    required this.maxLoanAmount,
    required this.scoreBreakdown,
    required this.isBlockchainVerified,
    required this.calculatedAt,
  });

  // Factory constructor for creating from JSON
  factory CreditScoreModel.fromJson(Map<String, dynamic> json) {
    return CreditScoreModel(
      score: json['score'] as int,
      rating: json['rating'] as String,
      maxLoanAmount: BigInt.parse(json['maxLoanAmount'].toString()),
      scoreBreakdown: Map<String, int>.from(json['scoreBreakdown'] as Map),
      isBlockchainVerified: json['isBlockchainVerified'] as bool,
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
    );
  }

  // Method for converting to JSON
  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'rating': rating,
      'maxLoanAmount': maxLoanAmount.toString(),
      'scoreBreakdown': scoreBreakdown,
      'isBlockchainVerified': isBlockchainVerified,
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }

  // Factory constructor for creating from blockchain calculation
  factory CreditScoreModel.fromBlockchainCalculation({
    required int score,
    required String rating,
    required BigInt maxLoanAmount,
    required Map<String, int> scoreBreakdown,
  }) {
    return CreditScoreModel(
      score: score,
      rating: rating,
      maxLoanAmount: maxLoanAmount,
      scoreBreakdown: scoreBreakdown,
      isBlockchainVerified: true,
      calculatedAt: DateTime.now(),
    );
  }

  // Factory constructor for creating default/empty state
  factory CreditScoreModel.empty() {
    return CreditScoreModel(
      score: 0,
      rating: 'N/A',
      maxLoanAmount: BigInt.zero,
      scoreBreakdown: {},
      isBlockchainVerified: false,
      calculatedAt: DateTime.now(),
    );
  }

  // Get credit rating based on score
  static String getRatingFromScore(int score) {
    if (score >= 800) return 'A';
    if (score >= 650) return 'B';
    if (score >= 500) return 'C';
    return 'D';
  }

  // Check if credit score qualifies for loan
  bool get isEligibleForLoan => score >= 300;

  // Get score percentage (0-100)
  double get scorePercentage => (score / 1000.0) * 100;

  // Get formatted score breakdown as string
  String get formattedScoreBreakdown {
    if (scoreBreakdown.isEmpty) return 'No breakdown available';
    
    return scoreBreakdown.entries
        .map((entry) => '${entry.key}: ${entry.value} points')
        .join('\n');
  }

  // Copy with method for creating modified instances
  CreditScoreModel copyWith({
    int? score,
    String? rating,
    BigInt? maxLoanAmount,
    Map<String, int>? scoreBreakdown,
    bool? isBlockchainVerified,
    DateTime? calculatedAt,
  }) {
    return CreditScoreModel(
      score: score ?? this.score,
      rating: rating ?? this.rating,
      maxLoanAmount: maxLoanAmount ?? this.maxLoanAmount,
      scoreBreakdown: scoreBreakdown ?? Map.from(this.scoreBreakdown),
      isBlockchainVerified: isBlockchainVerified ?? this.isBlockchainVerified,
      calculatedAt: calculatedAt ?? this.calculatedAt,
    );
  }

  @override
  String toString() {
    return 'CreditScoreModel(score: $score, rating: $rating, '
        'maxLoanAmount: $maxLoanAmount, isBlockchainVerified: $isBlockchainVerified)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreditScoreModel &&
        other.score == score &&
        other.rating == rating &&
        other.maxLoanAmount == maxLoanAmount &&
        _mapEquals(other.scoreBreakdown, scoreBreakdown) &&
        other.isBlockchainVerified == isBlockchainVerified &&
        other.calculatedAt == calculatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      score,
      rating,
      maxLoanAmount,
      scoreBreakdown,
      isBlockchainVerified,
      calculatedAt,
    );
  }

  // Helper method for comparing maps
  bool _mapEquals(Map<String, int> map1, Map<String, int> map2) {
    if (map1.length != map2.length) return false;
    for (final key in map1.keys) {
      if (map1[key] != map2[key]) return false;
    }
    return true;
  }
}
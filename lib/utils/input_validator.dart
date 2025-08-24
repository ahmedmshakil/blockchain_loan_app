import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Comprehensive input validation and sanitization utility
class InputValidator {
  // Regular expressions for validation
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  
  static final RegExp _phoneRegex = RegExp(
    r'^\+?[1-9]\d{1,14}$',
  );
  
  static final RegExp _nidRegex = RegExp(
    r'^\d{10,17}$',
  );
  
  static final RegExp _walletAddressRegex = RegExp(
    r'^0x[a-fA-F0-9]{40}$',
  );
  
  static final RegExp _privateKeyRegex = RegExp(
    r'^[a-fA-F0-9]{64}$',
  );
  
  static final RegExp _alphanumericRegex = RegExp(
    r'^[a-zA-Z0-9\s]+$',
  );
  
  static final RegExp _numericRegex = RegExp(
    r'^\d+(\.\d+)?$',
  );
  
  // Dangerous characters that should be sanitized
  static final RegExp _dangerousChars = RegExp(r'[<>"&${}[\]\\/*+?|()^%#@!~`]');
  
  /// Validate email address
  static ValidationResult validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return ValidationResult(false, 'Email is required');
    }
    
    final sanitized = sanitizeInput(email);
    if (sanitized != email) {
      return ValidationResult(false, 'Email contains invalid characters');
    }
    
    if (!_emailRegex.hasMatch(email)) {
      return ValidationResult(false, 'Invalid email format');
    }
    
    if (email.length > 254) {
      return ValidationResult(false, 'Email is too long');
    }
    
    return ValidationResult(true, 'Valid email');
  }
  
  /// Validate phone number
  static ValidationResult validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return ValidationResult(false, 'Phone number is required');
    }
    
    final sanitized = sanitizePhoneNumber(phone);
    if (!_phoneRegex.hasMatch(sanitized)) {
      return ValidationResult(false, 'Invalid phone number format');
    }
    
    return ValidationResult(true, 'Valid phone number');
  }
  
  /// Validate National ID (NID)
  static ValidationResult validateNID(String? nid) {
    if (nid == null || nid.isEmpty) {
      return ValidationResult(false, 'NID is required');
    }
    
    final sanitized = sanitizeNumericInput(nid);
    if (sanitized != nid) {
      return ValidationResult(false, 'NID should contain only numbers');
    }
    
    if (!_nidRegex.hasMatch(nid)) {
      return ValidationResult(false, 'NID should be 10-17 digits');
    }
    
    return ValidationResult(true, 'Valid NID');
  }
  
  /// Validate wallet address
  static ValidationResult validateWalletAddress(String? address) {
    if (address == null || address.isEmpty) {
      return ValidationResult(false, 'Wallet address is required');
    }
    
    if (!_walletAddressRegex.hasMatch(address)) {
      return ValidationResult(false, 'Invalid Ethereum wallet address format');
    }
    
    return ValidationResult(true, 'Valid wallet address');
  }
  
  /// Validate private key
  static ValidationResult validatePrivateKey(String? privateKey) {
    if (privateKey == null || privateKey.isEmpty) {
      return ValidationResult(false, 'Private key is required');
    }
    
    // Remove 0x prefix if present
    final cleanKey = privateKey.startsWith('0x') 
        ? privateKey.substring(2) 
        : privateKey;
    
    if (!_privateKeyRegex.hasMatch(cleanKey)) {
      return ValidationResult(false, 'Invalid private key format (should be 64 hex characters)');
    }
    
    return ValidationResult(true, 'Valid private key');
  }
  
  /// Validate loan amount
  static ValidationResult validateLoanAmount(String? amount, {
    double? minAmount,
    double? maxAmount,
  }) {
    if (amount == null || amount.isEmpty) {
      return ValidationResult(false, 'Loan amount is required');
    }
    
    final sanitized = sanitizeNumericInput(amount);
    if (sanitized != amount) {
      return ValidationResult(false, 'Loan amount should contain only numbers and decimal point');
    }
    
    final parsedAmount = double.tryParse(amount);
    if (parsedAmount == null) {
      return ValidationResult(false, 'Invalid loan amount format');
    }
    
    if (parsedAmount <= 0) {
      return ValidationResult(false, 'Loan amount must be greater than 0');
    }
    
    if (minAmount != null && parsedAmount < minAmount) {
      return ValidationResult(false, 'Loan amount must be at least \$${minAmount.toStringAsFixed(2)}');
    }
    
    if (maxAmount != null && parsedAmount > maxAmount) {
      return ValidationResult(false, 'Loan amount cannot exceed \$${maxAmount.toStringAsFixed(2)}');
    }
    
    return ValidationResult(true, 'Valid loan amount');
  }
  
  /// Validate name (person or organization)
  static ValidationResult validateName(String? name, {int maxLength = 100}) {
    if (name == null || name.isEmpty) {
      return ValidationResult(false, 'Name is required');
    }
    
    if (name.length > maxLength) {
      return ValidationResult(false, 'Name is too long (max $maxLength characters)');
    }
    
    if (name.length < 2) {
      return ValidationResult(false, 'Name is too short (min 2 characters)');
    }
    
    // Allow letters, spaces, hyphens, and apostrophes
    final nameRegex = RegExp(r"^[a-zA-Z\s\-'\.]+$");
    if (!nameRegex.hasMatch(name)) {
      return ValidationResult(false, 'Name contains invalid characters');
    }
    
    return ValidationResult(true, 'Valid name');
  }
  
  /// Validate profession
  static ValidationResult validateProfession(String? profession) {
    if (profession == null || profession.isEmpty) {
      return ValidationResult(false, 'Profession is required');
    }
    
    if (profession.length > 100) {
      return ValidationResult(false, 'Profession name is too long');
    }
    
    if (profession.length < 2) {
      return ValidationResult(false, 'Profession name is too short');
    }
    
    // Allow letters, spaces, and common profession characters
    final professionRegex = RegExp(r"^[a-zA-Z0-9\s\-'\.\/\(\)]+$");
    if (!professionRegex.hasMatch(profession)) {
      return ValidationResult(false, 'Profession contains invalid characters');
    }
    
    return ValidationResult(true, 'Valid profession');
  }
  
  /// Sanitize general text input
  static String sanitizeInput(String input) {
    if (input.isEmpty) return input;
    
    // Remove dangerous characters
    String sanitized = input.replaceAll(_dangerousChars, '');
    
    // Trim whitespace
    sanitized = sanitized.trim();
    
    // Remove multiple consecutive spaces
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');
    
    // Limit length to prevent DoS
    if (sanitized.length > 1000) {
      sanitized = sanitized.substring(0, 1000);
    }
    
    return sanitized;
  }
  
  /// Sanitize numeric input
  static String sanitizeNumericInput(String input) {
    if (input.isEmpty) return input;
    
    // Keep only digits and decimal point
    return input.replaceAll(RegExp(r'[^0-9\.]'), '');
  }
  
  /// Sanitize phone number
  static String sanitizePhoneNumber(String input) {
    if (input.isEmpty) return input;
    
    // Keep only digits and plus sign
    return input.replaceAll(RegExp(r'[^0-9\+]'), '');
  }
  
  /// Sanitize HTML content (basic)
  static String sanitizeHtml(String input) {
    if (input.isEmpty) return input;
    
    // Remove HTML tags
    String sanitized = input.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Decode HTML entities
    sanitized = sanitized
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#x27;', "'")
        .replaceAll('&#x2F;', '/');
    
    return sanitized;
  }
  
  /// Validate and sanitize JSON input
  static ValidationResult validateJson(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return ValidationResult(false, 'JSON string is required');
    }
    
    try {
      json.decode(jsonString);
      return ValidationResult(true, 'Valid JSON');
    } catch (e) {
      return ValidationResult(false, 'Invalid JSON format: $e');
    }
  }
  
  /// Validate password strength
  static ValidationResult validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return ValidationResult(false, 'Password is required');
    }
    
    if (password.length < 8) {
      return ValidationResult(false, 'Password must be at least 8 characters long');
    }
    
    if (password.length > 128) {
      return ValidationResult(false, 'Password is too long (max 128 characters)');
    }
    
    // Check for at least one uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return ValidationResult(false, 'Password must contain at least one uppercase letter');
    }
    
    // Check for at least one lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return ValidationResult(false, 'Password must contain at least one lowercase letter');
    }
    
    // Check for at least one digit
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return ValidationResult(false, 'Password must contain at least one digit');
    }
    
    // Check for at least one special character
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return ValidationResult(false, 'Password must contain at least one special character');
    }
    
    return ValidationResult(true, 'Strong password');
  }
  
  /// Validate contract address
  static ValidationResult validateContractAddress(String? address) {
    final walletValidation = validateWalletAddress(address);
    if (!walletValidation.isValid) {
      return ValidationResult(false, 'Invalid contract address: ${walletValidation.message}');
    }
    
    // Additional contract-specific validation can be added here
    return ValidationResult(true, 'Valid contract address');
  }
  
  /// Validate transaction hash
  static ValidationResult validateTransactionHash(String? hash) {
    if (hash == null || hash.isEmpty) {
      return ValidationResult(false, 'Transaction hash is required');
    }
    
    // Ethereum transaction hash is 66 characters (0x + 64 hex chars)
    final hashRegex = RegExp(r'^0x[a-fA-F0-9]{64}$');
    if (!hashRegex.hasMatch(hash)) {
      return ValidationResult(false, 'Invalid transaction hash format');
    }
    
    return ValidationResult(true, 'Valid transaction hash');
  }
  
  /// Batch validate multiple inputs
  static Map<String, ValidationResult> validateBatch(Map<String, dynamic> inputs) {
    final results = <String, ValidationResult>{};
    
    for (final entry in inputs.entries) {
      final key = entry.key;
      final value = entry.value;
      
      switch (key.toLowerCase()) {
        case 'email':
          results[key] = validateEmail(value?.toString());
          break;
        case 'phone':
          results[key] = validatePhone(value?.toString());
          break;
        case 'nid':
          results[key] = validateNID(value?.toString());
          break;
        case 'name':
          results[key] = validateName(value?.toString());
          break;
        case 'profession':
          results[key] = validateProfession(value?.toString());
          break;
        case 'wallet_address':
        case 'walletaddress':
          results[key] = validateWalletAddress(value?.toString());
          break;
        case 'private_key':
        case 'privatekey':
          results[key] = validatePrivateKey(value?.toString());
          break;
        case 'loan_amount':
        case 'loanamount':
          results[key] = validateLoanAmount(value?.toString());
          break;
        case 'password':
          results[key] = validatePassword(value?.toString());
          break;
        default:
          results[key] = ValidationResult(true, 'No specific validation rule');
      }
    }
    
    return results;
  }
  
  /// Check if all validation results are valid
  static bool areAllValid(Map<String, ValidationResult> results) {
    return results.values.every((result) => result.isValid);
  }
  
  /// Get all validation errors
  static List<String> getValidationErrors(Map<String, ValidationResult> results) {
    return results.entries
        .where((entry) => !entry.value.isValid)
        .map((entry) => '${entry.key}: ${entry.value.message}')
        .toList();
  }
}

/// Validation result class
class ValidationResult {
  final bool isValid;
  final String message;
  
  const ValidationResult(this.isValid, this.message);
  
  @override
  String toString() => 'ValidationResult(isValid: $isValid, message: $message)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ValidationResult &&
        other.isValid == isValid &&
        other.message == message;
  }
  
  @override
  int get hashCode => isValid.hashCode ^ message.hashCode;
}

/// Input sanitization utility
class InputSanitizer {
  /// Sanitize all string fields in a map
  static Map<String, dynamic> sanitizeMap(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};
    
    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value is String) {
        sanitized[key] = InputValidator.sanitizeInput(value);
      } else if (value is Map<String, dynamic>) {
        sanitized[key] = sanitizeMap(value);
      } else if (value is List) {
        sanitized[key] = sanitizeList(value);
      } else {
        sanitized[key] = value;
      }
    }
    
    return sanitized;
  }
  
  /// Sanitize all string elements in a list
  static List<dynamic> sanitizeList(List<dynamic> data) {
    return data.map((item) {
      if (item is String) {
        return InputValidator.sanitizeInput(item);
      } else if (item is Map<String, dynamic>) {
        return sanitizeMap(item);
      } else if (item is List) {
        return sanitizeList(item);
      } else {
        return item;
      }
    }).toList();
  }
}
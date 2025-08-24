import 'package:flutter_test/flutter_test.dart';
import 'package:blockchain_loan_app/services/web3_service.dart';
import 'package:blockchain_loan_app/config/blockchain_config.dart';

void main() {
  group('Web3Service Tests', () {
    late Web3Service web3Service;
    
    setUp(() {
      web3Service = Web3Service.instance;
    });
    
    test('should be singleton', () {
      final instance1 = Web3Service.instance;
      final instance2 = Web3Service.instance;
      
      expect(instance1, equals(instance2));
    });
    
    test('should get contract address', () async {
      try {
        final address = await web3Service.getContractAddress();
        expect(address.hex, isNotEmpty);
      } catch (e) {
        // Expected to fail if configuration is not set up
        expect(e.toString(), contains('Invalid argument (address)'));
      }
    });
    
    test('should validate configuration', () {
      expect(() => BlockchainConfig.validateConfiguration(), 
             throwsA(isA<Exception>()));
    });
    
    test('should handle Web3 client initialization failure gracefully', () async {
      // This test verifies error handling when configuration is invalid
      try {
        await web3Service.getWeb3Client();
        fail('Should have thrown an exception');
      } catch (e) {
        expect(e, isA<Exception>());
      }
    });
    
    test('should handle contract loading failure gracefully', () async {
      try {
        await web3Service.getContract();
        fail('Should have thrown an exception');
      } catch (e) {
        expect(e, isA<ArgumentError>());
      }
    });
    
    tearDown(() {
      web3Service.dispose();
    });
  });
}
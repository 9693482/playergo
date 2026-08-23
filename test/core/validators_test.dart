import 'package:flutter_test/flutter_test.dart';
import 'package:playergo/core/validators/validators.dart';

void main() {
  group('Email', () {
    test('rejects null', () {
      expect(Validators.email(null), isNotNull);
    });
    test('rejects empty', () {
      expect(Validators.email(''), isNotNull);
    });
    test('rejects whitespace only', () {
      expect(Validators.email('   '), isNotNull);
    });
    test('rejects missing @', () {
      expect(Validators.email('invalid'), isNotNull);
    });
    test('accepts valid email', () {
      expect(Validators.email('user@test.com'), isNull);
    });
    test('trims whitespace', () {
      expect(Validators.email('  user@test.com  '), isNull);
    });
  });

  group('Password', () {
    test('rejects null', () {
      expect(Validators.password(null), isNotNull);
    });
    test('rejects empty', () {
      expect(Validators.password(''), isNotNull);
    });
    test('rejects too short', () {
      expect(Validators.password('Ab1'), isNotNull);
    });
    test('rejects no uppercase', () {
      expect(Validators.password('abcdefg1'), isNotNull);
    });
    test('rejects no lowercase', () {
      expect(Validators.password('ABCDEFG1'), isNotNull);
    });
    test('rejects no number', () {
      expect(Validators.password('Abcdefgh'), isNotNull);
    });
    test('accepts valid password', () {
      expect(Validators.password('Admin123'), isNull);
    });
  });

  group('Phone', () {
    test('rejects null', () {
      expect(Validators.phone(null), isNotNull);
    });
    test('rejects empty', () {
      expect(Validators.phone(''), isNotNull);
    });
    test('rejects too short', () {
      expect(Validators.phone('1234567'), isNotNull);
    });
    test('rejects letters', () {
      expect(Validators.phone('abc1234567890'), isNotNull);
    });
    test('accepts valid phone', () {
      expect(Validators.phone('3001234567'), isNull);
    });
    test('accepts formatted phone', () {
      expect(Validators.phone('+57 300-123-4567'), isNull);
    });
  });

  group('Price', () {
    test('rejects null', () {
      expect(Validators.price(null), isNotNull);
    });
    test('rejects empty', () {
      expect(Validators.price(''), isNotNull);
    });
    test('rejects non-numeric', () {
      expect(Validators.price('abc'), isNotNull);
    });
    test('rejects zero', () {
      expect(Validators.price('0'), isNotNull);
    });
    test('rejects negative', () {
      expect(Validators.price('-10'), isNotNull);
    });
    test('rejects too high', () {
      expect(Validators.price('10001'), isNotNull);
    });
    test('accepts valid price', () {
      expect(Validators.price('500'), isNull);
    });
  });

  group('FullName', () {
    test('rejects null', () {
      expect(Validators.fullName(null), isNotNull);
    });
    test('rejects empty', () {
      expect(Validators.fullName(''), isNotNull);
    });
    test('rejects too short', () {
      expect(Validators.fullName('A'), isNotNull);
    });
    test('accepts valid name', () {
      expect(Validators.fullName('Juan Perez'), isNull);
    });
  });

  group('TeamName', () {
    test('rejects null', () {
      expect(Validators.teamName(null), isNotNull);
    });
    test('rejects empty', () {
      expect(Validators.teamName(''), isNotNull);
    });
    test('rejects too short', () {
      expect(Validators.teamName('AB'), isNotNull);
    });
    test('accepts valid name', () {
      expect(Validators.teamName('Los Tigres'), isNull);
    });
  });

  group('Sanitize', () {
    test('returns null for null', () {
      expect(Validators.sanitize(null), isNull);
    });
    test('removes script tags', () {
      final result = Validators.sanitize('<script>alert(1)</script>');
      expect(result, isNot(contains('<script')));
      expect(result, isNot(contains('</script')));
    });
    test('removes javascript protocol', () {
      expect(Validators.sanitize('javascript:alert(1)'), 'alert(1)');
    });
    test('trims whitespace', () {
      expect(Validators.sanitize('  hello  '), 'hello');
    });
    test('preserves normal text', () {
      expect(Validators.sanitize('Hello World'), 'Hello World');
    });
  });
}

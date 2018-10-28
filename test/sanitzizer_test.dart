import 'package:test/test.dart';
import 'package:validator/validator.dart' as s;

void parameterTest(Map<String, dynamic> options) {
  List<Object> args = options['args'];
  Map<dynamic, dynamic> expected = options['expect'];
  expected.keys.forEach((input) {
    List<Object> toTest = [input];
    toTest.addAll(args);
    var f = options["sanitizer"].toString();
    var result = Function.apply(options['sanitizer'], toTest);
    var expected = options['expect'][input];

    if ((expected is double || expected is int) &&
        expected.isNaN == true &&
        result.isNaN == true) {
      return true;
    }

    if (result != expected) {
      throw new Exception('sanitizer.$f($args) failed but should have passed');
    }
  });
}

void main() {
  group('sanitzizer test', () {
    test('test toString', () {
      parameterTest({
        'sanitizer': s.toString,
        'args': [],
        'expect': {
          1: '1',
          1.5: '1.5',
          {1: 2}: '{1: 2}',
          null: ''
        }
      });
    });

    test('test toDate', () {
      parameterTest({
        'sanitizer': s.toDate,
        'args': [],
        'expect': {
          '2012-02-27 13:27:00': DateTime.parse('2012-02-27 13:27:00'),
          'abc': null
        }
      });
    });

    test('test toFloat', () {
      parameterTest({
        'sanitizer': s.toFloat,
        'args': [],
        'expect': {'1': 1.0, '2.': 2.0, '-1.4': -1.4, 'foo': double.nan}
      });
    });

    test('test toInt', () {
      parameterTest({
        'sanitizer': s.toInt,
        'args': [],
        'expect': {'1.4': 1, '2.': 2, 'foo': double.nan}
      });
    });

    test(' test toBoolean', () {
      parameterTest({
        'sanitizer': s.toBoolean,
        'args': [],
        'expect': {
          '0': false,
          '': false,
          '1': true,
          'true': true,
          'foobar': true,
          '   ': true
        }
      });

      parameterTest({
        'sanitizer': s.toBoolean,
        'args': [true],
        'expect': {
          '0': false,
          '': false,
          '1': true,
          'true': true,
          'foobar': false,
          '   ': false
        }
      });
    });

    test('test trim', () {
      parameterTest({
        'sanitizer': s.trim,
        'args': [],
        'expect': {'  \r\n\tfoo  \r\n\t   ': 'foo'}
      });

      parameterTest({
        'sanitizer': s.trim,
        'args': ['01'],
        'expect': {'010100201000': '2'}
      });

      parameterTest({
        'sanitizer': s.ltrim,
        'args': [],
        'expect': {'  \r\n\tfoo  \r\n\t   ': 'foo  \r\n\t   '}
      });

      parameterTest({
        'sanitizer': s.ltrim,
        'args': ['01'],
        'expect': {'010100201000': '201000'}
      });

      parameterTest({
        'sanitizer': s.rtrim,
        'args': [],
        'expect': {'  \r\n\tfoo  \r\n\t   ': '  \r\n\tfoo'}
      });

      parameterTest({
        'sanitizer': s.rtrim,
        'args': ['01'],
        'expect': {'010100201000': '0101002'}
      });
    });

    test('test whitelist', () {
      parameterTest({
        'sanitizer': s.whitelist,
        'args': ['abc'],
        'expect': {
          'abcdef': 'abc',
          'aaaaaaaaaabbbbbbbbbb': 'aaaaaaaaaabbbbbbbbbb',
          'a1b2c3': 'abc',
          '   ': ''
        }
      });
    });

    test('test blacklist', () {
      parameterTest({
        'sanitizer': s.blacklist,
        'args': ['abc'],
        'expect': {
          'abcdef': 'def',
          'aaaaaaaaaabbbbbbbbbb': '',
          'a1b2c3': '123',
          '   ': '   '
        }
      });
    });

    test('test stripLow', () {
      parameterTest({
        'sanitizer': s.stripLow,
        'args': [true],
        'expect': {
          "foo\x0A\x0D": "foo\x0A\x0D",
          "\x03foo\x0A\x0D": "foo\x0A\x0D"
        }
      });

      parameterTest({
        'sanitizer': s.stripLow,
        'args': [],
        'expect': {
          "foo\x00": "foo",
          "\x7Ffoo\x02": "foo",
          "\x01\x09": "",
          "foo\x0A\x0D": "foo",
          "perch\u00e9": "perch\u00e9",
          "\u20ac": "\u20ac",
          "\u2206\x0A": "\u2206"
        }
      });
    });

    test('test escape', () {
      parameterTest({
        'sanitizer': s.escape,
        'args': [],
        'expect': {
          '<img alt="foo&bar">': '&lt;img alt=&quot;foo&amp;bar&quot;&gt;',
          "<img alt='foo&bar'>": '&lt;img alt=&#x27;foo&amp;bar&#x27;&gt;'
        }
      });
    });

    test('test normalizeEmail', () {
      parameterTest({
        'sanitizer': s.normalizeEmail,
        'args': [],
        'expect': {
          'test@me.com': 'test@me.com',
          'some.name@gmail.com': 'somename@gmail.com',
          'some.name@googleMail.com': 'somename@gmail.com',
          'some.name+extension@gmail.com': 'somename@gmail.com',
          'some.Name+extension@GoogleMail.com': 'somename@gmail.com',
          'some.name.middleName+extension@gmail.com':
              'somenamemiddlename@gmail.com',
          'some.name.middleName+extension@GoogleMail.com':
              'somenamemiddlename@gmail.com',
          'some.name.midd.leNa.me.+extension@gmail.com':
              'somenamemiddlename@gmail.com',
          'some.name.midd.leNa.me.+extension@GoogleMail.com':
              'somenamemiddlename@gmail.com',
          'some.name+extension@unknown.com': 'some.name+extension@unknown.com',
          'hans@m端ller.com': 'hans@m端ller.com',
          'an invalid email address': '',
          '': ''
        }
      });

      parameterTest({
        'sanitizer': s.normalizeEmail,
        'args': [false],
        'expect': {
          'test@me.com': 'test@me.com',
          'hans@m端ller.com': 'hans@m端ller.com',
          'test@ME.COM': 'test@me.com',
          'TEST@me.com': 'TEST@me.com',
          'TEST@ME.COM': 'TEST@me.com',
          'blAH@x.com': 'blAH@x.com',
          'SOME.name@GMAIL.com': 'somename@gmail.com',
          'SOME.name.middleName+extension@GoogleMail.com':
              'somenamemiddlename@gmail.com',
          'SOME.name.midd.leNa.me.+extension@gmail.com':
              'somenamemiddlename@gmail.com'
        }
      });
    });
  });
}

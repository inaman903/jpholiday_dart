import 'dart:collection';
import 'dart:io';
import 'package:jpholiday/jpholiday_dart.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart' as xml;
import 'package:intl/intl.dart';

final DateTime _statDate = DateTime(1948, 7, 20);
final DateTime _endDate = DateTime(2050, 12, 31);
final DateFormat _dateFormat = DateFormat('yyyy/MM/dd');

void main() {
  group('UnitTests', () {
    test('Test isHoliday', () {
      var holidayTable = _getHolidayTable();
      for (var date = _statDate; date.compareTo(_endDate) <= 0; date = DateTime(date.year, date.month, date.day + 1)) {
        var expected = holidayTable.containsKey(date);
        var actual = JpHoliday.isHoliday(date);
        expect(actual, expected,
            reason:
                '[${_dateFormat.format(date)}]は[${actual ? '休日' : '休日ではない'}]と判定されましたがテストデータの[${expected ? '休日' : '休日ではない'}]と一致しません');
      }
    });
    test('Test existsHoliday', () {
      var holidayTable = _getHolidayTable();
      var startDate = DateTime(_statDate.year, _statDate.month, 1);
      var endDate = DateTime(_endDate.year, _endDate.month, 1);
      for (var date = startDate; date.compareTo(endDate) <= 0; date = DateTime(date.year, date.month + 1, date.day)) {
        {
          var start = new DateTime(date.year, date.month, 1);
          var end = new DateTime(date.year, date.month + 1, 0);

          var expected = holidayTable.keys.any((d) => d.year == date.year && d.month == date.month);
          var actual = JpHoliday.existsHoliday(start, end);
          expect(actual, expected,
              reason:
                  '[${_dateFormat.format(date)}]は[${actual ? '休日あり' : '休日なし'}]と判定されましたがテストデータの[${expected ? '休日あり' : '休日なし'}]と一致しません');
        }
      }
    });
    test('Test getHoliday', () {
      var holidayTable = _getHolidayTable();
      for (var date = _statDate; date.compareTo(_endDate) <= 0; date = DateTime(date.year, date.month, date.day + 1)) {
        var holiday = JpHoliday.getHoliday(date);
        if (holiday != null && !holidayTable.containsKey(date)) {
          fail('[${_dateFormat.format(date)}]は[${holiday.name}]と判定されましたがテストデータに含まれていません');
        } else if (holiday == null && holidayTable.containsKey(date)) {
          fail('[${_dateFormat.format(date)}]は休日ではないと判定されましたがテストデータには[${holidayTable[date]}]として含まれています');
        }
        if (holiday != null) {
          expect(holiday.name, holidayTable[date],
              reason: '[${_dateFormat.format(date)}]は[${holiday.name}]と判定されましたがテストデータの[${holidayTable[date]}]と一致しません');
        }
      }
    });
    test('Test getHolidays', () {
      var holidayTable = _getHolidayTable();
      for (var year = _statDate.year; year <= _endDate.year; year++) {
        var start = new DateTime(year, 1, 1);
        var end = new DateTime(year + 1, 1, 0);

        var holidays = JpHoliday.getHolidays(start, end);
        for (var date in holidayTable.keys.where((d) => d.year == year)) {
          var holiday = holidays.firstWhere((h) => h.date == date, orElse: () => null);
          expect(holiday, isNotNull,
              reason: '[${_dateFormat.format(date)}]は休日ではないと判定されましたがテストデータには[${holidayTable[date]}]として含まれています');

          expect(holiday.name, holidayTable[date],
              reason: '[${_dateFormat.format(date)}]は[${holiday.name}]と判定されましたがテストデータの[${holidayTable[date]}]と一致しません');
        }
      }
    });
  });
}

LinkedHashMap<DateTime, String> _getHolidayTable() {
  var result = new LinkedHashMap<DateTime, String>();

  var xmlString = File('test/Holidays.xml').readAsStringSync();
  var doc = xml.parse(xmlString);

  var holidayNodes = doc.findAllElements('holiday');
  for (var holidayElement in holidayNodes) {
    var date = _dateFormat.parse(holidayElement.getAttribute('date'));
    var name = holidayElement.getAttribute('name');

    result[date] = name;
  }

  return result;
}

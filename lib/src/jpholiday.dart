DateTime _incrementalDays(DateTime date, int days) => DateTime(date.year, date.month, date.day + days);

abstract class _Rule {
  bool eval(DateTime date);
}

class _YearRule implements _Rule {
  final int _start;
  final int _end;

  _YearRule._internal(this._start, this._end);

  @override
  bool eval(DateTime date) => (_start < 0 || date.year >= _start) && (_end < 0 || date.year <= _end);

  factory _YearRule.just(int year) => _YearRule._internal(year, year);
  factory _YearRule.before(int year) => _YearRule._internal(-1, year);
  factory _YearRule.after(int year) => _YearRule._internal(year, -1);
  factory _YearRule.range(int start, int end) => _YearRule._internal(start, end);
  factory _YearRule.any() => _YearRule._internal(-1, -1);
}

class _MonthRule implements _Rule {
  final int _start;
  final int _end;

  _MonthRule._internal(this._start, this._end);

  @override
  bool eval(DateTime date) => (_start < 0 || date.month >= _start) && (_end < 0 || date.month <= _end);

  factory _MonthRule.just(int month) => _MonthRule._internal(month, month);
  factory _MonthRule.before(int month) => _MonthRule._internal(-1, month);
  factory _MonthRule.after(int month) => _MonthRule._internal(month, -1);
  factory _MonthRule.range(int start, int end) => _MonthRule._internal(start, end);
  factory _MonthRule.any() => _MonthRule._internal(-1, -1);
}

class _JustDayRule implements _Rule {
  final int _day;

  _JustDayRule(this._day);

  @override
  bool eval(DateTime date) => date.day == _day;
}

class _WeekdayDayRule implements _Rule {
  final int _week;
  final int _weekday;

  _WeekdayDayRule(this._week, this._weekday);

  @override
  bool eval(DateTime date) {
    var tmp = DateTime(date.year, date.month, 1);
    tmp = _incrementalDays(
        tmp,
        (DateTime.daysPerWeek * (_week - 1)) +
            (_weekday >= tmp.weekday ? _weekday - tmp.weekday : DateTime.sunday - tmp.weekday + _weekday));

    return date.month == tmp.month && date.day == tmp.day;
  }
}

typedef bool _FuncRuleEvalFunction(DateTime date);

class _FuncDayRule implements _Rule {
  final _FuncRuleEvalFunction _func;

  _FuncDayRule(this._func);

  @override
  bool eval(DateTime date) => _func != null ? _func(date) : false;
}

class _DayRule implements _Rule {
  final _Rule _rule;

  _DayRule._internal(this._rule);

  @override
  bool eval(DateTime date) => _rule != null ? _rule.eval(date) : false;

  factory _DayRule.just(int day) => _DayRule._internal(_JustDayRule(day));
  factory _DayRule.weekday(int week, int weekday) => _DayRule._internal(_WeekdayDayRule(week, weekday));
  factory _DayRule.func(_FuncRuleEvalFunction func) => _DayRule._internal(_FuncDayRule(func));
}

enum _DateRuleType { Holiday, SubstituteHoliday, NationalHoliday }

class _DateRule implements _Rule {
  final String _name;
  final _DateRuleType _type;
  final _YearRule _yearRule;
  final _MonthRule _monthRule;
  final _DayRule _dayRule;

  String get name => _name;
  _DateRuleType get type => _type;
  _YearRule get yearRule => _yearRule;
  _MonthRule get monthRule => _monthRule;
  _DayRule get dayRule => _dayRule;

  _DateRule.internal(this._name, this._type, this._yearRule, this._monthRule, this._dayRule);

  @override
  bool eval(DateTime date) {
    if (!_yearRule.eval(date)) return false;
    if (!_monthRule.eval(date)) return false;
    if (!_dayRule.eval(date)) return false;

    return true;
  }

  factory _DateRule.holiday(String name, _YearRule yearRule, _MonthRule monthRule, _DayRule dayRule) =>
      _DateRule.internal(name, _DateRuleType.Holiday, yearRule, monthRule, dayRule);
  factory _DateRule.substituteHoliday(String name, _YearRule yearRule, _MonthRule monthRule, _DayRule dayRule) =>
      _DateRule.internal(name, _DateRuleType.SubstituteHoliday, yearRule, monthRule, dayRule);
  factory _DateRule.nationalHoliday(String name, _YearRule yearRule, _MonthRule monthRule, _DayRule dayRule) =>
      _DateRule.internal(name, _DateRuleType.NationalHoliday, yearRule, monthRule, dayRule);
}

class Holiday {
  final String _name;
  final DateTime _date;

  String get name => _name;
  DateTime get date => _date;

  Holiday(this._name, this._date);
}

class JpHoliday {
  static final DateTime _substituteHolidayStartDate = DateTime(1973, 4, 12);

  static final List<_DateRule> _holidayRules = List.unmodifiable([
    _DateRule.holiday('元日', _YearRule.after(1949), _MonthRule.just(1), _DayRule.just(1)),
    _DateRule.holiday('成人の日', _YearRule.after(2000), _MonthRule.just(1), _DayRule.weekday(2, DateTime.monday)),
    _DateRule.holiday('成人の日', _YearRule.range(1949, 1999), _MonthRule.just(1), _DayRule.just(15)),
    _DateRule.holiday('建国記念の日', _YearRule.after(1967), _MonthRule.just(2), _DayRule.just(11)),
    _DateRule.holiday('昭和の日', _YearRule.after(2007), _MonthRule.just(4), _DayRule.just(29)),
    _DateRule.holiday('憲法記念日', _YearRule.after(1949), _MonthRule.just(5), _DayRule.just(3)),
    _DateRule.holiday('みどりの日', _YearRule.after(2007), _MonthRule.just(5), _DayRule.just(4)),
    _DateRule.holiday('みどりの日', _YearRule.range(1989, 2006), _MonthRule.just(4), _DayRule.just(29)),
    _DateRule.holiday('こどもの日', _YearRule.after(1949), _MonthRule.just(5), _DayRule.just(5)),
    _DateRule.holiday('海の日', _YearRule.after(2021), _MonthRule.just(7), _DayRule.weekday(3, DateTime.monday)),
    _DateRule.holiday('海の日', _YearRule.just(2020), _MonthRule.just(7), _DayRule.just(23)),
    _DateRule.holiday('海の日', _YearRule.range(2003, 2019), _MonthRule.just(7), _DayRule.weekday(3, DateTime.monday)),
    _DateRule.holiday('海の日', _YearRule.range(1996, 2002), _MonthRule.just(7), _DayRule.just(20)),
    _DateRule.holiday('山の日', _YearRule.after(2021), _MonthRule.just(8), _DayRule.just(11)),
    _DateRule.holiday('山の日', _YearRule.just(2020), _MonthRule.just(8), _DayRule.just(10)),
    _DateRule.holiday('山の日', _YearRule.range(2016, 2019), _MonthRule.just(8), _DayRule.just(11)),
    _DateRule.holiday('敬老の日', _YearRule.after(2003), _MonthRule.just(9), _DayRule.weekday(3, DateTime.monday)),
    _DateRule.holiday('敬老の日', _YearRule.range(1966, 2002), _MonthRule.just(9), _DayRule.just(15)),
    _DateRule.holiday('体育の日', _YearRule.range(2000, 2019), _MonthRule.just(10), _DayRule.weekday(2, DateTime.monday)),
    _DateRule.holiday('体育の日', _YearRule.range(1966, 1999), _MonthRule.just(10), _DayRule.just(10)),
    _DateRule.holiday('スポーツの日', _YearRule.after(2021), _MonthRule.just(10), _DayRule.weekday(2, DateTime.monday)),
    _DateRule.holiday('スポーツの日', _YearRule.just(2020), _MonthRule.just(7), _DayRule.just(24)),
    _DateRule.holiday('文化の日', _YearRule.after(1948), _MonthRule.just(11), _DayRule.just(3)),
    _DateRule.holiday('勤労感謝の日', _YearRule.after(1948), _MonthRule.just(11), _DayRule.just(23)),
    _DateRule.holiday('天皇誕生日', _YearRule.after(2020), _MonthRule.just(2), _DayRule.just(23)),
    _DateRule.holiday('天皇誕生日', _YearRule.range(1989, 2018), _MonthRule.just(12), _DayRule.just(23)),
    _DateRule.holiday('天皇誕生日', _YearRule.range(1949, 1988), _MonthRule.just(4), _DayRule.just(29)),
    //
    _DateRule.holiday('春分の日', _YearRule.range(1949, 1979), _MonthRule.just(3), _DayRule.func((date) {
      return date.day == (20.8357 + 0.242194 * (date.year - 1980) - ((date.year - 1983) / 4.0).truncate()).truncate();
    })),
    _DateRule.holiday('春分の日', _YearRule.range(1980, 2099), _MonthRule.just(3), _DayRule.func((date) {
      return date.day == (20.8431 + 0.242194 * (date.year - 1980) - ((date.year - 1980) / 4.0).truncate()).truncate();
    })),
    _DateRule.holiday('春分の日', _YearRule.range(2100, 2150), _MonthRule.just(3), _DayRule.func((date) {
      return date.day == (21.8510 + 0.242194 * (date.year - 1980) - ((date.year - 1980) / 4.0).truncate()).truncate();
    })),
    //
    _DateRule.holiday('秋分の日', _YearRule.range(1948, 1979), _MonthRule.just(9), _DayRule.func((date) {
      return date.day == (23.2588 + 0.242194 * (date.year - 1980) - ((date.year - 1983) / 4.0).truncate()).truncate();
    })),
    _DateRule.holiday('秋分の日', _YearRule.range(1980, 2099), _MonthRule.just(9), _DayRule.func((date) {
      return date.day == (23.2488 + 0.242194 * (date.year - 1980) - ((date.year - 1980) / 4.0).truncate()).truncate();
    })),
    _DateRule.holiday('秋分の日', _YearRule.range(2100, 2150), _MonthRule.just(9), _DayRule.func((date) {
      return date.day == (24.2488 + 0.242194 * (date.year - 1980) - ((date.year - 1980) / 4.0).truncate()).truncate();
    })),
    //
    _DateRule.holiday('即位礼正殿の儀', _YearRule.just(2019), _MonthRule.just(10), _DayRule.just(22)),
    _DateRule.holiday('即位礼正殿の儀', _YearRule.just(1990), _MonthRule.just(11), _DayRule.just(12)),
    //
    _DateRule.holiday('天皇の即位の日', _YearRule.just(2019), _MonthRule.just(5), _DayRule.just(1)),
    _DateRule.holiday('皇太子徳仁親王の結婚の儀', _YearRule.just(1993), _MonthRule.just(6), _DayRule.just(9)),
    _DateRule.holiday('昭和天皇の大喪の礼', _YearRule.just(1989), _MonthRule.just(2), _DayRule.just(24)),
    _DateRule.holiday('皇太子明仁親王の結婚の儀', _YearRule.just(1959), _MonthRule.just(4), _DayRule.just(10)),
    //
    _DateRule.substituteHoliday('振替休日', _YearRule.after(2007), _MonthRule.any(), _DayRule.func((date) {
      var tmp = _incrementalDays(date, -1);
      while (_findHoliday(tmp, false, false) != null) {
        if (tmp.weekday == DateTime.sunday) return true;
        tmp = _incrementalDays(tmp, -1);
      }
      return false;
    })),
    _DateRule.substituteHoliday('振替休日', _YearRule.after(1973), _MonthRule.any(), _DayRule.func((date) {
      if (date.compareTo(_substituteHolidayStartDate) >= 0) {
        var tmp = _incrementalDays(date, -1);
        if (_findHoliday(tmp, false, false) != null && tmp.weekday == DateTime.sunday) return true;
      }
      return false;
    })),
    //
    _DateRule.nationalHoliday('国民の休日', _YearRule.after(1986), _MonthRule.any(), _DayRule.func((date) {
      if (date.weekday == DateTime.sunday) return false;

      var tmp1 = _incrementalDays(date, -1);
      var tmp2 = _incrementalDays(date, 1);
      return _findHoliday(tmp1, false, false) != null && _findHoliday(tmp2, false, false) != null;
    })),
  ]);

  static Holiday _findHoliday(DateTime date, bool includeSubstitudeHoliday, bool includeNationalHoliday) {
    Holiday result = null;

    var holidayRule = _holidayRules.firstWhere((rule) {
      if (!includeSubstitudeHoliday && rule.type == _DateRuleType.SubstituteHoliday) return false;
      if (!includeNationalHoliday && rule.type == _DateRuleType.NationalHoliday) return false;
      return rule.eval(date);
    }, orElse: () => null);

    if (holidayRule != null) {
      result = new Holiday(holidayRule.name, date);
    }

    return result;
  }

  /// <summary>
  /// 判定日が休日かどうかを取得します。
  /// </summary>
  /// <param name="date">判定日</param>
  /// <returns>判定日が休日であればtrue、それ以外はfalse</returns>
  static bool isHoliday(DateTime date) => getHoliday(date) != null;

  /// <summary>
  /// 開始日から終了日までに休日が存在するかどうかを取得します。
  /// </summary>
  /// <param name="start">開始日</param>
  /// <param name="end">終了日</param>
  /// <returns>開始日から終了日までに休日が存在する場合はtrue、それ以外はfalse</returns>
  static bool existsHoliday(DateTime start, DateTime end) => getHolidays(start, end).isNotEmpty;

  /// <summary>
  /// 判定日の休日情報を取得します。
  /// </summary>
  /// <param name="date">判定日</param>
  /// <returns>判定日が休日であれば休日情報、それ以外はnull</returns>
  static Holiday getHoliday(DateTime date) => _findHoliday(date, true, true);

  /// <summary>
  /// 開始日から終了日までの休日情報のリストを取得します。
  /// </summary>
  /// <param name="start">開始日</param>
  /// <param name="end">終了日</param>
  /// <returns>開始日から終了日までの休日情報のリスト、休日が無い場合は空のリスト</returns>
  static List<Holiday> getHolidays(DateTime start, DateTime end) {
    var result = new List<Holiday>();
    for (var date = start; date.compareTo(end) <= 0; date = _incrementalDays(date, 1)) {
      var holiday = _findHoliday(date, true, true);
      if (holiday != null) {
        result.add(holiday);
      }
    }
    return result;
  }
}

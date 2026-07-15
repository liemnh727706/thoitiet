// Test các hàm định dạng thuần (không phụ thuộc mạng/plugin).
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:vn_weather/utils/formatters.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('vi_VN', null);
  });

  test('uvLabel phân loại đúng', () {
    expect(uvLabel(null), '--');
    expect(uvLabel(1), 'Thấp');
    expect(uvLabel(4), 'Trung bình');
    expect(uvLabel(7), 'Cao');
    expect(uvLabel(9), 'Rất cao');
    expect(uvLabel(12), 'Cực cao');
  });

  test('formatDayLabel trả về "Hôm nay"/"Ngày mai"', () {
    expect(formatDayLabel(DateTime.now()), 'Hôm nay');
    expect(formatDayLabel(DateTime.now().add(const Duration(days: 1))), 'Ngày mai');
  });

  test('formatHour định dạng HH:mm', () {
    expect(formatHour(DateTime(2026, 7, 15, 9, 5)), '09:05');
  });
}

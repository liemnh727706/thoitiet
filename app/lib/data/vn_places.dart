// Nhãn địa danh tiếng Việt để phủ lên bản đồ radar (base không nhãn).
// Bao gồm quần đảo/đảo (đặt tên chủ quyền tiếng Việt) và các thành phố lớn.
class VnPlace {
  final String name;
  final double lat;
  final double lon;
  final bool island;   // true = đảo/quần đảo, false = thành phố
  final double minZoom; // chỉ hiện từ mức zoom này (giảm rối)
  const VnPlace(this.name, this.lat, this.lon,
      {this.island = false, this.minZoom = 0});
}

const vnPlaces = <VnPlace>[
  // Quần đảo & đảo (hiện sớm vì ngoài biển trống)
  VnPlace('Quần đảo Hoàng Sa', 16.50, 112.00, island: true, minZoom: 4),
  VnPlace('Quần đảo Trường Sa', 9.50, 113.00, island: true, minZoom: 4),
  VnPlace('Đảo Phú Quốc', 10.23, 103.96, island: true, minZoom: 6),
  VnPlace('Côn Đảo', 8.68, 106.60, island: true, minZoom: 6),
  VnPlace('Đảo Phú Quý', 10.53, 108.93, island: true, minZoom: 6),
  VnPlace('Đảo Lý Sơn', 15.38, 109.11, island: true, minZoom: 7),
  VnPlace('Đảo Bạch Long Vĩ', 20.13, 107.72, island: true, minZoom: 6),
  VnPlace('Đảo Cát Bà', 20.72, 107.05, island: true, minZoom: 7),
  VnPlace('Quần đảo Cô Tô', 20.98, 107.77, island: true, minZoom: 7),
  VnPlace('Đảo Cồn Cỏ', 17.16, 107.34, island: true, minZoom: 7),
  // Thành phố lớn (hiện khi zoom vào)
  VnPlace('Hà Nội', 21.03, 105.85, minZoom: 6),
  VnPlace('Hải Phòng', 20.86, 106.68, minZoom: 7),
  VnPlace('Vinh', 18.68, 105.68, minZoom: 7),
  VnPlace('Đà Nẵng', 16.05, 108.22, minZoom: 6),
  VnPlace('Huế', 16.46, 107.59, minZoom: 7),
  VnPlace('Quy Nhơn', 13.77, 109.22, minZoom: 7),
  VnPlace('Nha Trang', 12.24, 109.19, minZoom: 7),
  VnPlace('Đà Lạt', 11.94, 108.44, minZoom: 7),
  VnPlace('Vũng Tàu', 10.35, 107.08, minZoom: 7),
  VnPlace('TP. Hồ Chí Minh', 10.78, 106.70, minZoom: 6),
  VnPlace('Cần Thơ', 10.03, 105.78, minZoom: 7),
  VnPlace('Cà Mau', 9.18, 105.15, minZoom: 7),
];

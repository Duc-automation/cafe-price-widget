/// 1 điểm dữ liệu trên biểu đồ: ngày + giá trị (VND).
class PricePoint {
  final String date; // yyyy-MM-dd
  final int value; // giá trung bình nội địa (đ/kg)

  const PricePoint({required this.date, required this.value});
}

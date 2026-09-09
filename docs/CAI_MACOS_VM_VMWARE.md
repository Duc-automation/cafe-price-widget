# Cài macOS ảo trên VMware Workstation Pro (Windows) → để build iOS

**Mục tiêu:** có môi trường macOS để chạy Xcode, build app Flutter iOS và cài lên **iPhone thật** (Phase 5 của dự án).
**Máy:** VMware Workstation Pro 17.6.1 (miễn phí cho cá nhân) • CPU Intel i7-14700KF • Windows 11.

> ⚠️ **Lưu ý pháp lý:** Apple chỉ cho phép cài macOS trên phần cứng Apple (EULA). Chạy trên VMware Windows là ngoài quy định; bạn tự cân nhắc cho mục đích học/làm. Nên lấy **bộ cài macOS hợp lệ** (từ App Store trên máy Mac thật hoặc mượn Mac).

---

## 1) Bước tiên quyết — "Mở khoá" macOS guest trên VMware
VMware Windows **không nhận macOS guest** nếu chưa unlock:
1. Tải công cụ **VMware unlocker** (bản hỗ trợ VMware 17; ví dụ nhánh phổ biến của DrDonk).
2. Chạy `win-install.cmd` **bằng quyền Admin** (đóng hết VMware trước).
3. Kiểm tra trong thư mục VMware có file `darwin.iso`/`darwinPre15.iso`.
4. **Quan trọng:** VMware 17.6.x khá mới → nếu unlocker chưa theo kịp, macOS không xuất hiện trong danh sách OS. Khi đó cần bản unlocker mới nhất, hoặc cân nhắc hạ VMware xuống bản mà unlocker hỗ trợ.

## 2) Nguồn file cài macOS
Chưa có file cài. 2 hướng hợp lệ nhất:
- **Mượn máy Mac thật** (bạn bè/trường): vào App Store tải macOS (Sonoma 14 / Sequoia 15) rồi tạo file `.iso` để mount vào VMware.
- Thuê **Mac trên mây** thời gian ngắn để lấy bộ cài.
> Chọn macOS **Sonoma 14 trở lên** vì Xcode mới (iOS SDK hiện tại) yêu cầu tối thiểu như vậy.

## 3) Tạo máy ảo trong VMware
1. VMware → **Create a New Virtual Machine** → chọn **Apple Mac OS X** → version khớp (macOS 14/15).
2. Cấu hình đề xuất: **CPU ≥ 4–6 nhân**, **RAM ≥ 8GB** (khuyên 12–16GB), **đĩa ≥ 80GB**.
3. Gắn file `.iso` vào **CD/DVD** → bật máy → cài như máy thật.
4. Sau khi cài, nhớ **cài VMware Tools** để kéo thả/bàn phím ổn định.

## 4) Trong macOS: cài công cụ iOS
1. Mở **App Store** (trong VM) → cài **Xcode** (bản mới nhất; dung lượng rất lớn, chờ lâu).
2. Cài Command Line Tools: mở Terminal chạy `xcode-select --install`.
3. Chạy `sudo xcodebuild -license accept` (nếu cần).
4. Kiểm tra: `flutter doctor` → mục **Xcode / iOS** hiện OK.

## 5) Build & cài lên iPhone thật
1. Trong VMware: **cắm iPhone vào PC** → bật **USB passthrough** cho VM (VM → Removable Devices → chọn iPhone).
2. Trong Xcode: **Signing & Capabilities** → chọn **Team** = Apple ID của bạn.
   - Miễn phí: cài được **7 ngày** rồi phải ký lại.
   - Trả phí Apple Developer **$99/năm**: cài lâu dài + đủ tính năng.
3. Chạy `flutter run -d <iPhone>` từ thư mục `app/` để build + cài.
4. **Widget iOS (WidgetKit)** — code riêng ở Phase 5; thêm vào project này khi có Xcode.

## 6) Rủi ro / lưu ý hiệu năng
- VM không có GPU tăng tốc → Xcode build chậm hơn; **iOS Simulator rất ì** (khuyên test trên iPhone thật).
- VMware/Windows update có thể làm mất unlock → phải unlock lại.
- Cắm iPhone vào VM đôi khi cần cài driver **Apple Mobile Device (iTunes)** trên Windows để Windows nhận iPhone trước khi passthrough.

---
**Trạng thái:** ⏳ chưa có bộ cài macOS; chưa unlock VMware. Làm xong bước 1–2 thì báo để tôi hướng dẫn tiếp + chỉnh `.vmx` cho đúng.

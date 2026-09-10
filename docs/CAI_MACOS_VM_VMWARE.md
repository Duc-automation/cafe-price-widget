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

## 2b) Hướng dẫn download & cài từng bước (cụ thể)

### Bước A — Mở khoá VMware (bắt buộc trước khi thấy macOS)
1. Tải **VMware Unlocker** bản mới nhất (hỗ trợ VMware 17.6): GitHub **DrDonk/unlocker** → mục **Releases** → tải file zip `unlocker-x.y.z.zip`.
   - URL: `https://github.com/DrDonk/unlocker/releases`
2. **Đóng toàn bộ VMware** (kể cả icon khay).
3. Giải nén → chuột phải **`win-install.cmd`** → **Run as administrator**.
4. Kiểm tra: mở thư mục cài VMware (vd `C:\Program Files (x86)\VMware\VMware Workstation\`) thấy file **`darwin.iso`** là OK.
5. Nếu bản unlocker không theo kịp VMware 17.6.x (macOS không hiện trong danh sách OS khi tạo VM) → thử bản unlocker mới hơn, hoặc **hạ VMware xuống bản 17.5.x** mà unlocker hỗ trợ chắc.

### Bước B — Tải bộ cài macOS
Chọn macOS **Sonoma 14.x hoặc Sequoia 15.x** (đủ mới cho Xcode hiện tại). Nguồn tải (chọn 1):
- **Cách hợp lệ nhất:** mượn máy Mac thật → App Store tải "macOS Sonoma" → tạo `.iso`:
  ```
  hdiutil create -o /tmp/Sonoma.cdr -size 16g -layout SPUD -fs HFS+J
  hdiutil attach /tmp/Sonoma.cdr -noverify -mountpoint /Volumes/install_build
  sudo cp -R "/Applications/Install macOS Sonoma.app" /Volumes/install_build
  hdiutil detach /Volumes/install_build
  hdiutil convert /tmp/Sonoma.cdr -format UDTO -o /tmp/Sonoma.iso
  ```
- **Không có Mac:** tải bản **ISO macOS Sonoma/Sequoia** dựng sẵn. Nguồn đề xuất:
  - GitHub **Pyenb/macOS-ISOs** (ISO + link torrent + MD5 hash, dựng bằng MIST):
    `https://github.com/Pyenb/macOS-ISOs`
  - Chọn **macOS Sonoma 14.7** (VD `23H124`, MD5 `26acc94a4c72f850d46bd8e0eff6e8ce`) — đủ mới cho Xcode, hỗ trợ Intel.
  - Các file này tải bằng **torrent** → cài **qBittorrent** rồi mở link torrent. Tải xong nên kiểm tra MD5 cho khớp.
> ⚠️ Lưu ý: file ~13–15GB, tải lâu. Ưu tiên bản tên **"Install macOS Sonoma"** đầy đủ, không phải bản "recovery only".

### Bước C — Tạo máy ảo trong VMware
1. **File → New Virtual Machine → Typical (Recommended)**.
2. Chọn **"Apple Mac OS X"** → Version chọn **macOS 14 (Sonoma)** hoặc **macOS 15** tùy ISO.
3. Đặt tên, chọn nơi lưu (để ổ khác **không phải OneDrive** nếu có — tránh lỗi đồng bộ!).
4. Cấu hình đề xuất cho i7-14700KF:
   - **CPU:** 4–6 lõi (nhớ tick bỏ "Virtualize Intel VT-x" nếu cần — thường mặc định).
   - **RAM:** 12–16GB (tối thiểu 8GB).
   - **Disk:** ≥ 80GB (dung lượng Xcode rất nặng). Chọn "Store as single file" cho nhanh.
5. **Edit VM → CD/DVD (SATA)** → chọn **Use ISO image** → trỏ tới file ISO đã tải.
6. Chỉnh file `.vmx` nếu cần (báo tôi — tôi sẽ ghi dòng cấu hình cho đúng: `smc.version`, `board-id`, `hw.model`, ...).
7. **Power on** → boot từ ISO → cài macOS như máy thật (Disk Utility → xoá ổ → cài lên ổ đó).
8. Sau khi vào được desktop: **VM → Install VMware Tools** (kéo thả, bàn phím, độ phân giải ổn định).

### Bước D — Sau khi có macOS (build iOS)
- App Store (trong VM) → cài **Xcode** (rất lớn, chờ lâu).
- Terminal: `xcode-select --install`.
- Trong thư mục `app/` của dự án: chạy `flutter doctor` kiểm tra mục Xcode/iOS OK.

---
**Trạng thái:** 🚧 đang cài (Bước A–C). Xong bước nào báo để tôi hỗ trợ tiếp (chỉnh `.vmx`, cài Xcode, kết nối iPhone qua USB passthrough).

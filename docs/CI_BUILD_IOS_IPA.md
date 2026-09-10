# Build iOS (.ipa) trên cloud — không cần Xcode trên máy

**Mục đích:** biến code Flutter thành file `.ipa` để cài lên iPhone **mà không cần cài Xcode / macOS 45 GB** trên máy Windows.
**Cách làm:** GitHub Actions chạy máy macOS miễn phí → build ra `.ipa` chưa ký → tải về → **Sideloadly** ký bằng Apple ID và cài vào iPhone.

> Repo hiện là **PUBLIC** ⇒ macOS runner **miễn phí**. Nếu chuyển sang private: macOS tính **10× phút**, gói free 2000 phút/tháng ≈ chỉ ~200 phút macOS (~8–13 lần build).

---

## 1. Workflow đã có sẵn

File: `.github/workflows/ios-ipa.yml`
- Runner: `macos-latest`, Flutter `3.47.2` (khớp bản local), `cache: true`.
- `actions/checkout@v7` + `actions/upload-artifact@v7` (bản mới nhất — v4/v5 bị cảnh báo deprecated Node.js 20).
- Chạy khi: bấm tay (**Actions → Build iOS IPA (unsigned) → Run workflow**) hoặc push có thay đổi trong `app/**`.
- Kết quả:
  - artifact **`Runner-unsigned-ipa`** (chứa `Runner.ipa`), giữ 14 ngày;
  - **GitHub Release tag `ios-latest`** — link tải cố định, không cần đăng nhập (xem mục 2b).

### ✅ Đã kiểm chứng (10/09/2026)

| Lần | Mô tả | Thời gian | Kết quả |
|---|---|---|---|
| 1 | cache lạnh (lần đầu) | **4 phút 17 giây** | ✓ success |
| 2 | cache nóng (không đổi code iOS) | **1 phút 29 giây** | ✓ success |
| 3 | sau khi nâng `@v7` | **3 phút 12 giây** | ✓ success, **hết cảnh báo** |

- Artifact: `Runner-unsigned-ipa`, **7,1 MB**, không hết hạn trong 14 ngày.
- 10/10 bước thành công, 0 annotation/cảnh báo.
- Đường dẫn VD: `https://github.com/Duc-automation/cafe-price-widget/actions/runs/34450269105`

**Vì sao build `--no-codesign`:** CI không có chứng chỉ của bạn, nên build thẳng `Runner.app` rồi tự đóng gói thành `.ipa`. Việc ký do **Sideloadly** làm trên Windows bằng Apple ID cá nhân.

---

## 2. Quy trình build + cài (mỗi lần muốn cập nhật app trên iPhone)

1. Sửa code → commit → push lên `main` (đổi gì trong `app/**` là CI tự chạy).
   - Hoặc ép chạy: **Actions → Run workflow**.
2. Đợi **~1,5–3 phút** (lần đầu ~4–5 phút do tải Flutter; các lần sau nhờ cache nên rất nhanh).
3. Lấy `.ipa` bằng 1 trong 2 cách:
   - **Artifacts** trong run → tải `Runner-unsigned-ipa` (phải đăng nhập GitHub) → giải nén ra `Runner.ipa`
   - **Link cố định**, mở được ngay trên điện thoại, không cần đăng nhập → xem **mục 2b**
4. Mở **Sideloadly** → kéo `Runner.ipa` vào → nhập **Apple ID** → **Start**.
5. iPhone: **Settings → Privacy & Security → Developer Mode → On** (khởi động lại máy), và **Settings → General → VPN & Device Management → Trust** tài khoản Apple của bạn.

### 2b. 📱 Tải trực tiếp trên điện thoại — link cố định (không cần đăng nhập)

Workflow tự đính `.ipa` mới nhất vào **GitHub Release tag `ios-latest`**, nên có **link cố định** luôn trỏ về bản mới nhất:

```
https://github.com/Duc-automation/cafe-price-widget/releases/download/ios-latest/Runner.ipa
```

Mở link này bằng **Safari trên iPhone** → file tải vào app **Files**.

> ⚠️ **Tải được ≠ cài được.** iOS 26 **không** cho cài `.ipa` chưa ký bằng cách bấm vào file (TrollStore đã bị Apple vá từ iOS 17.1 trở lên). Vẫn **bắt buộc** phải có công cụ **ký**:
>
> | Cách ký | Ghi chú |
> |---|---|
> | **Sideloadly / AltStore** trên PC (Windows) | Miễn phí, app sống 7 ngày; chuyển `.ipa` từ iPhone sang PC rồi ký |
> | **ESign / Scarlet / GBox** (ký ngay trên iPhone) | Không cần PC, nhưng là app ngoài luồng → **rủi ro bảo mật** |
> | **TestFlight** ($99/năm) | Cài thẳng trong app TestFlight trên iPhone, không cần PC |

### Bằng dòng lệnh (nếu thích)
```powershell
gh run list --workflow ios-ipa.yml --limit 3
gh run watch <run-id> --exit-status
gh run download <run-id> -n Runner-unsigned-ipa
```

---

## 3. Cài Sideloadly trên Windows

1. Cài **iTunes bản tải từ apple.com** (KHÔNG dùng bản Microsoft Store) — để Windows nhận iPhone (Apple Mobile Device Support).
2. Tải **Sideloadly** tại `sideloadly.io` → cài.
3. Cắm iPhone → **Trust** máy tính trên iPhone.

---

## 4. Giới hạn phải biết (đừng sốc)

| Vấn đề | Thực tế |
|---|---|
| Hạn dùng app | Apple ID **miễn phí** → app chỉ chạy **7 ngày**, sau đó phải chạy lại Sideloadly. **AltStore** có thể tự refresh qua Wi-Fi. |
| Debug UI | **Không có** Xcode GUI / Simulator / breakpoint. Muốn debug sâu phải có Xcode (VM hoặc máy Mac). |
| Build lặp lại | Mỗi lần sửa phải push + chờ CI 10–15 phút. |
| **iOS Widget (Phase 5)** | Thêm target **WidgetKit** vào Xcode project cần **Xcode GUI một lần** (sửa tay `.pbxproj` rất dễ sai). Sau khi target có trong repo, CI build được luôn cả widget. |
| **App Group** | Tài khoản miễn phí **KHÔNG** tạo được App Group ⇒ widget iOS không dùng chung `UserDefaults` với app như thiết kế ban đầu. **Workaround:** widget iOS **tự gọi API `api.chocaphe.vn/v1/prices`** trong `TimelineProvider` và tự lưu cấu hình riêng. |
| Phát hành App Store / TestFlight | Cần Apple Developer **$99/năm**. |

---

## 5. Xử lý lỗi thường gặp trên CI

| Lỗi | Cách sửa |
|---|---|
| `flutter pub get` fail | Kiểm tra `app/pubspec.yaml`, chạy `flutter pub get` ở máy trước |
| Lỗi CocoaPods / không thấy `Podfile` | Bình thường — Flutter tự sinh `Podfile` khi project có plugin. Xem log bước `Build iOS` |
| `Xcode ... requires a newer version of macOS` | Thêm bước `sudo xcode-select -s /Applications/Xcode.app` hoặc đổi `runs-on: macos-14` |
| Build xong nhưng `.ipa` không có | Xem bước "Package into .ipa" — đường dẫn `build/ios/iphoneos/Runner.app` phải tồn tại |
| Hết phút Actions | Repo public → không tốn phút macOS. Private → tắt trigger `push`, chỉ dùng `workflow_dispatch` |

---

## 6. Khi nào vẫn cần Xcode (VM macOS)

Chỉ cho các việc **bắt buộc GUI**:
1. Thêm **Widget Extension target** (Phase 5).
2. Cấu hình **Signing & Capabilities**, App Group (nếu có tài khoản $99).
3. Debug bằng Simulator / Instruments.

→ Khi đó nên cài Xcode **tinh giản**: **KHÔNG** tải iOS Simulator runtime (Xcode: Settings → Components), xoá `~/Library/Developer/CoreSimulator` → tiết kiệm ~10–25 GB. SDK build cho iPhone thật nằm sẵn trong `Xcode.app`.

---

**Trạng thái:** ✅ workflow `ios-ipa.yml` đã chạy thành công 3 lần (10/09/2026), `.ipa` 7,1 MB sẵn sàng. Việc còn lại: tải `.ipa`, cài bằng **Sideloadly** lên iPhone (mục 2–3).

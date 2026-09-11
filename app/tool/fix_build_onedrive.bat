@echo off
REM ============================================================
REM  Fix loi OneDrive: thu muc "build" bi dong bang (pinned)
REM  Trieu chung: "Flutter failed to delete a directory at ...build"
REM  Cach dung: double-click file nay, roi chay lai lenh flutter
REM ============================================================
cd /d "%~dp0.."
echo.
echo Thu muc dang xu ly: %CD%
echo.

if not exist build (
  echo [OK] Khong co thu muc build - khong can sua gi.
  goto :end
)

echo [1/2] Bo thuoc tinh Pinned / Offline ...
attrib -P -U /S /D build 2>nul

echo [2/2] Xoa thu muc build ...
rmdir /S /Q build 2>nul

if exist build (
  echo.
  echo [X] Van chua xoa duoc. Hay dong VS Code / Flutter / Chrome roi thu lai.
  echo     Neu van loi: tat tam OneDrive ^(chuot phai icon OneDrive -^> Pause syncing^) roi chay lai file nay.
) else (
  echo.
  echo [OK] Da xoa build. Bay gio chay lai:
  echo      flutter run -d chrome --web-port=8088
)

:end
echo.
pause

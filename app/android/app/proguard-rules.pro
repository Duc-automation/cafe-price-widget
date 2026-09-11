# ============================================================
#  Quy tắc giữ code (R8 / ProGuard) cho bản RELEASE
# ============================================================
#
#  Vì sao cần file này?
#  Bản release có bật R8 (thu gọn + đổi tên code). R8 "dọn" mất class
#  WorkDatabase_Impl do Room sinh ra, nhưng WorkManager lại tạo nó bằng
#  reflection -> mở app là crash ngay:
#
#    FATAL EXCEPTION: Unable to get provider
#      androidx.startup.InitializationProvider:
#      java.lang.NoSuchMethodException:
#      androidx.work.impl.WorkDatabase_Impl.<init> []
#
#  Các rule dưới đây giữ nguyên những class mà Room/WorkManager tìm bằng
#  reflection (tên class + constructor rỗng).

# --- Room: giữ mọi class Room sinh ra (WorkDatabase_Impl, AppDatabase_Impl...) ---
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep @androidx.room.Entity class * { *; }
-keep class androidx.room.** { *; }
-dontwarn androidx.room.**

# --- WorkManager ---
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

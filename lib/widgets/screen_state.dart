/// Mô hình trạng thái chuẩn cho toàn bộ màn hình nạp dữ liệu (Sealed class)
sealed class ScreenState<T> {
  const ScreenState();
}

/// Trạng thái khởi tạo mặc định (Initial)
class StateInitial<T> extends ScreenState<T> {
  const StateInitial();
}

/// Trạng thái đang tải dữ liệu (Loading)
class StateLoading<T> extends ScreenState<T> {
  final String? message;
  const StateLoading({this.message});
}

/// Trạng thái tải thành công nhưng danh sách rỗng (Empty)
class StateEmpty<T> extends ScreenState<T> {
  final String message;
  const StateEmpty({this.message = 'Không tìm thấy dữ liệu phù hợp.'});
}

/// Trạng thái nạp dữ liệu thành công kèm thực thể dữ liệu (Success)
class StateSuccess<T> extends ScreenState<T> {
  final T data;
  const StateSuccess(this.data);
}

/// Trạng thái xảy ra lỗi (Error)
class StateError<T> extends ScreenState<T> {
  final String errorMessage;
  final bool canRetry;
  const StateError(this.errorMessage, {this.canRetry = true});
}


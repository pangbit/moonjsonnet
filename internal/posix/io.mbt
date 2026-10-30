///|
pub extern "c" fn clear_io_error() -> Unit = "mj_clear_io_error"

///|
#borrow(path)
extern "c" fn io_error_ffi(path : Bytes, input : Int32) -> Bytes = "mj_io_error"

///|
// Consume the OS failure captured by the immediately preceding operation.
// Policy failures have no OS error and continue through their structured path.
pub fn io_error(path : String, input~ : Bool = false) -> String? {
  if path.contains("\u0000") {
    clear_io_error()
    return Some(
      (if input { "Opening input file: " } else { "open " }) +
      path +
      ": invalid argument",
    )
  }
  let bytes = io_error_ffi(@utf8.encode(path), if input { 1 } else { 0 })
  if bytes.is_empty() {
    None
  } else {
    Some(@utf8.decode_lossy(bytes))
  }
}

///|
#borrow(path)
extern "c" fn realpath_ffi(path : Bytes) -> Bytes = "mj_realpath"

///|
#borrow(root, relative)
extern "c" fn read_ffi(root : Bytes, relative : Bytes, limit : Int32) -> Bytes = "mj_read"

///|
#borrow(path, data)
extern "c" fn write_ffi(path : Bytes, data : Bytes) -> Int32 = "mj_write"

///|
#borrow(path)
extern "c" fn mkdir_all_ffi(path : Bytes) -> Int32 = "mj_mkdir_all"

///|
pub fn mkdir_all(path : String) -> Bool {
  !path.is_empty() &&
  !path.contains("\u0000") &&
  mkdir_all_ffi(@utf8.encode(path)) == 0
}

///|
#borrow(path, data)
extern "c" fn output_same_ffi(path : Bytes, data : Bytes) -> Int32 = "mj_output_same"

///|
// 0 missing/different; 1 identical; 2 read error.
pub fn output_same(path : String, text : String) -> Int32 {
  if path.contains("\u0000") {
    2
  } else {
    output_same_ffi(@utf8.encode(path), @utf8.encode(text))
  }
}

///|
#borrow(path)
extern "c" fn open_output_ffi(path : Bytes) -> Int32 = "mj_open_output"

///|
pub fn open_output(path : String) -> Int32 {
  if path.contains("\u0000") {
    -1
  } else {
    open_output_ffi(@utf8.encode(path))
  }
}

///|
#borrow(data)
extern "c" fn write_output_ffi(fd : Int32, data : Bytes) -> Int32 = "mj_write_output"

///|
pub fn write_output(fd : Int32, text : String) -> Bool {
  write_output_ffi(fd, @utf8.encode(text)) == 0
}

///|
pub fn close_output(fd : Int32) -> Bool {
  close_output_ffi(fd) == 0
}

///|
extern "c" fn close_output_ffi(fd : Int32) -> Int32 = "mj_close_output"

///|
#borrow(data)
extern "c" fn stderr_ffi(data : Bytes) -> Unit = "mj_stderr"

///|
#borrow(data)
extern "c" fn stdout_ffi(data : Bytes) -> Int32 = "mj_stdout"

///|
extern "c" fn stdout_is_terminal_ffi() -> Int32 = "mj_stdout_is_terminal"

///|
pub fn stdout_is_terminal() -> Bool {
  stdout_is_terminal_ffi() == 1
}

///|
pub fn stdout(text : String) -> Bool {
  stdout_ffi(@utf8.encode(text)) == 0
}

///|
pub extern "c" fn exit(code : Int32) -> Unit = "mj_exit"

///|
extern "c" fn stdin_ffi(limit : Int32) -> Bytes = "mj_stdin"

///|
// 0 success; 1 I/O/allocation failure; 2 invalid limit; 3 byte limit exceeded.
pub fn read_stdin(limit : Int32) -> (Int32, Bytes) {
  let data = stdin_ffi(limit)
  if data[0] != 0 {
    (data[0].to_int(), b"")
  } else {
    (0, data[1:].to_owned())
  }
}

///|
pub fn canonical(path : String) -> String? {
  let (status, result) = canonical_result(path)
  if status == 0 {
    Some(result)
  } else {
    None
  }
}

///|
// 0 success; 1 I/O failure; 2 invalid path; 5 invalid UTF-8; 6 not found.
pub fn canonical_result(path : String) -> (Int32, String) {
  if path.contains("\u0000") {
    return (2, "")
  }
  let bytes = realpath_ffi(@utf8.encode(path))
  if bytes[0] != 0 {
    return (bytes[0].to_int(), "")
  }
  (0, @utf8.decode(bytes[1:])) catch {
    _ => (5, "")
  }
}

///|
pub fn read(root : String, relative : String, limit : Int32) -> (Int32, String) {
  let (status, data) = read_bytes(root, relative, limit)
  if status != 0 {
    return (status, "")
  }
  (0, @utf8.decode(data)) catch {
    _ => (5, "")
  }
}

///|
pub fn read_bytes(
  root : String,
  relative : String,
  limit : Int32,
) -> (Int32, Bytes) {
  if root.contains("\u0000") || relative.contains("\u0000") {
    return (2, b"")
  }
  let data = read_ffi(@utf8.encode(root), @utf8.encode(relative), limit)
  if data[0] != 0 {
    return (data[0].to_int(), b"")
  }
  (0, data[1:].to_owned())
}

///|
pub fn write(path : String, text : String) -> Bool {
  !path.contains("\u0000") &&
  write_ffi(@utf8.encode(path), @utf8.encode(text)) == 0
}

///|
pub fn stderr(message : String) -> Unit {
  stderr_ffi(@utf8.encode(message))
}

///|
// Write arbitrary diagnostic bytes followed by one LF.
pub fn stderr_bytes(message : Bytes) -> Unit {
  stderr_ffi(message)
}

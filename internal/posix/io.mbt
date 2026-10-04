///|
#borrow(path)
extern "c" fn realpath_ffi(path : Bytes) -> Bytes = "mj_realpath"

///|
#borrow(root, relative)
extern "c" fn read_ffi(root : Bytes, relative : Bytes, limit : Int) -> Bytes = "mj_read"

///|
#borrow(path, data)
extern "c" fn write_ffi(path : Bytes, data : Bytes) -> Int = "mj_write"

///|
#borrow(path)
extern "c" fn mkdir_all_ffi(path : Bytes) -> Int = "mj_mkdir_all"

///|
pub fn mkdir_all(path : String) -> Bool {
  !path.is_empty() &&
  !path.contains("\u0000") &&
  mkdir_all_ffi(@utf8.encode(path)) == 0
}

///|
#borrow(path, data)
extern "c" fn output_same_ffi(path : Bytes, data : Bytes) -> Int = "mj_output_same"

///|
// 0 missing/different; 1 identical; 2 read error.
pub fn output_same(path : String, text : String) -> Int {
  if path.contains("\u0000") {
    2
  } else {
    output_same_ffi(@utf8.encode(path), @utf8.encode(text))
  }
}

///|
#borrow(path)
extern "c" fn open_output_ffi(path : Bytes) -> Int = "mj_open_output"

///|
pub fn open_output(path : String) -> Int {
  if path.contains("\u0000") {
    -1
  } else {
    open_output_ffi(@utf8.encode(path))
  }
}

///|
#borrow(data)
extern "c" fn write_output_ffi(fd : Int, data : Bytes) -> Int = "mj_write_output"

///|
pub fn write_output(fd : Int, text : String) -> Bool {
  write_output_ffi(fd, @utf8.encode(text)) == 0
}

///|
pub fn close_output(fd : Int) -> Bool {
  close_output_ffi(fd) == 0
}

///|
extern "c" fn close_output_ffi(fd : Int) -> Int = "mj_close_output"

///|
#borrow(data)
extern "c" fn stderr_ffi(data : Bytes) -> Unit = "mj_stderr"

///|
#borrow(data)
extern "c" fn stdout_ffi(data : Bytes) -> Int = "mj_stdout"

///|
pub fn stdout(text : String) -> Bool {
  stdout_ffi(@utf8.encode(text)) == 0
}

///|
pub extern "c" fn exit(code : Int) -> Unit = "mj_exit"

///|
extern "c" fn stdin_ffi(limit : Int) -> Bytes = "mj_stdin"

///|
// 0 success; 1 I/O/allocation failure; 2 invalid limit; 3 byte limit exceeded.
pub fn read_stdin(limit : Int) -> (Int, Bytes) {
  let data = stdin_ffi(limit)
  if data[0] != 0 {
    (data[0].to_int(), b"")
  } else {
    (0, data[1:].to_owned())
  }
}

///|
pub fn canonical(path : String) -> String? {
  if path.contains("\u0000") {
    return None
  }
  let bytes = realpath_ffi(@utf8.encode(path))
  if bytes.is_empty() {
    None
  } else {
    Some(@utf8.decode(bytes)) catch {
      _ => None
    }
  }
}

///|
pub fn read(root : String, relative : String, limit : Int) -> (Int, String) {
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
  limit : Int,
) -> (Int, Bytes) {
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

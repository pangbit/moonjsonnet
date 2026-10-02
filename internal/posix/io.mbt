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
#borrow(data)
extern "c" fn stderr_ffi(data : Bytes) -> Unit = "mj_stderr"

///|
pub extern "c" fn exit(code : Int) -> Unit = "mj_exit"

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
  if root.contains("\u0000") || relative.contains("\u0000") {
    return (2, "")
  }
  let data = read_ffi(@utf8.encode(root), @utf8.encode(relative), limit)
  if data[0] != 0 {
    return (data[0].to_int(), "")
  }
  (0, @utf8.decode(data[1:])) catch {
    _ => (5, "")
  }
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

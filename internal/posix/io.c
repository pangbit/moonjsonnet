#define _XOPEN_SOURCE 700
#define _DARWIN_C_SOURCE
#include <moonbit.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <errno.h>
#include <locale.h>

enum { IO_OPEN = 1, IO_READ, IO_WRITE, IO_CLOSE, IO_MKDIR };
/* Capture errno before cleanup changes it. Only scalar state is retained, and
 * each operation starts fresh. Prefix lengths identify MkdirAll's failing
 * ancestor without retaining MoonBit memory or allocating a saved path. */
static _Thread_local int io_errno, io_operation, io_prefix = -1;

MOONBIT_FFI_EXPORT void mj_clear_io_error(void) {
  io_errno = io_operation = 0;
  io_prefix = -1;
}

static void record_io_error(int operation, int error, int prefix) {
  io_operation = operation;
  io_errno = error ? error : EIO;
  io_prefix = prefix;
}

MOONBIT_FFI_EXPORT moonbit_bytes_t mj_io_error(moonbit_bytes_t path, int32_t input) {
  if (!io_errno) return moonbit_make_bytes(0, 0);
  int error = io_errno, operation = io_operation, length = io_prefix;
  mj_clear_io_error();
  const char *prefix = operation == IO_OPEN ? "open " :
                       operation == IO_READ ? "read " :
                       operation == IO_WRITE ? "write " :
                       operation == IO_CLOSE ? "close " : "mkdir ";
  if (input && operation == IO_OPEN) prefix = "Opening input file: ";
  if (input && operation == IO_READ) prefix = "Reading input file: ";
  size_t path_length = Moonbit_array_length(path);
  if (length >= 0 && (size_t)length < path_length) path_length = (size_t)length;
  locale_t locale = newlocale(LC_MESSAGES_MASK, "C", (locale_t)0);
  locale_t previous = locale ? uselocale(locale) : (locale_t)0;
  const char *message = previous ? strerror(error) : "I/O error";
  size_t prefix_length = strlen(prefix), message_length = strlen(message);
  moonbit_bytes_t out = moonbit_make_bytes((int32_t)(prefix_length + path_length + 2 + message_length), 0);
  memcpy(out, prefix, prefix_length);
  memcpy(out + prefix_length, path, path_length);
  memcpy(out + prefix_length + path_length, ": ", 2);
  memcpy(out + prefix_length + path_length + 2, message, message_length);
  uint8_t *first = out + prefix_length + path_length + 2;
  if (*first >= 'A' && *first <= 'Z') *first += 'a' - 'A';
  if (previous) uselocale(previous);
  if (locale) freelocale(locale);
  return out;
}

static moonbit_bytes_t status(int code) {
  return moonbit_make_bytes(1, (uint8_t)code);
}

MOONBIT_FFI_EXPORT moonbit_bytes_t mj_realpath(const uint8_t *path) {
  mj_clear_io_error();
  char *p = realpath((const char *)path, NULL);
  if (!p) { int error = errno; record_io_error(IO_OPEN, error, -1); return status(error == ENOENT ? 6 : 1); }
  size_t n = strlen(p);
  moonbit_bytes_t out = moonbit_make_bytes((int32_t)n + 1, 0);
  memcpy(out + 1, p, n);
  free(p);
  return out;
}

/* Resolve first in MoonBit; then walk the canonical relative path by directory
 * descriptors, refusing symlinks during the walk. Never open special files. */
MOONBIT_FFI_EXPORT moonbit_bytes_t mj_read(const uint8_t *root,
                                         const uint8_t *relative, int32_t limit) {
  mj_clear_io_error();
  if (limit <= 0 || limit == INT32_MAX || relative[0] == '/') return status(2);
  int fd = open((const char *)root, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
  if (fd < 0) { record_io_error(IO_OPEN, errno, -1); return status(1); }
  char *path = strdup((const char *)relative);
  if (!path) { record_io_error(IO_OPEN, ENOMEM, -1); close(fd); return status(1); }
  char *save = NULL;
  char *part = strtok_r(path, "/", &save);
  if (!part) { free(path); close(fd); return status(2); }
  while (part) {
    char *next = strtok_r(NULL, "/", &save);
    if (!strcmp(part, ".") || !strcmp(part, "..")) {
      free(path); close(fd); return status(2);
    }
    int child = openat(fd, part, O_RDONLY | O_NOFOLLOW | O_CLOEXEC |
                                  (next ? O_DIRECTORY : O_NONBLOCK));
    int error = errno;
    close(fd);
    if (child < 0) { record_io_error(IO_OPEN, error, -1); free(path); return status(error == ENOENT ? 6 : 1); }
    fd = child;
    part = next;
  }
  free(path);
  struct stat st;
  if (fstat(fd, &st)) { record_io_error(IO_READ, errno, -1); close(fd); return status(4); }
  if (!S_ISREG(st.st_mode)) { if (S_ISDIR(st.st_mode)) record_io_error(IO_READ, EISDIR, -1); close(fd); return status(4); }
  if (st.st_size > limit) { close(fd); return status(3); }
  uint8_t *buffer = malloc((size_t)limit + 1);
  if (!buffer) { record_io_error(IO_READ, ENOMEM, -1); close(fd); return status(1); }
  size_t used = 0;
  while (used <= (size_t)limit) {
    ssize_t n = read(fd, buffer + used, (size_t)limit + 1 - used);
    if (n < 0 && errno == EINTR) continue;
    if (n < 0) { record_io_error(IO_READ, errno, -1); free(buffer); close(fd); return status(1); }
    if (!n) break;
    used += (size_t)n;
  }
  close(fd);
  if (used > (size_t)limit) { free(buffer); return status(3); }
  moonbit_bytes_t out = moonbit_make_bytes((int32_t)used + 1, 0);
  memcpy(out + 1, buffer, used);
  free(buffer);
  return out;
}

MOONBIT_FFI_EXPORT int32_t mj_write(const uint8_t *path, moonbit_bytes_t data) {
  mj_clear_io_error();
  FILE *f = fopen((const char *)path, "wb");
  if (!f) { record_io_error(IO_OPEN, errno, -1); return 1; }
  size_t size = Moonbit_array_length(data);
  int ok = fwrite(data, 1, size, f) == size;
  if (!ok) record_io_error(IO_WRITE, errno, -1);
  if (fclose(f)) { record_io_error(IO_CLOSE, errno, -1); ok = 0; }
  return ok ? 0 : 1;
}

static int ensure_directory(const char *path) {
  if (!mkdir(path, 0755)) return 0;
  int error = errno;
  struct stat st;
  if (error == EEXIST && !stat(path, &st)) return S_ISDIR(st.st_mode) ? 0 : ENOTDIR;
  return error;
}

/* The caller supplies a lexically cleaned parent path, as in filepath.Dir. */
MOONBIT_FFI_EXPORT int32_t mj_mkdir_all(const uint8_t *path) {
  mj_clear_io_error();
  char *copy = strdup((const char *)path);
  if (!copy) { record_io_error(IO_MKDIR, ENOMEM, -1); return 1; }
  for (char *p = copy + 1; *p; p++) {
    if (*p != '/') continue;
    *p = 0;
    int error = ensure_directory(copy);
    *p = '/';
    if (error) { record_io_error(IO_MKDIR, error, (int)(p - copy)); free(copy); return 1; }
  }
  int error = ensure_directory(copy);
  if (error) record_io_error(IO_MKDIR, error, -1);
  free(copy);
  return error ? 1 : 0;
}

/* 0 missing/different, 1 identical, 2 read error. Compare without decoding or
 * loading an unbounded existing file. Symlinks follow the explicit output path. */
MOONBIT_FFI_EXPORT int32_t mj_output_same(const uint8_t *path, moonbit_bytes_t data) {
  mj_clear_io_error();
  struct stat st;
  if (stat((const char *)path, &st)) {
    int error = errno;
    if (error == ENOENT) return 0;
    record_io_error(IO_OPEN, error, -1); return 2;
  }
  FILE *f = fopen((const char *)path, "rb");
  if (!f) { record_io_error(IO_OPEN, errno, -1); return 2; }
  if (S_ISDIR(st.st_mode)) { record_io_error(IO_READ, EISDIR, -1); fclose(f); return 2; }
  size_t size = Moonbit_array_length(data), used = 0;
  uint8_t buffer[4096];
  int same = 1;
  for (;;) {
    size_t remaining = size - used;
    size_t want = remaining < sizeof(buffer) ? remaining + 1 : sizeof(buffer);
    size_t n = fread(buffer, 1, want, f);
    if (ferror(f)) { record_io_error(IO_READ, errno, -1); fclose(f); return 2; }
    if (n > remaining || memcmp(buffer, data + used, n)) { same = 0; break; }
    used += n;
    if (n < want) { same = used == size; break; }
  }
  if (fclose(f)) { record_io_error(IO_CLOSE, errno, -1); return 2; }
  return same;
}

MOONBIT_FFI_EXPORT int32_t mj_open_output(const uint8_t *path) {
  mj_clear_io_error();
  int fd = open((const char *)path, O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0666);
  if (fd < 0) record_io_error(IO_OPEN, errno, -1);
  return fd;
}

MOONBIT_FFI_EXPORT int32_t mj_write_output(int32_t fd, moonbit_bytes_t data) {
  mj_clear_io_error();
  size_t size = Moonbit_array_length(data), used = 0;
  while (used < size) {
    ssize_t n = write(fd, data + used, size - used);
    if (n < 0 && errno == EINTR) continue;
    if (n <= 0) { record_io_error(IO_WRITE, n < 0 ? errno : EIO, -1); return 1; }
    used += (size_t)n;
  }
  return 0;
}

MOONBIT_FFI_EXPORT int32_t mj_close_output(int32_t fd) {
  mj_clear_io_error();
  int result = close(fd);
  if (result) record_io_error(IO_CLOSE, errno, -1);
  return result;
}

/* Consume stdin up to limit + 1 bytes. Never close the process-owned descriptor.
 * Reading one extra byte distinguishes exact-size input from an overrun. */
MOONBIT_FFI_EXPORT moonbit_bytes_t mj_stdin(int32_t limit) {
  mj_clear_io_error();
  if (limit <= 0 || limit == INT32_MAX) return status(2);
  uint8_t *buffer = malloc((size_t)limit + 1);
  if (!buffer) { record_io_error(IO_READ, ENOMEM, -1); return status(1); }
  size_t used = 0;
  while (used <= (size_t)limit) {
    ssize_t n = read(STDIN_FILENO, buffer + used, (size_t)limit + 1 - used);
    if (n < 0 && errno == EINTR) continue;
    if (n < 0) { record_io_error(IO_READ, errno, -1); free(buffer); return status(1); }
    if (!n) break;
    used += (size_t)n;
  }
  if (used > (size_t)limit) { free(buffer); return status(3); }
  moonbit_bytes_t out = moonbit_make_bytes((int32_t)used + 1, 0);
  memcpy(out + 1, buffer, used);
  free(buffer);
  return out;
}

MOONBIT_FFI_EXPORT void mj_stderr(moonbit_bytes_t data) {
  fwrite(data, 1, Moonbit_array_length(data), stderr);
  fputc('\n', stderr);
}

MOONBIT_FFI_EXPORT int32_t mj_stdout_is_terminal(void) {
  return isatty(STDOUT_FILENO) ? 1 : 0;
}

/* Borrow the buffer for this call; stdout remains owned by the process. */
MOONBIT_FFI_EXPORT int32_t mj_stdout(moonbit_bytes_t data) {
  mj_clear_io_error();
  size_t size = Moonbit_array_length(data);
  int ok = fwrite(data, 1, size, stdout) == size;
  if (!ok) record_io_error(IO_WRITE, errno, -1);
  if (fflush(stdout)) { record_io_error(IO_WRITE, errno, -1); ok = 0; }
  return ok ? 0 : 1;
}

MOONBIT_FFI_EXPORT void mj_exit(int32_t code) { exit(code); }

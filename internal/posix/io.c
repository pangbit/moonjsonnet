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

static moonbit_bytes_t status(int code) {
  return moonbit_make_bytes(1, (uint8_t)code);
}

MOONBIT_FFI_EXPORT moonbit_bytes_t mj_realpath(const uint8_t *path) {
  char *p = realpath((const char *)path, NULL);
  if (!p) return status(errno == ENOENT ? 6 : 1);
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
  if (limit <= 0 || limit == INT32_MAX || relative[0] == '/') return status(2);
  int fd = open((const char *)root, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
  if (fd < 0) return status(1);
  char *path = strdup((const char *)relative);
  if (!path) { close(fd); return status(1); }
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
    if (child < 0) { free(path); return status(error == ENOENT ? 6 : 1); }
    fd = child;
    part = next;
  }
  free(path);
  struct stat st;
  if (fstat(fd, &st) || !S_ISREG(st.st_mode)) { close(fd); return status(4); }
  if (st.st_size > limit) { close(fd); return status(3); }
  uint8_t *buffer = malloc((size_t)limit + 1);
  if (!buffer) { close(fd); return status(1); }
  size_t used = 0;
  while (used <= (size_t)limit) {
    ssize_t n = read(fd, buffer + used, (size_t)limit + 1 - used);
    if (n < 0 && errno == EINTR) continue;
    if (n < 0) { free(buffer); close(fd); return status(1); }
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
  FILE *f = fopen((const char *)path, "wb");
  if (!f) return 1;
  size_t size = Moonbit_array_length(data);
  int ok = fwrite(data, 1, size, f) == size;
  if (fclose(f)) ok = 0;
  return ok ? 0 : 1;
}

static int ensure_directory(const char *path) {
  if (!mkdir(path, 0755)) return 0;
  struct stat st;
  return errno == EEXIST && !stat(path, &st) && S_ISDIR(st.st_mode) ? 0 : 1;
}

/* The caller supplies a lexically cleaned parent path, as in filepath.Dir. */
MOONBIT_FFI_EXPORT int32_t mj_mkdir_all(const uint8_t *path) {
  char *copy = strdup((const char *)path);
  if (!copy) return 1;
  for (char *p = copy + 1; *p; p++) {
    if (*p != '/') continue;
    *p = 0;
    int error = ensure_directory(copy);
    *p = '/';
    if (error) { free(copy); return 1; }
  }
  int error = ensure_directory(copy);
  free(copy);
  return error;
}

/* 0 missing/different, 1 identical, 2 read error. Compare without decoding or
 * loading an unbounded existing file. Symlinks follow the explicit output path. */
MOONBIT_FFI_EXPORT int32_t mj_output_same(const uint8_t *path, moonbit_bytes_t data) {
  struct stat st;
  if (stat((const char *)path, &st)) {
    return errno == ENOENT || errno == ENOTDIR ? 0 : 2;
  }
  FILE *f = fopen((const char *)path, "rb");
  if (!f) return 2;
  if (S_ISDIR(st.st_mode)) { fclose(f); return 2; }
  size_t size = Moonbit_array_length(data), used = 0;
  uint8_t buffer[4096];
  int same = 1;
  for (;;) {
    size_t remaining = size - used;
    size_t want = remaining < sizeof(buffer) ? remaining + 1 : sizeof(buffer);
    size_t n = fread(buffer, 1, want, f);
    if (ferror(f)) { fclose(f); return 2; }
    if (n > remaining || memcmp(buffer, data + used, n)) { same = 0; break; }
    used += n;
    if (n < want) { same = used == size; break; }
  }
  if (fclose(f)) return 2;
  return same;
}

MOONBIT_FFI_EXPORT int32_t mj_open_output(const uint8_t *path) {
  return open((const char *)path, O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0666);
}

MOONBIT_FFI_EXPORT int32_t mj_write_output(int32_t fd, moonbit_bytes_t data) {
  size_t size = Moonbit_array_length(data), used = 0;
  while (used < size) {
    ssize_t n = write(fd, data + used, size - used);
    if (n < 0 && errno == EINTR) continue;
    if (n <= 0) return 1;
    used += (size_t)n;
  }
  return 0;
}

MOONBIT_FFI_EXPORT int32_t mj_close_output(int32_t fd) { return close(fd); }

/* Consume stdin up to limit + 1 bytes. Never close the process-owned descriptor.
 * Reading one extra byte distinguishes exact-size input from an overrun. */
MOONBIT_FFI_EXPORT moonbit_bytes_t mj_stdin(int32_t limit) {
  if (limit <= 0 || limit == INT32_MAX) return status(2);
  uint8_t *buffer = malloc((size_t)limit + 1);
  if (!buffer) return status(1);
  size_t used = 0;
  while (used <= (size_t)limit) {
    ssize_t n = read(STDIN_FILENO, buffer + used, (size_t)limit + 1 - used);
    if (n < 0 && errno == EINTR) continue;
    if (n < 0) { free(buffer); return status(1); }
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

/* Borrow the buffer for this call; stdout remains owned by the process. */
MOONBIT_FFI_EXPORT int32_t mj_stdout(moonbit_bytes_t data) {
  size_t size = Moonbit_array_length(data);
  int ok = fwrite(data, 1, size, stdout) == size;
  if (fflush(stdout)) ok = 0;
  return ok ? 0 : 1;
}

MOONBIT_FFI_EXPORT void mj_exit(int32_t code) { exit(code); }

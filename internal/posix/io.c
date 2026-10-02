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
  if (!p) return moonbit_make_bytes(0, 0);
  size_t n = strlen(p);
  moonbit_bytes_t out = moonbit_make_bytes((int32_t)n, 0);
  memcpy(out, p, n);
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
    close(fd);
    if (child < 0) { free(path); return status(1); }
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

MOONBIT_FFI_EXPORT void mj_stderr(moonbit_bytes_t data) {
  fwrite(data, 1, Moonbit_array_length(data), stderr);
  fputc('\n', stderr);
}

MOONBIT_FFI_EXPORT void mj_exit(int32_t code) { exit(code); }

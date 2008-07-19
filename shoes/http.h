//
// shoes/http.h
// the shoes downloader, which uses platform code and threads
// to achieve much faster and brain-dead http access.
//
#define SHOES_CHUNKSIZE 16384

#define SHOES_DOWNLOAD_CONTINUE 0
#define SHOES_DOWNLOAD_HALT 1

#define SHOES_HTTP_CONNECTED 5
#define SHOES_HTTP_TRANSFER  10
#define SHOES_HTTP_COMPLETED 15

#define HTTP_EVENT(handler, s, last, perc, trans, tot, dat, abort) \
{ struct timespec ts, tse; \
  clock_gettime(CLOCK_REALTIME, &ts); \
  tse = shoes_time_diff(last, ts); \
  if (s != SHOES_HTTP_TRANSFER || tse.tv_nsec > 300000000 ) { \
    shoes_download_event event; \
    event.stage = s; \
    if (s == SHOES_HTTP_COMPLETED) event.stage = SHOES_HTTP_TRANSFER; \
    event.percent = perc; \
    event.transferred = trans;\
    event.total = tot; \
    last = ts; \
    if (handler != NULL && (handler(&event, dat) & SHOES_DOWNLOAD_HALT)) \
    { abort; } \
    if (s == SHOES_HTTP_COMPLETED) { event.stage = s; \
      if (handler != NULL && (handler(&event, dat) & SHOES_DOWNLOAD_HALT)) \
      { abort; } \
    } \
  } }

typedef struct {
  unsigned char stage;
  unsigned LONG_LONG total;
  unsigned LONG_LONG transferred;
  unsigned long percent;
} shoes_download_event;

typedef int (*shoes_download_handler)(shoes_download_event *, void *);

typedef struct {
  char *host;
  int port;
  char *path;
  char *mem;
  char *filepath;
  unsigned LONG_LONG size;
  shoes_download_handler handler;
  void *data;
} shoes_download_request;

void shoes_download(shoes_download_request *req);
void shoes_queue_download(shoes_download_request *req);

#ifdef SHOES_WIN32
#include <stdio.h>
#include <windows.h>
#include <winhttp.h>
void shoes_winhttp(LPCWSTR, INTERNET_PORT, LPCWSTR, TCHAR *, HANDLE, LPDWORD, shoes_download_handler, void *);
#define HTTP_HANDLER(x) reinterpret_cast<shoes_download_handler>(x)
#else
#define HTTP_HANDLER(x)
#endif
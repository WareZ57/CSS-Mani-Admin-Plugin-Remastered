// MySQL stand-in for the 64-bit build: no client library is linked, every connection fails cleanly
// ("MySQL support not available") and Mani falls back to its text files (clients.txt, etc.)
#ifndef MANI_X64_MYSQL_STUB_H
#define MANI_X64_MYSQL_STUB_H

typedef struct st_mysql { int unused; } MYSQL;
typedef struct st_mysql_res { int unused; } MYSQL_RES;
typedef struct st_mysql_field { char *name; } MYSQL_FIELD;
typedef char **MYSQL_ROW;
typedef unsigned long long my_ulonglong;
typedef char my_bool;
enum mysql_option { MYSQL_OPT_CONNECT_TIMEOUT };

static inline MYSQL *mysql_init(MYSQL *mysql) { static MYSQL dummy; return mysql ? mysql : &dummy; }
static inline int mysql_options(MYSQL *, enum mysql_option, const void *) { return 0; }
static inline MYSQL *mysql_real_connect(MYSQL *, const char *, const char *, const char *, const char *,
	unsigned int, const char *, unsigned long) { return 0; }
static inline void mysql_close(MYSQL *) {}
static inline unsigned int mysql_errno(MYSQL *) { return 2000; }
static inline const char *mysql_error(MYSQL *) { return "MySQL support not available in the 64-bit build"; }
static inline int mysql_select_db(MYSQL *, const char *) { return 1; }
static inline int mysql_query(MYSQL *, const char *) { return 1; }
static inline MYSQL_RES *mysql_store_result(MYSQL *) { return 0; }
static inline void mysql_free_result(MYSQL_RES *) {}
static inline my_ulonglong mysql_num_rows(MYSQL_RES *) { return 0; }
static inline unsigned int mysql_num_fields(MYSQL_RES *) { return 0; }
static inline MYSQL_ROW mysql_fetch_row(MYSQL_RES *) { return 0; }
static inline my_ulonglong mysql_insert_id(MYSQL *) { return 0; }
static inline const char *mysql_get_server_info(MYSQL *) { return ""; }
static inline unsigned long mysql_thread_id(MYSQL *) { return 0; }
static inline my_bool mysql_thread_init(void) { return 0; }
static inline void mysql_thread_end(void) {}
static inline unsigned int mysql_thread_safe(void) { return 1; }

#endif

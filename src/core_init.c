int sqlite3_webext_init(sqlite3 *db, char **pzErrMsg,
                        const sqlite3_api_routines *pApi);

int core_init(const char *dummy)
{
  return sqlite3_auto_extension((void *)sqlite3_webext_init);
  // return SQLITE_OK;
}

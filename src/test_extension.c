#include "sqlite3ext.h"
SQLITE_EXTENSION_INIT1

#include "test_extension.h"

#ifdef _WIN32
__declspec(dllexport)
#endif
    int sqlite3_test_extension_init(sqlite3 *db, char **pzErrMsg,
                                    const sqlite3_api_routines *pApi)
{
  sqlite3_commit_hook(db, testext_commit_hook, 0);
  return SQLITE_OK;
}
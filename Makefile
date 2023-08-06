# dependencies

# TODO: pull latest sqlite
SQLITE_AMALGAMATION = sqlite-amalgamation-3410200
SQLITE_AMALGAMATION_ZIP_URL = https://www.sqlite.org/2023/${SQLITE_AMALGAMATION}.zip
SQLITE_AMALGAMATION_ZIP_SHA = 01df06a84803c1ab4d62c64e995b151b2dbcf5dbc93bbc5eee213cb18225d987

EXTENSION_FUNCTIONS = extension-functions.c
EXTENSION_FUNCTIONS_URL = https://www.sqlite.org/contrib/download/extension-functions.c?get=25
EXTENSION_FUNCTIONS_SHA = 991b40fe8b2799edc215f7260b890f14a833512c9d9896aa080891330ffe4052

# source files

LIBRARY_FILES = src/libauthorizer.js src/libfunction.js src/libmodule.js src/libprogress.js src/libvfs.js
EXPORTED_FUNCTIONS = src/exported_functions.json
EXPORTED_RUNTIME_METHODS = src/extra_exported_runtime_methods.json
ASYNCIFY_IMPORTS = src/asyncify_imports.json

# intermediate files

RS_LIB = crsql_bundle
RS_LIB_DIR = ./crsql/rs/bundle
RS_WASM_TGT = wasm32-unknown-emscripten
RS_WASM_TGT_DIR = $(RS_LIB_DIR)/target/$(RS_WASM_TGT)
RS_RELEASE_BC = $(RS_WASM_TGT_DIR)/release/deps/$(RS_LIB).bc
RS_DEBUG_BC = $(RS_WASM_TGT_DIR)/debug/deps/$(RS_LIB).bc

OBJ_FILES_DEBUG = \
	tmp/obj/debug/extension-functions.o \
	tmp/obj/debug/libauthorizer.o \
	tmp/obj/debug/libfunction.o \
	tmp/obj/debug/libmodule.o \
	tmp/obj/debug/libprogress.o \
	tmp/obj/debug/libvfs.o

OBJ_FILES_DIST = \
	tmp/obj/dist/extension-functions.o \
	tmp/obj/dist/libauthorizer.o \
	tmp/obj/dist/libfunction.o \
	tmp/obj/dist/libmodule.o \
	tmp/obj/dist/libprogress.o \
	tmp/obj/dist/libvfs.o

dir.crsql := ./crsql/src

crsql-files := \
	$(dir.crsql)/crsqlite.c\
	$(dir.crsql)/util.c \
	$(dir.crsql)/tableinfo.c \
	$(dir.crsql)/changes-vtab.c \
	$(dir.crsql)/ext-data.c \
	$(dir.crsql)/get-table.c

sqlite3.c := deps/$(SQLITE_AMALGAMATION)/sqlite3.c
sqlite3.extra.c := deps/$(SQLITE_AMALGAMATION)/sqlite3-extra.c

# build options

EMCC ?= emcc

CFLAGS_COMMON = \
	-I'deps/$(SQLITE_AMALGAMATION)' \
	-I$(dir.crsql) \
	-Wno-non-literal-null-conversion

CFLAGS_DEBUG = $(CFLAGS_COMMON) -g

CFLAGS_DIST = $(CFLAGS_COMMON)

EMFLAGS_COMMON = \
	-s ALLOW_MEMORY_GROWTH=1 \
	-s WASM=1 \
	-s INVOKE_RUN \
	-s ENVIRONMENT="web,worker" \
	-s STACK_SIZE=512KB

EMFLAGS_DEBUG = $(EMFLAGS_COMMON) \
	-s ASSERTIONS=1 \
	-g

EMFLAGS_DIST = $(EMFLAGS_COMMON) \
	-O3 \
	-flto \
	--closure 1

EMFLAGS_INTERFACES = \
	-s EXPORTED_FUNCTIONS=@$(EXPORTED_FUNCTIONS) \
	-s EXPORTED_RUNTIME_METHODS=@$(EXPORTED_RUNTIME_METHODS) \
	-s ENVIRONMENT="web,worker"

EMFLAGS_LIBRARIES = \
	--js-library src/libauthorizer.js \
	--js-library src/libfunction.js \
	--js-library src/libmodule.js \
	--js-library src/libprogress.js \
	--js-library src/libvfs.js

EMFLAGS_ASYNCIFY_COMMON = \
	-s ASYNCIFY \
	-s ASYNCIFY_IMPORTS=@src/asyncify_imports.json

EMFLAGS_ASYNCIFY_DEBUG = \
	$(EMFLAGS_ASYNCIFY_COMMON) \
	-s ASYNCIFY_STACK_SIZE=24576

EMFLAGS_ASYNCIFY_DIST = \
	$(EMFLAGS_ASYNCIFY_COMMON) \
	-s ASYNCIFY_STACK_SIZE=16384

# https://www.sqlite.org/compile.html
WASQLITE_DEFINES ?= \
	-DSQLITE_DEFAULT_MEMSTATUS=0 \
	-DSQLITE_DEFAULT_WAL_SYNCHRONOUS=1 \
	-DSQLITE_DQS=0 \
	-DDEFAULT_CACHE_SIZE=8000 \
	-DSQLITE_LIKE_DOESNT_MATCH_BLOBS \
	-DSQLITE_MAX_EXPR_DEPTH=0 \
	-DSQLITE_OMIT_AUTOINIT \
	-DSQLITE_OMIT_DECLTYPE \
	-DSQLITE_OMIT_DEPRECATED \
	-DSQLITE_OMIT_LOAD_EXTENSION \
	-DSQLITE_OMIT_SHARED_CACHE \
	-DSQLITE_ENABLE_BYTECODE_VTAB \
	-DSQLITE_THREADSAFE=0 \
	-DSQLITE_USE_ALLOCA \
	-DSQLITE_EXTRA_INIT=core_init \
	-DSQLITE_ENABLE_BATCH_ATOMIC_WRITE \
	-DSQLITE_ENABLE_FTS5 \
	-DCRSQLITE_WASM

WASQLITE_KS_DEFINES ?= $(WASQLITE_DEFINES) \
  -DSQLITE_ENABLE_FTS5 \
  -DSQLITE_ENABLE_RTREE \
  -DSQLITE_ENABLE_EXPLAIN_COMMENTS \
  -DSQLITE_ENABLE_UNKNOWN_SQL_FUNCTION \
  -DSQLITE_ENABLE_STMTVTAB \
  -DSQLITE_ENABLE_DBPAGE_VTAB \
  -DSQLITE_ENABLE_DBSTAT_VTAB \
  -DSQLITE_ENABLE_BYTECODE_VTAB \
  -DSQLITE_ENABLE_OFFSET_SQL_FUNC

# directories
.PHONY: all
all: dist

$(sqlite3.extra.c): $(sqlite3.c) $(dir.crsql)/core_init.c
	cat $(sqlite3.c) $(dir.crsql)/core_init.c > $@

.PHONY: crsqlite-extra
crsqlite-extra: $(sqlite3.extra.c)

.PHONY: clean
clean:
	rm -rf dist dist-xl debug tmp
	rm *.o

.PHONY: spotless
spotless:
	rm -rf dist dist-xl debug tmp deps cache

## cache
.PHONY: clean-cache
clean-cache:
	rm -rf cache

cache/$(SQLITE_AMALGAMATION).zip:
	mkdir -p cache
	curl -LsSf '$(SQLITE_AMALGAMATION_ZIP_URL)' -o $@

cache/$(EXTENSION_FUNCTIONS):
	mkdir -p cache
	curl -LsSf '$(EXTENSION_FUNCTIONS_URL)' -o $@

## deps
.PHONY: clean-deps
clean-deps:
	rm -rf deps

.PHONY: deps
deps: deps/$(SQLITE_AMALGAMATION) deps/$(EXTENSION_FUNCTIONS) $(EXPORTED_FUNCTIONS)

deps/$(SQLITE_AMALGAMATION): cache/$(SQLITE_AMALGAMATION).zip
	mkdir -p deps
	openssl dgst -sha256 -r cache/$(SQLITE_AMALGAMATION).zip | sed -e 's/ .*//' > deps/sha
	echo $(SQLITE_AMALGAMATION_ZIP_SHA) > deps/sha-expected
	cmp deps/sha deps/sha-expected
	rm -rf deps/sha deps/sha-expected $@
	unzip 'cache/$(SQLITE_AMALGAMATION).zip' -d deps/
	touch $@

deps/$(EXTENSION_FUNCTIONS): cache/$(EXTENSION_FUNCTIONS)
	mkdir -p deps
	openssl dgst -sha256 -r cache/$(EXTENSION_FUNCTIONS) | sed -e 's/ .*//' > deps/sha
	echo $(EXTENSION_FUNCTIONS_SHA) > deps/sha-expected
	cmp deps/sha deps/sha-expected
	rm -rf deps/sha deps/sha-expected $@
	cp 'cache/$(EXTENSION_FUNCTIONS)' $@

## tmp
.PHONY: clean-tmp
clean-tmp:
	rm -rf tmp

# TODO: -emit-llvm ? -flto?
# tmp/obj/debug/sqlite3-extra.o: deps/$(SQLITE_AMALGAMATION) $(sqlite3.extra.c) $(crsql-files)
# 	mkdir -p tmp/obj/debug
# 	$(EMCC) $(CFLAGS_DEBUG) $(WASQLITE_DEFINES) deps/$(SQLITE_AMALGAMATION)/sqlite3-extra.c $(crsql-files) -c

tmp/obj/debug/extension-functions.o: deps/$(EXTENSION_FUNCTIONS)
	mkdir -p tmp/obj/debug
	$(EMCC) $(CFLAGS_DEBUG) $(WASQLITE_DEFINES) $^ -c -o $@

tmp/obj/debug/libfunction.o: src/libfunction.c
	mkdir -p tmp/obj/debug
	$(EMCC) $(CFLAGS_DEBUG) $(WASQLITE_DEFINES) $^ -c -o $@

tmp/obj/debug/libauthorizer.o: src/libauthorizer.c
	mkdir -p tmp/obj/debug
	$(EMCC) $(CFLAGS_DEBUG) $(WASQLITE_DEFINES) $^ -c -o $@

tmp/obj/debug/libmodule.o: src/libmodule.c
	mkdir -p tmp/obj/debug
	$(EMCC) $(CFLAGS_DEBUG) $(WASQLITE_DEFINES) $^ -c -o $@

tmp/obj/debug/libprogress.o: src/libprogress.c
	mkdir -p tmp/obj/debug
	$(EMCC) $(CFLAGS_DEBUG) $(WASQLITE_DEFINES) $^ -c -o $@

tmp/obj/debug/libvfs.o: src/libvfs.c
	mkdir -p tmp/obj/debug
	$(EMCC) $(CFLAGS_DEBUG) $(WASQLITE_DEFINES) $^ -c -o $@

sqlite3-extra.o: deps/$(SQLITE_AMALGAMATION) $(sqlite3.extra.c) $(crsql-files)
	mkdir -p tmp/obj/dist
	$(EMCC) $(CFLAGS_DIST) $(WASQLITE_DEFINES) deps/$(SQLITE_AMALGAMATION)/sqlite3-extra.c $(crsql-files) -c

tmp/obj/dist/extension-functions.o: deps/$(EXTENSION_FUNCTIONS)
	mkdir -p tmp/obj/dist
	$(EMCC) $(CFLAGS_DIST) $(WASQLITE_DEFINES) $^ -c -o $@

tmp/obj/dist/libfunction.o: src/libfunction.c
	mkdir -p tmp/obj/dist
	$(EMCC) $(CFLAGS_DIST) $(WASQLITE_DEFINES) $^ -c -o $@

tmp/obj/dist/libauthorizer.o: src/libauthorizer.c
	mkdir -p tmp/obj/dist
	$(EMCC) $(CFLAGS_DIST) $(WASQLITE_DEFINES) $^ -c -o $@

tmp/obj/dist/libmodule.o: src/libmodule.c
	mkdir -p tmp/obj/dist
	$(EMCC) $(CFLAGS_DIST) $(WASQLITE_DEFINES) $^ -c -o $@

tmp/obj/dist/libprogress.o: src/libprogress.c
	mkdir -p tmp/obj/dist
	$(EMCC) $(CFLAGS_DIST) $(WASQLITE_DEFINES) $^ -c -o $@

tmp/obj/dist/libvfs.o: src/libvfs.c
	mkdir -p tmp/obj/dist
	$(EMCC) $(CFLAGS_DIST) $(WASQLITE_DEFINES) $^ -c -o $@

$(RS_DEBUG_BC): FORCE
	mkdir -p tmp/bc/dist
	cd $(RS_LIB_DIR); \
	RUSTFLAGS="--emit=llvm-bc -C linker=/usr/bin/true" cargo build --features static,omit_load_extension -Z build-std=panic_abort,core,alloc --target $(RS_WASM_TGT)

# See comments on debug
$(RS_RELEASE_BC): FORCE
	mkdir -p tmp/bc/dist
	cd $(RS_LIB_DIR); \
	RUSTFLAGS="--emit=llvm-bc -C linker=/usr/bin/true" cargo build --features static,omit_load_extension --release -Z build-std=panic_abort,core,alloc --target $(RS_WASM_TGT)

## debug
.PHONY: clean-debug
clean-debug:
	rm -rf debug

.PHONY: debug
debug: debug/crsqlite-sync.mjs debug/crsqlite.mjs

debug/crsqlite-sync.mjs: $(OBJ_FILES_DEBUG) $(RS_DEBUG_BC) sqlite3-extra.o $(LIBRARY_FILES) $(EXPORTED_FUNCTIONS) $(EXPORTED_RUNTIME_METHODS)
	mkdir -p debug
	$(EMCC) $(EMFLAGS_DEBUG) \
	  $(EMFLAGS_INTERFACES) \
	  $(EMFLAGS_LIBRARIES) \
		$(RS_WASM_TGT_DIR)/debug/deps/*.bc \
	  $(OBJ_FILES_DEBUG) *.o -o $@

debug/crsqlite.mjs: $(OBJ_FILES_DEBUG) $(RS_DEBUG_BC) sqlite3-extra.o $(LIBRARY_FILES) $(EXPORTED_FUNCTIONS) $(EXPORTED_RUNTIME_METHODS) $(ASYNCIFY_IMPORTS)
	mkdir -p debug
	$(EMCC) $(EMFLAGS_DEBUG) \
	  $(EMFLAGS_INTERFACES) \
	  $(EMFLAGS_LIBRARIES) \
	  $(EMFLAGS_ASYNCIFY_DEBUG) \
		$(RS_WASM_TGT_DIR)/debug/deps/*.bc \
	  $(OBJ_FILES_DEBUG) *.o -o $@

## dist
.PHONY: clean-dist
clean-dist:
	rm -rf dist

.PHONY: dist
dist: deps dist/crsqlite-sync.mjs dist/crsqlite.mjs

dist/crsqlite-sync.mjs: $(OBJ_FILES_DIST) $(RS_RELEASE_BC) sqlite3-extra.o $(LIBRARY_FILES) $(EXPORTED_FUNCTIONS) $(EXPORTED_RUNTIME_METHODS)
	mkdir -p dist
	$(EMCC) $(EMFLAGS_DIST) \
	  $(EMFLAGS_INTERFACES) \
	  $(EMFLAGS_LIBRARIES) \
		$(RS_WASM_TGT_DIR)/release/deps/*.bc \
	  $(OBJ_FILES_DIST) *.o -o $@

dist/crsqlite.mjs: $(OBJ_FILES_DIST) $(RS_RELEASE_BC) sqlite3-extra.o $(LIBRARY_FILES) $(EXPORTED_FUNCTIONS) $(EXPORTED_RUNTIME_METHODS) $(ASYNCIFY_IMPORTS)
	mkdir -p dist
	$(EMCC) $(EMFLAGS_DIST) \
	  $(EMFLAGS_INTERFACES) \
	  $(EMFLAGS_LIBRARIES) \
	  $(EMFLAGS_ASYNCIFY_DIST) \
		$(CFLAGS_DIST) \
		$(RS_WASM_TGT_DIR)/release/deps/*.bc \
	  $(OBJ_FILES_DIST) *.o -o $@

FORCE: ;

# dist-xl
.PHONY: clean-dist-xl
clean-dist-xl:
	rm -f dist-xl.zip
	rm -rf dist-xl

.PHONY: dist-xl
dist-xl: dist-xl/wa-sqlite.mjs dist-xl/wa-sqlite-async.mjs
	zip -r dist-xl dist-xl/
	
dist-xl/wa-sqlite.mjs: deps/$(SQLITE_AMALGAMATION)/sqlite3.c deps/$(EXTENSION_FUNCTIONS) src/*.c
	mkdir -p dist-xl
	$(EMCC) $(CFLAGS_DIST) $(WASQLITE_KS_DEFINES) $(EMFLAGS_DIST) \
	  $(EMFLAGS_INTERFACES) \
	  $(EMFLAGS_LIBRARIES) \
	  $^ -o $@

dist-xl/wa-sqlite-async.mjs: deps/$(SQLITE_AMALGAMATION)/sqlite3.c deps/$(EXTENSION_FUNCTIONS) src/*.c
	mkdir -p dist-xl
	$(EMCC) $(CFLAGS_DIST) $(WASQLITE_KS_DEFINES) $(EMFLAGS_DIST) \
	  $(EMFLAGS_INTERFACES) \
	  $(EMFLAGS_LIBRARIES) \
	  $(EMFLAGS_ASYNCIFY_DIST) \
	  $^ -o $@


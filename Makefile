# dependencies

SQLITE_AMALGAMATION = sqlite-amalgamation-3400000
SQLITE_AMALGAMATION_ZIP_URL = https://www.sqlite.org/2022/${SQLITE_AMALGAMATION}.zip
SQLITE_AMALGAMATION_ZIP_SHA = 7c23eb51409315738c930a222cf7cd41518ae5823c41e60a81b93a07070ef22a

EXTENSION_FUNCTIONS = extension-functions.c
EXTENSION_FUNCTIONS_URL = https://www.sqlite.org/contrib/download/extension-functions.c?get=25
EXTENSION_FUNCTIONS_SHA = 991b40fe8b2799edc215f7260b890f14a833512c9d9896aa080891330ffe4052

# source files

LIBRARY_FILES = src/libfunction.js src/libmodule.js src/libvfs.js
EXPORTED_FUNCTIONS = src/exported_functions.json
EXPORTED_RUNTIME_METHODS = src/extra_exported_runtime_methods.json
ASYNCIFY_IMPORTS = src/asyncify_imports.json

sqlite3.c := deps/$(SQLITE_AMALGAMATION)/sqlite3.c

# intermediate files
RS_WASM_TARGET = ../rs/test_runtime_ext/target/wasm32-unknown-unknown

BITCODE_FILES_DEBUG = \
	tmp/bc/debug/sqlite3.extra.bc tmp/bc/debug/extension-functions.bc \
	tmp/bc/debug/libfunction.bc \
	tmp/bc/debug/libmodule.bc \
	tmp/bc/debug/libvfs.bc

BITCODE_FILES_DIST = \
	tmp/bc/dist/sqlite3.extra.bc tmp/bc/dist/extension-functions.bc \
	tmp/bc/dist/libfunction.bc \
	tmp/bc/dist/libmodule.bc \
	tmp/bc/dist/libvfs.bc

sqlite3.extra.c := deps/$(SQLITE_AMALGAMATION)/sqlite3.extra.c

# build options

EMCC ?= emcc

CFLAGS_COMMON = \
	-I'deps/$(SQLITE_AMALGAMATION)' \
	-Wno-non-literal-null-conversion

CFLAGS_DEBUG = $(CFLAGS_COMMON) -g

CFLAGS_DIST = $(CFLAGS_COMMON) -Oz -flto

EMFLAGS_COMMON = \
	-s ALLOW_MEMORY_GROWTH=1 \
	-s WASM=1 \
	-s INVOKE_RUN

EMFLAGS_DEBUG = $(EMFLAGS_COMMON) \
	-s ASSERTIONS=1 \
	-g

EMFLAGS_DIST = $(EMFLAGS_COMMON) \
	-Oz \
	-flto \
	--closure 1

EMFLAGS_INTERFACES = \
	-s EXPORTED_FUNCTIONS=@$(EXPORTED_FUNCTIONS) \
	-s EXPORTED_RUNTIME_METHODS=@$(EXPORTED_RUNTIME_METHODS)

EMFLAGS_LIBRARIES = \
	--js-library src/libfunction.js \
	--js-library src/libmodule.js \
	--js-library src/libvfs.js

EMFLAGS_ASYNCIFY_COMMON = \
	-s ASYNCIFY \
	-s ASYNCIFY_IMPORTS=@src/asyncify_imports.json

EMFLAGS_ASYNCIFY_DEBUG = \
	$(EMFLAGS_ASYNCIFY_COMMON) \
	-s ASYNCIFY_STACK_SIZE=24576

EMFLAGS_ASYNCIFY_DIST = \
	$(EMFLAGS_ASYNCIFY_COMMON) \
	-s ASYNCIFY_STACK_SIZE=12288

# https://www.sqlite.org/compile.html
WASQLITE_DEFINES ?= \
	-DSQLITE_DEFAULT_MEMSTATUS=0 \
	-DSQLITE_DEFAULT_WAL_SYNCHRONOUS=1 \
	-DSQLITE_DQS=0 \
	-DSQLITE_LIKE_DOESNT_MATCH_BLOBS \
	-DSQLITE_MAX_EXPR_DEPTH=0 \
	-DSQLITE_OMIT_AUTOINIT \
	-DSQLITE_OMIT_DECLTYPE \
	-DSQLITE_OMIT_DEPRECATED \
	-DSQLITE_OMIT_LOAD_EXTENSION \
	-DSQLITE_OMIT_PROGRESS_CALLBACK \
	-DSQLITE_OMIT_SHARED_CACHE \
	-DSQLITE_THREADSAFE=0 \
	-DSQLITE_USE_ALLOCA \
	-DSQLITE_EXTRA_INIT=core_init \
	-DSQLITE_ENABLE_BATCH_ATOMIC_WRITE

# directories
.PHONY: all
all: dist

.PHONY: clean
clean:
	rm -rf dist debug tmp

.PHONY: spotless
spotless:
	rm -rf dist debug tmp deps cache

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
deps: deps/$(SQLITE_AMALGAMATION) deps/$(EXTENSION_FUNCTIONS) deps/$(EXPORTED_FUNCTIONS)

deps/$(SQLITE_AMALGAMATION): cache/$(SQLITE_AMALGAMATION).zip
	mkdir -p deps
	openssl dgst -sha256 -r cache/$(SQLITE_AMALGAMATION).zip | sed -e 's/ .*//' > deps/sha
	echo $(SQLITE_AMALGAMATION_ZIP_SHA) | cmp deps/sha
	rm -rf deps/sha $@
	unzip 'cache/$(SQLITE_AMALGAMATION).zip' -d deps/
	touch $@

deps/$(EXTENSION_FUNCTIONS): cache/$(EXTENSION_FUNCTIONS)
	mkdir -p deps
	openssl dgst -sha256 -r cache/$(EXTENSION_FUNCTIONS) | sed -e 's/ .*//' > deps/sha
	echo $(EXTENSION_FUNCTIONS_SHA) | cmp deps/sha
	rm -rf deps/sha $@
	cp 'cache/$(EXTENSION_FUNCTIONS)' $@

## tmp
.PHONY: clean-tmp
clean-tmp:
	rm -rf tmp

$(sqlite3.extra.c): $(sqlite3.c) src/core_init.c
	cat $(sqlite3.c) src/core_init.c > $@

tmp/bc/debug/sqlite3.extra.bc: $(sqlite3.extra.c) deps/$(SQLITE_AMALGAMATION)
	mkdir -p tmp/bc/debug
	$(EMCC) $(CFLAGS_DEBUG) $(WASQLITE_DEFINES) $(sqlite3.extra.c) -c -o $@

tmp/bc/debug/extension-functions.bc: deps/$(EXTENSION_FUNCTIONS)
	mkdir -p tmp/bc/debug
	$(EMCC) $(CFLAGS_DEBUG) $(WASQLITE_DEFINES) $^ -c -o $@

tmp/bc/debug/libfunction.bc: src/libfunction.c
	mkdir -p tmp/bc/debug
	$(EMCC) $(CFLAGS_DEBUG) $(WASQLITE_DEFINES) $^ -c -o $@

tmp/bc/debug/libmodule.bc: src/libmodule.c
	mkdir -p tmp/bc/debug
	$(EMCC) $(CFLAGS_DEBUG) $(WASQLITE_DEFINES) $^ -c -o $@

tmp/bc/debug/libvfs.bc: src/libvfs.c
	mkdir -p tmp/bc/debug
	$(EMCC) $(CFLAGS_DEBUG) $(WASQLITE_DEFINES) $^ -c -o $@

tmp/bc/dist/sqlite3.extra.bc: $(sqlite3.extra.c) deps/$(SQLITE_AMALGAMATION)
	mkdir -p tmp/bc/dist
	$(EMCC) $(CFLAGS_DIST) $(WASQLITE_DEFINES) $(sqlite3.extra.c) -c -o $@

tmp/bc/dist/extension-functions.bc: deps/$(EXTENSION_FUNCTIONS)
	mkdir -p tmp/bc/dist
	$(EMCC) $(CFLAGS_DIST) $(WASQLITE_DEFINES) $^ -c -o $@

tmp/bc/dist/libfunction.bc: src/libfunction.c
	mkdir -p tmp/bc/dist
	$(EMCC) $(CFLAGS_DIST) $(WASQLITE_DEFINES) $^ -c -o $@

tmp/bc/dist/libmodule.bc: src/libmodule.c
	mkdir -p tmp/bc/dist
	$(EMCC) $(CFLAGS_DIST) $(WASQLITE_DEFINES) $^ -c -o $@

tmp/bc/dist/libvfs.bc: src/libvfs.c
	mkdir -p tmp/bc/dist
	$(EMCC) $(CFLAGS_DIST) $(WASQLITE_DEFINES) $^ -c -o $@

$(RS_WASM_TARGET)/debug/deps/test_runtime_ext.bc: ../rs/test_runtime_ext/src/lib.rs
	cd ../rs/test_runtime_ext; \
	RUSTFLAGS="--emit=llvm-bc" cargo build -Z build-std=panic_abort,std --target wasm32-unknown-unknown

$(RS_WASM_TARGET)/release/deps/test_runtime_ext.bc: ../rs/test_runtime_ext/src/lib.rs
	cd ../rs/test_runtime_ext; \
	RUSTFLAGS="--emit=llvm-bc" cargo build --release -Z build-std=panic_abort,std --target wasm32-unknown-unknown

## debug
.PHONY: clean-debug
clean-debug:
	rm -rf debug

.PHONY: debug
debug: debug/wa-sqlite.mjs debug/wa-sqlite-async.mjs

debug/wa-sqlite.mjs: $(BITCODE_FILES_DEBUG) $(RS_WASM_TARGET)/debug/deps/test_runtime_ext.bc $(LIBRARY_FILES) $(EXPORTED_FUNCTIONS) $(EXPORTED_RUNTIME_METHODS)
	mkdir -p debug
	rm -f $(RS_WASM_TARGET)/debug/deps/panic_unwind*
	$(EMCC) $(EMFLAGS_DEBUG) \
	  $(EMFLAGS_INTERFACES) \
	  $(EMFLAGS_LIBRARIES) \
		$(RS_WASM_TARGET)/debug/deps/*.bc \
	  $(BITCODE_FILES_DEBUG) -o $@

debug/wa-sqlite-async.mjs: $(BITCODE_FILES_DEBUG) $(RS_WASM_TARGET)/debug/deps/test_runtime_ext.bc $(LIBRARY_FILES) $(EXPORTED_FUNCTIONS) $(EXPORTED_RUNTIME_METHODS) $(ASYNCIFY_IMPORTS)
	mkdir -p debug
	rm -f $(RS_WASM_TARGET)/debug/deps/panic_unwind*
	$(EMCC) $(EMFLAGS_DEBUG) \
	  $(EMFLAGS_INTERFACES) \
	  $(EMFLAGS_LIBRARIES) \
	  $(EMFLAGS_ASYNCIFY_DEBUG) \
		$(RS_WASM_TARGET)/debug/deps/*.bc \
	  $(BITCODE_FILES_DEBUG) -o $@

## dist
.PHONY: clean-dist
clean-dist:
	rm -rf dist

.PHONY: dist
dist: dist/wa-sqlite.mjs dist/wa-sqlite-async.mjs

dist/wa-sqlite.mjs: $(BITCODE_FILES_DIST) $(RS_WASM_TARGET)/release/deps/test_runtime_ext.bc $(LIBRARY_FILES) $(EXPORTED_FUNCTIONS) $(EXPORTED_RUNTIME_METHODS)
	mkdir -p dist
	rm -f $(RS_WASM_TARGET)/release/deps/panic_unwind*
	$(EMCC) $(EMFLAGS_DIST) \
	  $(EMFLAGS_INTERFACES) \
	  $(EMFLAGS_LIBRARIES) \
		$(RS_WASM_TARGET)/release/deps/*.bc \
	  $(BITCODE_FILES_DIST) -o $@

dist/wa-sqlite-async.mjs: $(BITCODE_FILES_DIST) $(RS_WASM_TARGET)/release/deps/test_runtime_ext.bc $(LIBRARY_FILES) $(EXPORTED_FUNCTIONS) $(EXPORTED_RUNTIME_METHODS) $(ASYNCIFY_IMPORTS)
	mkdir -p dist
	rm -f $(RS_WASM_TARGET)/release/deps/panic_unwind*
	$(EMCC) $(EMFLAGS_DIST) \
	  $(EMFLAGS_INTERFACES) \
	  $(EMFLAGS_LIBRARIES) \
	  $(EMFLAGS_ASYNCIFY_DIST) \
		$(RS_WASM_TARGET)/release/deps/*.bc \
	  $(BITCODE_FILES_DIST) -o $@

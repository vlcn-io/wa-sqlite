# @vlcn.io/wa-sqlite

## 0.14.1

### Patch Changes

- 519bcfc2a: hooks, fixes to support examples, auto-determine tables queried
- hooks package, used_tables query, web only target for wa-sqlite

## 0.14.1-next.0

### Patch Changes

- hooks, fixes to support examples, auto-determine tables queried

## 0.14.0

### Minor Changes

- seen peers, binary encoding for network layer, retry on disconnect for server, auto-track peers

## 0.13.3

### Patch Changes

- deploy table validation fix

## 0.13.2

### Patch Changes

- cid winner selection bugfix

## 0.13.1

### Patch Changes

- rebuild all

## 0.13.0

### Minor Changes

- breaking change -- fix version recording problem that prevented convergence in p2p cases

## 0.12.2

### Patch Changes

- fix gh #108

## 0.12.1

### Patch Changes

- fix mem leak and cid win value selection bug

## 0.12.0

### Minor Changes

- fix tie breaking for merge, add example client-server sync

## 0.11.2

### Patch Changes

- fix bigint overflow in wasm, fix site_id not being returned with changesets

## 0.11.1

### Patch Changes

- fix memory leak when applying changesets

## 0.11.0

### Minor Changes

- fix multi-way merge

## 0.10.0

### Minor Changes

- incorporate schema fitness checks

## 0.9.0

### Minor Changes

- update to use `wa-sqlite`, fix site id forwarding, fix scientific notation replication, etc.

## 0.8.9

### Patch Changes

- fix linking issues on linux distros

## 0.8.8

### Patch Changes

- fixes site id not being passed during replication

## 0.8.7

### Patch Changes

- fix statement preparation error in cases where there are multiple concurrent db connections

## 0.8.6

### Patch Changes

- update sqlite binaries

## 0.8.5

### Patch Changes

- debug logging, fatal on bad binds

## 0.8.4

### Patch Changes

- remove `link:../` references so we actually correctly resolve packages

# Playback Refactor: ViMusic-Style Architecture

## Goal
Replace current streaming/caching with ViMusic-style architecture:
- Songs stream in real-time, cached transparently as bytes flow through
- Fully cached songs play instantly from disk
- Player never sees errors — proxy handles URL resolution, 403 refresh, retries
- Skip/seek work instantly with no corruption

---

## How ViMusic Works

### Architecture
ExoPlayer's `CacheDataSource` — single data pipeline:
1. Check disk cache (`SimpleCache`) for requested bytes
2. Cached → read from disk (instant)
3. Not cached → fetch from HTTP, write to cache as bytes flow to player
4. Single connection, no duplication

### Key Components
- **`SimpleCache`** — LRU chunk-based disk cache (512KB chunks), keyed by video ID
- **`CacheDataSource`** — Reads cache if available, fetches upstream + writes to cache if not
- **`ResolvingDataSource`** — Lazily resolves video ID → stream URL only when bytes needed
- **`UriCache`** — In-memory URL cache (24h TTL), avoids re-resolving
- **`RetryingDataSourceFactory`** — Retries transient errors with exponential backoff
- **`CatchingDataSourceFactory`** — Catches 403/404 → triggers URL refresh
- **`RangeHandlerDataSourceFactory`** — Handles HTTP 416 by retrying without Range header
- **`PrecacheService`** — Background downloads via ExoPlayer's DownloadManager

### ViMusic Flow
```
1. Player needs bytes at position X
2. Cached? → read from disk
3. URL in memory cache? → use it. Otherwise → resolve via Innertube API
4. Fetch from YouTube, write chunks to cache as they flow through
5. 403? → clear URL cache, re-resolve, retry
6. Transient error? → retry with backoff
```

---

## Current Architecture (Sangeet) & Problems

### Current Flow
```
1. prefetchStream() → resolve URL eagerly (adds latency)
2. Player.open("http://127.0.0.1:8085/stream/{videoId}")
3. Proxy: check disk cache → serve file OR fetch from YouTube + pipe-through cache
4. Separately: prefetchAndCacheTrack() downloads next 3 tracks
```

### Problems
1. **Pipe-through cache fails on skip/seek** — .part discarded, never cached
2. **Whole-file caching** — either 100% cached or 0%, no partial
3. **Separate prefetch competes** — two HTTP connections to same URL
4. **Eager URL resolution** — resolves before player needs it
5. **Error handling scattered** — some in proxy, some in player

---

## Implementation Plan

### Constraint
- Flutter uses `media_kit` (libmpv), not ExoPlayer — cannot use CacheDataSource directly
- `media_kit` only accepts URLs/file paths — **must keep HTTP proxy**
- Proxy becomes our "DataSource pipeline"
- **No UI changes**

---

### Phase 1: Chunk-Based Cache

Replace `_AudioDiskCache` (whole-file) with `_ChunkCache` (512KB chunks).

**Changes in `streaming_server.dart`**:
- New `_ChunkCache` class: stores `{videoId}_{chunkIndex}` files
- Methods: `hasChunk()`, `readChunk()`, `writeChunk()`, `hasAllChunks()`
- LRU eviction at video level
- Rewrite `_handleStreamRequest`: serve cached chunks from disk, fetch missing from upstream, write chunks as they flow through
- Remove: `_AudioDiskCache`, `cacheFromStream`, pipe-through `StreamTransformer`

---

### Phase 2: Lazy URL Resolution

Resolve URLs only when proxy needs bytes (not eagerly before play).

**Changes in `streaming_server.dart`**:
- Replace `_streamCache`/`_CachedStream` with `_UriCache` (videoId → url+userAgent+contentLength, 6h TTL)
- URL resolution happens inside `_handleStreamRequest` only when needed
- Remove `prefetchStream()` as a separate pre-play step

**Changes in `audio_player_service.dart`**:
- Remove `prefetchStream` call from `_attemptPlayback`
- Just call `player.open(proxyUrl)` directly — proxy resolves lazily

---

### Phase 3: Layered Error Handling in Proxy

All errors handled in proxy. Player never sees them.

**Changes in `streaming_server.dart`**:
- **403**: clear URI cache, re-resolve, retry (up to 2x with different clients)
- **Transient (timeout, 5xx)**: retry with backoff (1s, 2s, 4s), max 3 retries
- **416**: retry without Range header

**Changes in `audio_player_service.dart`**:
- Remove `retryCount`/retry loop from `_playCurrentTrack`
- If proxy returns error → truly unplayable → skip
- Keep spurious completion guard

---

### Phase 4: Prefetch via Chunk Cache

**Changes in `streaming_server.dart`**:
- Rewrite `prefetchAndCacheTrack`: GET through proxy (triggers chunk caching naturally)
- Add prefetch cancellation by videoId
- Low-priority downloads that don't compete with playback

**Changes in `audio_player_service.dart`**:
- Keep prefetch-next-3 logic, just calls rewritten method

---

### Phase 5: Cleanup

**Remove from `streaming_server.dart`**:
- `_CachedStream`, `_AudioDiskCache`, `_backgroundCacheDownload`, `_teeCacheToPartFile`
- Unused fields: `_chunkSize`, `_innertube`, `_tryInnertubeClient`
- Unused imports: `dart:convert`, `shared_preferences`

**Remove from `audio_player_service.dart`**:
- Retry logic, prefetch-before-play step, buffering timeout logic

---

## File Change Summary

| File | Changes |
|---|---|
| `streaming_server.dart` | Major rewrite: chunk cache, lazy URL resolution, layered error handling |
| `audio_player_service.dart` | Simplify: remove retries, remove prefetch-before-play |
| No UI files | No changes |

## Implementation Order
1. Phase 1 → Chunk cache (biggest impact)
2. Phase 2 → Lazy URL resolution (removes latency)
3. Phase 3 → Error handling cleanup
4. Phase 4 → Prefetch rewrite
5. Phase 5 → Dead code cleanup

Each phase tested independently before moving to next.

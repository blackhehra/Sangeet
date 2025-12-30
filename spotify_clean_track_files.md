# Spotify Clean Track Files Database Documentation

## Overview

This database contains Spotify track metadata from the **Anna's Archive Spotify 2025-07 Metadata** collection.

### File Information

- **File**: `spotify_clean_track_files.sqlite3`
- **Size**: 98.53 GB
- **Tables**: 1

## Tables

- [track_files](#track_files)

---

## track_files

### Schema
```sql
CREATE TABLE "track_files" (
	`rowid` integer PRIMARY KEY NOT NULL,
	`track_id` text NOT NULL,
	`filename` text,
	`reencoded_kbit_vbr` integer,
	`fetched_at` integer,
	`session_country` text,
	`sha256_original` text,
	`sha256_with_embedded_meta` text,
	`status` text NOT NULL,
	`isrc_has_download` integer,
	`track_popularity` integer,
	`secondary_priority` real,
	`prefixed_ogg_packet` blob,
	`alternatives` text,
	`file_id_ogg_vorbis_96` text,
	`file_id_ogg_vorbis_160` text,
	`file_id_ogg_vorbis_320` text,
	`file_id_aac_24` text,
	`language_of_performance` text,
	`artist_roles` text,
	`has_lyrics` integer,
	`licensor` text,
	`original_title` text,
	`version_title` text
, `file_id_mp3_96` text, `content_ratings` text, `filesize_bytes` integer)
```

### Columns

| # | Column | Type | Nullable | Default | PK |
|---|--------|------|----------|---------|-----|
| 0 | `rowid` | INTEGER | No | - | ✓ |
| 1 | `track_id` | TEXT | No | - |  |
| 2 | `filename` | TEXT | Yes | - |  |
| 3 | `reencoded_kbit_vbr` | INTEGER | Yes | - |  |
| 4 | `fetched_at` | INTEGER | Yes | - |  |
| 5 | `session_country` | TEXT | Yes | - |  |
| 6 | `sha256_original` | TEXT | Yes | - |  |
| 7 | `sha256_with_embedded_meta` | TEXT | Yes | - |  |
| 8 | `status` | TEXT | No | - |  |
| 9 | `isrc_has_download` | INTEGER | Yes | - |  |
| 10 | `track_popularity` | INTEGER | Yes | - |  |
| 11 | `secondary_priority` | REAL | Yes | - |  |
| 12 | `prefixed_ogg_packet` | BLOB | Yes | - |  |
| 13 | `alternatives` | TEXT | Yes | - |  |
| 14 | `file_id_ogg_vorbis_96` | TEXT | Yes | - |  |
| 15 | `file_id_ogg_vorbis_160` | TEXT | Yes | - |  |
| 16 | `file_id_ogg_vorbis_320` | TEXT | Yes | - |  |
| 17 | `file_id_aac_24` | TEXT | Yes | - |  |
| 18 | `language_of_performance` | TEXT | Yes | - |  |
| 19 | `artist_roles` | TEXT | Yes | - |  |
| 20 | `has_lyrics` | INTEGER | Yes | - |  |
| 21 | `licensor` | TEXT | Yes | - |  |
| 22 | `original_title` | TEXT | Yes | - |  |
| 23 | `version_title` | TEXT | Yes | - |  |
| 24 | `file_id_mp3_96` | TEXT | Yes | - |  |
| 25 | `content_ratings` | TEXT | Yes | - |  |
| 26 | `filesize_bytes` | INTEGER | Yes | - |  |

### Indexes

- `clean_track_files_track_id_unique`
  ```sql
  CREATE UNIQUE INDEX `clean_track_files_track_id_unique` ON "track_files" (`track_id`)
  ```
- `track_files_todo`
  ```sql
  CREATE INDEX track_files_todo on track_files(track_id) where status = 'todo_unk'
  ```
- `track_files_filesize`
  ```sql
  CREATE INDEX track_files_filesize on track_files(filesize_bytes)
  ```
- `track_files_filesize_todo2`
  ```sql
  CREATE INDEX track_files_filesize_todo2 on track_files(track_popularity, filename) where filename is not null and filesize_bytes is null
  ```

### Statistics

- **Estimated Rows**: ~256,805,972

### Sample Data

| rowid | track_id | filename | reencoded_kbit_vbr | fetched_at | session_country | sha256_original | sha256_with_embedded_meta | status | isrc_has_download | track_popularity | secondary_priority | prefixed_ogg_packet | alternatives | file_id_ogg_vorbis_96 | file_id_ogg_vorbis_160 | file_id_ogg_vorbis_320 | file_id_aac_24 | language_of_performance | artist_roles | has_lyrics | licensor | original_title | version_title | file_id_mp3_96 | content_ratings | filesize_bytes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1892 | 003vvx7Niy0yvhvHt4a68B | track-popularity-50-to-100/T/TH/The Killers/2004 Hot Fuss (4... | NULL | 1741824000000 | UNK | f4b083875794e0583cc686ab478b37f17eb5c392481b933d02a75763f9cc... | f0ea763215eb83875dc84d00b7ea4357b561c0117af656987bc69e2a8c47... | success | NULL | 88 | NULL | b'OggS\x00\x06\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x... | NULL | e02d12f5e3540f96dc39e4de8baadeab0ab1dde7 | d2ea54df9f2a62d53f2269ba0fee54875070ecbc | 9ecc88fdbe8ae750528aaebcbf7ec9c219145402 | 3b6a4b4cf9f91dd5e21621ab185133b429d7b139 | ["en"] | NULL | NULL | NULL | NULL | NULL | NULL | NULL | 4258118 |
| 6955 | 00E0Z2jrF7reoHps4zcbWQ | track-popularity-50-to-100/A/AL/Alok/2023 Car Keys (Ayla) (1... | NULL | 1741824000000 | UNK | eacb46fecfd3e8f3c34a7cd2fc1e072f5a07f8ced33ccafd52777a2f8f4a... | 24bdc38cb51745c0cc08bb22220f94425c8041d0ea71fcfa65c649583fb0... | success | NULL | 71 | NULL | b'OggS\x00\x06\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x... | NULL | 6b811209ea1d1a5006b3845ca83850bc1ef72a78 | 6cf617e1df9db843c8dda75e501934706f63088a | b924f439dfe5959a9e9775ff8283ef69ec1e0fca | 2bf0f011867c454e1cf6e7262c99bca1b8279767 | ["en"] | NULL | NULL | NULL | NULL | NULL | NULL | NULL | 3122766 |
| 7185 | 00GvqqIkMdHaxChyhZf9Nx | track-popularity-50-to-100/M/MA/Matroda/2024 4U (5p6wULtzOrj... | NULL | 1741824000000 | UNK | e122d01a0dcc2fe725fc80b3bd475a66002eff0377838fbe736de8dd0115... | fccd174945a70da362b39e062888e5ce3d10de6bea43a4a1bcfa5b4c47ad... | success | NULL | 63 | NULL | b'OggS\x00\x06\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x... | NULL | 92d1a2e0f598de67cb9a39025fc7ced6633cffa0 | 6d958060f849338883fcf1c0a6f4d81c00993c9a | 42164b3518270ff2f8572a03343df88ec344870c | dc2a1bfc9715e12af8fb9c268fdd2f8a262ed2af | ["zxx"] | NULL | NULL | NULL | NULL | NULL | NULL | NULL | 3465717 |
| 12733 | 003FTlCpBTM4eSqYSWPv4H | track-popularity-50-to-100/T/TH/The All-American Rejects/200... | NULL | 1741824000000 | UNK | 57c8314515bc72b7d10365729fc9ce8bf7c2e3c5176ee382d6f9da698f42... | 6b5fcc82d84f85851ecc60ab4784f29d0d6b5431dd9080df97c74fc08b74... | success | NULL | 68 | NULL | b"OggS\x00\x06\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x... | NULL | 4c51cb1220d892c94d61b72c69e21e34e9806eae | 691406af81c03022fd245be98f4c91de15269948 | 64b1bad3adb0ef2847c55b9427a8ef1f146d5c50 | a7d681a75a47990236f695ab00ef65ce07e47b6e | ["en"] | NULL | NULL | NULL | NULL | NULL | NULL | NULL | 4668038 |
| 20188 | 00AitwJWRhIH5IuNLGYLVD | track-popularity-28/C/CL/Clay Western/2024 When You Call (3R... | NULL | 1741824000000 | UNK | 1672a29c2ff3ef43cb2dd005692f435e87fb54920a4c6e8dbc712d1d3cd6... | 3cb0505192c99203abd305e84b5c7d6804ed4bf8069a5d270d09d05a72ac... | success | NULL | 28 | NULL | b'OggS\x00\x06\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x... | NULL | ffd33b4e2a25aedd930e3f2a9c1b477769d7fbe4 | bac449a2060daf7f5ebe7d26f5d3f034469a1d81 | 1dd6a63b68b219ffde2c1da3ed912bfb15ac33d9 | 598a43e6fbd3cbb42721179bc27c554680f40aba | ["en"] | NULL | NULL | NULL | NULL | NULL | NULL | NULL | 3466554 |

# Spotify Clean Playlists Database Documentation

## Overview

- **Source File**: `S:\qbtorrent\annas_archive_spotify_2025_07_metadata\spotify_clean_playlists.sqlite3`
- **File Size**: 115.88 GB
- **Total Tables**: 3

## Tables

- [playlist_images](#playlist_images)
- [playlist_tracks](#playlist_tracks)
- [playlists](#playlists)

---

### playlist_images

#### Schema
```sql
CREATE TABLE `playlist_images` (
	`playlist_rowid` integer NOT NULL,
	`width` integer,
	`height` integer,
	`url` text NOT NULL,
	FOREIGN KEY (`playlist_rowid`) REFERENCES "playlists"(`rowid`) ON UPDATE no action ON DELETE no action
)
```

#### Columns
| # | Name | Type | Not Null | Default | Primary Key |
|---|------|------|----------|---------|-------------|
| 0 | playlist_rowid | INTEGER | True | None | False |
| 1 | width | INTEGER | False | None | False |
| 2 | height | INTEGER | False | None | False |
| 3 | url | TEXT | True | None | False |

#### Statistics
- **Row Count**: 11,326,423

#### Indexes
- **playlist_images_playlist_id**
  ```sql
  CREATE INDEX `playlist_images_playlist_id` ON `playlist_images` (`playlist_rowid`)
  ```

#### Sample Data (First 5 Rows)
| playlist_rowid | width | height | url |
| --- | --- | --- | --- |
| 1 | NULL | NULL | https://daylist.spotifycdn.com/playlist-covers-mix... |
| 2 | NULL | NULL | https://daily-mix.scdn.co/covers/your-daily-podcas... |
| 3 | NULL | NULL | https://i.scdn.co/image/ab67706f00000002c782f5168b... |
| 4 | NULL | NULL | https://i.scdn.co/image/ab67706f00000002a81b5b4d68... |
| 5 | NULL | NULL | https://i.scdn.co/image/ab67706f000000021639825432... |

---

### playlist_tracks

#### Schema
```sql
CREATE TABLE "playlist_tracks" (
	`playlist_rowid` integer NOT NULL,
	`position` integer NOT NULL,
	`is_episode` integer NOT NULL,
	`track_rowid` integer,
	`id_if_not_in_tracks_table` text,
	`added_at` integer NOT NULL,
	`added_by_id` text,
	`primary_color` text,
	`video_thumbnail_url` text,
	`is_local` integer NOT NULL,
	`name_if_is_local` text,
	`uri_if_is_local` text,
	`album_name_if_is_local` text,
	`artists_name_if_is_local` text,
	`duration_ms_if_is_local` integer,
	PRIMARY KEY(`playlist_rowid`, `position`),
	FOREIGN KEY (`playlist_rowid`) REFERENCES "playlists"(`rowid`) ON UPDATE no action ON DELETE no action
)
```

#### Columns
| # | Name | Type | Not Null | Default | Primary Key |
|---|------|------|----------|---------|-------------|
| 0 | playlist_rowid | INTEGER | True | None | True |
| 1 | position | INTEGER | True | None | True |
| 2 | is_episode | INTEGER | True | None | False |
| 3 | track_rowid | INTEGER | False | None | False |
| 4 | id_if_not_in_tracks_table | TEXT | False | None | False |
| 5 | added_at | INTEGER | True | None | False |
| 6 | added_by_id | TEXT | False | None | False |
| 7 | primary_color | TEXT | False | None | False |
| 8 | video_thumbnail_url | TEXT | False | None | False |
| 9 | is_local | INTEGER | True | None | False |
| 10 | name_if_is_local | TEXT | False | None | False |
| 11 | uri_if_is_local | TEXT | False | None | False |
| 12 | album_name_if_is_local | TEXT | False | None | False |
| 13 | artists_name_if_is_local | TEXT | False | None | False |
| 14 | duration_ms_if_is_local | INTEGER | False | None | False |

#### Statistics
- **Row Count**: 1,698,443,099

#### Sample Data (First 5 Rows)
| playlist_rowid | position | is_episode | track_rowid | id_if_not_in_tracks_table | added_at | added_by_id | primary_color | video_thumbnail_url | is_local | name_if_is_local | uri_if_is_local | album_name_if_is_local | artists_name_if_is_local | duration_ms_if_is_local |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 2 | 0 | 1 | NULL | 5SeY2D5YVJ1I4hmzGOtVsk | 0 |  | NULL | NULL | 0 | NULL | NULL | NULL | NULL | NULL |
| 2 | 1 | 0 | NULL | NULL | 0 |  | NULL | NULL | 0 | NULL | NULL | NULL | NULL | NULL |
| 2 | 2 | 1 | NULL | 3cCPgGLmgJqp8k3uQvUfD7 | 0 |  | NULL | NULL | 0 | NULL | NULL | NULL | NULL | NULL |
| 2 | 3 | 1 | NULL | 2zT28jtBbq3k9h5vGEAm6M | 0 |  | NULL | NULL | 0 | NULL | NULL | NULL | NULL | NULL |
| 2 | 4 | 1 | NULL | 5nVUSVNCbzYYLXIZ40dNci | 0 |  | NULL | NULL | 0 | NULL | NULL | NULL | NULL | NULL |

---

### playlists

#### Schema
```sql
CREATE TABLE "playlists" (
	`rowid` integer PRIMARY KEY NOT NULL,
	`id` text NOT NULL,
	`snapshot_id` text NOT NULL,
	`fetched_at` integer NOT NULL,
	`name` text NOT NULL,
	`description` text,
	`collaborative` integer NOT NULL,
	`public` integer NOT NULL,
	`primary_color` text,
	`owner_id` text,
	`owner_display_name` text,
	`followers_total` integer,
	`tracks_total` integer NOT NULL
)
```

#### Columns
| # | Name | Type | Not Null | Default | Primary Key |
|---|------|------|----------|---------|-------------|
| 0 | rowid | INTEGER | True | None | True |
| 1 | id | TEXT | True | None | False |
| 2 | snapshot_id | TEXT | True | None | False |
| 3 | fetched_at | INTEGER | True | None | False |
| 4 | name | TEXT | True | None | False |
| 5 | description | TEXT | False | None | False |
| 6 | collaborative | INTEGER | True | None | False |
| 7 | public | INTEGER | True | None | False |
| 8 | primary_color | TEXT | False | None | False |
| 9 | owner_id | TEXT | False | None | False |
| 10 | owner_display_name | TEXT | False | None | False |
| 11 | followers_total | INTEGER | False | None | False |
| 12 | tracks_total | INTEGER | True | None | False |

#### Statistics
- **Row Count**: 6,608,769

#### Indexes
- **playlists_id_unique**
  ```sql
  CREATE UNIQUE INDEX `playlists_id_unique` ON "playlists" (`id`)
  ```
- **playlists_followers**
  ```sql
  CREATE INDEX `playlists_followers` ON "playlists" (`followers_total`)
  ```
- **playlists_owner_id**
  ```sql
  CREATE INDEX playlists_owner_id on playlists(owner_id)
  ```

#### Sample Data (First 5 Rows)
| rowid | id | snapshot_id | fetched_at | name | description | collaborative | public | primary_color | owner_id | owner_display_name | followers_total | tracks_total |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 37i9dQZF1EP6YuccBxUcC1 | AAAAAAAAAABuYPO2herY5rqaUQGREzFC | 1741824000000 | daylist | Your day in a playlist. | 0 | 1 | #ffffff | spotify | Spotify | 0 | 0 |
| 2 | 37i9dQZF1EnOBYmteT8p3O | AAAAAAAAAAAhp7blsYnA3e5uTteKpTdV | 1741824000000 | Daily Podcasts | Podcast episodes picked just for you | 0 | 1 | #FFFFFF | spotify | Spotify | 277840 | 11 |
| 3 | 37i9dQZF1DXcecv7ESbOPu | Z9RFUQAAAAAKqIKpDo7XUz37lI5PNCmA | 1741824000000 | New Music Friday Sweden | Äntligen fredag och ny musik från Chappell Roan, H... | 0 | 1 | #A0C3D2 | spotify | Spotify | 220102 | 104 |
| 4 | 37i9dQZF1DX3WvGXE8FqYX | Z8YrfAAAAAA5Mj8T6iA1UaVdXpVep4sn | 1741824000000 | Women of Pop | Celebrating the power of amazing female pop artist... | 0 | 1 | #ffffff | spotify | Spotify | 2592601 | 75 |
| 5 | 37i9dQZF1DXc7FZ2VBjaeT | Z8y/QAAAAADh7aySbrlanbnlMPfJnbau | 1741824000000 | This Is Lady Gaga | Listen to all her biggest hits, in one place. | 0 | 1 | #ffffff | spotify | Spotify | 1784210 | 50 |

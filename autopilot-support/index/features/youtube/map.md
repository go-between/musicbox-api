# YouTube Integration — Map

## Client

- `app/lib/youtube_client.rb` — `YoutubeClient`. Thin wrapper over YouTube Data API v3 (`videos` and `search` endpoints) using raw `Net::HTTP`. Reads `ENV["YOUTUBE_KEY"]`. Two public methods: `find(youtube_id)` (hydration for `SongCreate`) and `search(query)` (search-before-add UX). Accepts a `user` in the constructor but never uses it — kept for future per-user quota/auth.

## GraphQL surface

- `app/graphql/types/youtube_result_type.rb` — `Types::YoutubeResult`. Projects a `YoutubeClient#search` result (`id`, `name`, `description`, `thumbnail_url`) for the client's search-before-add UI. All fields are non-null even though `YoutubeClient#search` populates them from optional API fields — empty strings will pass, missing keys will raise. Returned as one of the `Types::SearchResultType` union members (see `features/search/`).

## Schema

- `db/migrate/20190319122943_add_youtube_id_to_songs.rb` — Adds `songs.youtube_id` (string). The string-typed external key used everywhere as the song's identity.
- `db/migrate/20200415022511_add_youtube_details_to_songs.rb` — Adds `songs.thumbnail_url`, `license`, `licensed` (default `false`), `youtube_tags` (string array, default `[]`). These are the YouTube-sourced columns hydrated by `SongCreate` via `YoutubeClient#find`; they live on `Song` (see `features/songs/`).

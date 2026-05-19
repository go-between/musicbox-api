# YouTube Integration — Boundaries

What this feature owns, where it ends, and what not to build inside it.

## What this feature owns

- `app/lib/youtube_client.rb` — the only HTTP integration with the YouTube Data API.
- `app/graphql/types/youtube_result_type.rb` — the GraphQL projection of a search result.
- The schema-level YouTube columns added by `db/migrate/20190319122943_add_youtube_id_to_songs.rb` and `db/migrate/20200415022511_add_youtube_details_to_songs.rb`. Those columns physically live on `songs` (owned by `features/songs/`), but the *shape* — what gets pulled from YouTube, what the names are — is owned here.
- The `ENV["YOUTUBE_KEY"]` contract (see `.env.template`).

## Where this feature ends

- **Song persistence and identity** — `Song` model, `youtube_id` as primary external key, `Mutations::SongCreate`, and the hydration call site (`attrs_from_youtube!`) all belong to `features/songs/`. This feature provides `YoutubeClient#find` and the shape of its return value; it does not own how those fields land in the database.
- **Search UI integration** — `Selectors::SearchResults#from_youtube`, `Types::SearchResultType` (the union), the `search` query field, and the local-first/YouTube-fallback policy live in `features/search/`. This feature owns `YoutubeClient#search` and `Types::YoutubeResult`; it does not own where they get composed into the search response.
- **Recommendations** — `Mutations::RecommendationCreate` takes a `youtube_id` argument and looks up `Song.find_by(youtube_id:)`, but never instantiates `YoutubeClient`. Recommendation flows belong to `features/recommendations/`.
- **Library and listening history** — Anything keyed on a `Song` after it exists (LibraryRecord, RecordListen, tagging) is downstream of this feature.

## Extension points

- **New YouTube endpoints** — Add a method to `YoutubeClient` (e.g., `playlist_items`, `channel`, `comments`). Mirror the existing pattern: build the params hash with `key: ENV["YOUTUBE_KEY"]`, call `get`, and shape the response into an `OpenStruct` or array of `OpenStruct`s. Pick a return-shape convention up front — see Patterns on how `find` and `search` deliberately diverge.
- **Alternative providers (SoundCloud, Spotify, Bandcamp)** — Add a sibling class in `app/lib/` (e.g., `SoundcloudClient`) with the same constructor shape (`initialize(user)`). Do not add provider branching inside `YoutubeClient`. The Song model is currently single-provider (`youtube_id` is the identity); a multi-provider Song requires schema work in `features/songs/` first.
- **Per-user quota or OAuth-tokened access** — The unused `@user` field on `YoutubeClient` is the hook. Add reads of `@user.youtube_access_token` (or similar) inside `find`/`search`. Today every caller already passes `current_user`, so the call sites do not need to change.
- **Real error handling** — Wrap the body of `YoutubeClient#get` (or add a higher-level rescue around `find`/`search`) to call `Airbrake.notify` on non-success. Coordinate with the call sites: `SongCreate` currently has no fallback for `find` returning `nil`, and adding one belongs there, not here.
- **A `videoId → metadata` cache** — Caller's concern. See "Do not build here" below.

## Do not build here

- **Calling YouTube from controllers, mutations, channels, or workers directly.** Every YouTube call must go through `YoutubeClient`. Today there are exactly two call sites (`Mutations::SongCreate` and `Selectors::SearchResults`). Adding a third should still instantiate `YoutubeClient.new(current_user)` — do not inline `Net::HTTP`, do not use `URI.open`, and do not pull in a Google SDK.
- **Caching at this layer.** No `Rails.cache.fetch`, no memoization across instances, no ETag handling. If `Mutations::SongCreate` were called twice in quick succession, that is the caller's problem to solve (and `Song.find_or_initialize_by(youtube_id:)` already solves it at the persistence layer). For `search`, the caller (`SearchResults`) is the right place to decide on caching since it also owns the local-first policy.
- **Per-request rate limiting or quota tracking.** YouTube enforces it server-side; the client surfaces failures as `nil`/`[]`. Quota awareness belongs in operational dashboards, not in this code path.
- **Adding `Airbrake.notify` inline in `YoutubeClient#get`** without also fixing `SongCreate#attrs_from_youtube!`. Notifying and then letting `SongCreate` raise a `NoMethodError` on `video.description` is worse than the current behavior — coordinate the two changes.
- **A "refresh YouTube metadata" job.** Song hydration is intentionally single-shot at create time (see `features/songs/patterns.md`). If product wants drift correction, design it as a feature with its own boundaries, not as a bolt-on to `YoutubeClient`.
- **Reusing `Types::YoutubeResult` for non-search payloads.** Its four-field shape exists to mirror `YoutubeClient#search` output. Use a new type for any other YouTube projection, or surface `Song` fields directly via `Types::SongType`.
- **A separate `YoutubeSearchType`, `YoutubeVideoType`, etc.** Today's surface is one search type. Resist proliferation — adding fields to `YoutubeResult` is cheaper than adding sibling types.

## Schema invariants

- `songs.youtube_id` is a `string`, indexed but **not** uniquely constrained (`db/migrate/20190322030217_add_index_to_songs.rb`). Uniqueness is enforced at the application layer via `find_or_initialize_by` — see `features/songs/`. New tables referencing a video by YouTube ID should use `string`, not foreign-key to `songs.id`, if they want to represent unknown-yet videos.
- `songs.youtube_tags` is `string[]` with `default: []`. Treat empty array and `nil` differently only if you have a reason to — `YoutubeClient#find` will write whatever the API returned (which may be a `nil` if `:tags` is absent on the snippet).

## Test boundary

- No dedicated spec for `YoutubeClient` itself — it has no test coverage. The two callers stub it (`spec/mutations/song_create_spec.rb`, indirectly `spec/queries/search_spec.rb`), so behavior changes to `YoutubeClient` will not be caught by CI. If you change response shape, grep for `YoutubeClient` and update every stub.

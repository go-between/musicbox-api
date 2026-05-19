# Testing

RSpec-based test suite under `spec/`, mirroring the GraphQL-first architecture rather than the Rails MVC layout. Most tests are request specs that POST to the single `/api/v1/graphql` endpoint; there are no controller specs, no system/feature specs, and no view specs.

## Helper setup

- `spec/rails_helper.rb` is the heavyweight entry point — sets `RAILS_ENV=test`, requires `rspec/rails` and `sidekiq/testing`, then auto-requires every file under `spec/support/**/*.rb`. Includes `FactoryBot::Syntax::Methods` globally so `create(:foo)` works without prefixing `FactoryBot.`.
- `spec/spec_helper.rb` is lightweight — only requires `webmock/rspec` (so every spec has outbound HTTP blocked by default) and defines a `:not_change` negated matcher (used in mutation specs to combine multiple `not_change(...)` expectations with `and`).
- DatabaseCleaner is configured in `rails_helper.rb`: `:transaction` strategy per example via `config.around`, with an initial `:truncation` clean before the suite. `DatabaseCleaner.allow_remote_database_url = true` is set so the suite can run against a non-local Postgres in CI/Docker. Rails' default transactional fixtures are disabled in favor of this.
- `config.infer_spec_type_from_file_location!` is on — but request specs still explicitly tag `type: :request` because they live in `spec/integration`, `spec/mutations`, and `spec/queries` (none of which Rails auto-infers).
- Gemfile test group: `factory_bot_rails`, `database_cleaner`, `webmock`, `rspec-sidekiq`, `rspec-rails`.

## Factories

All factories live flat under `spec/factories/` — one file per top-level model, no nested traits or sequences. Conventions worth knowing:

- `spec/factories/users.rb` — note the **plural filename** (the only plural one); generates a unique email via `SecureRandom.uuid` to avoid uniqueness collisions across the suite. Default password is `"hunter2"`.
- `spec/factories/team.rb` — auto-creates an `owner` user via `create(:user)`. Hardcoded name `"Fine Musical Folks"`.
- `spec/factories/room.rb` — depends on `team` association; defaults `current_record: nil`, `waiting_songs: false`.
- `spec/factories/song.rb` — hardcoded `youtube_id: "abcde"`; tests that need uniqueness override it explicitly.
- `spec/factories/room_playlist_record.rb` — defaults `play_state: "waiting"`, `order: 1`.
- `spec/factories/library_record.rb`, `message.rb`, `tag.rb` — all minimal, pulling associations from their default factories.

There is no factory for `Invitation`, `RecordListen`, or `Recommendation` — specs build those with `Model.create!` directly. Adding one is a safe extension if you find yourself repeating the same instantiation.

## Support helpers

Three modules, each opt-in via `include` inside `RSpec.describe`:

- `spec/support/auth_helper.rb` (`AuthHelper`) — the canonical way to authenticate a test request. `auth_headers(user)` mints (and memoizes per user) a `Doorkeeper::AccessToken` and returns a `Bearer` header. `graphql_request(query:, variables:, user:)` is the workhorse: it POSTs to `/api/v1/graphql` with the query/variables JSON body and the auth headers. Default `user:` is `create(:user)` — i.e., omitting the user still authenticates as a fresh user, never anonymously. Auth is **not** stubbed or mocked; tests exercise the real Doorkeeper token path end-to-end.
- `spec/support/graphql_helper.rb` (`GraphQLHelper`) — holds a small set of shared GraphQL query strings reused across specs (currently just `room_activate_mutation` and `room_playlist_query`). Most specs inline their query string in a private `query` method rather than adding it here.
- `spec/support/json_helper.rb` (`JsonHelper`) — `json_body` parses `response.body` with `symbolize_names: true`. It also asserts `response.successful?` and dumps the body on failure, which surfaces 500s clearly instead of letting them masquerade as nil-key errors deep in a `dig` chain.

## Integration tests

`spec/integration/requests_spec.rb` is the **only** integration spec — a single, long-form scenario test that walks three users through joining a room, building a collaborative playlist, and verifying both the broadcast payloads and the final query order. Notable choices:

- Wraps the whole example in `Sidekiq::Testing.inline!` so worker fan-out executes synchronously.
- Includes `ActionCable::TestHelper` to use `have_broadcasted_to(...).with do |msg| ... end` for asserting on channel payloads.
- Exercises the user-rotation playlist algorithm end-to-end (see `features/playlist-management/` for the underlying logic).

Add new high-level cross-feature scenarios here; per-mutation/per-query coverage belongs in `spec/mutations/` or `spec/queries/`.

## Mutation specs

Pattern in `spec/mutations/*_spec.rb`:

- `type: :request`, includes `AuthHelper` and `JsonHelper` (plus `GraphQLHelper` only when reusing shared queries).
- Each file defines a private `query` method returning a heredoc-style GraphQL string with `$variable` placeholders.
- Calls `graphql_request(query: query, variables: { ... }, user: current_user)` then inspects `json_body.dig(:data, :mutationName, ...)`.
- Side-effect assertions use `have_enqueued_sidekiq_job(...)` (from `rspec-sidekiq`) to verify broadcast workers fire — specs do not run the workers themselves. See `message_create_spec.rb` and `room_activate_spec.rb` for the canonical shape.
- External-service calls are stubbed with `instance_double` / `receive` — e.g. `song_create_spec.rb` stubs `YoutubeClient.new` rather than letting WebMock intercept.
- Error cases live in `describe "error"` or `describe "failure"` blocks and assert `data[:errors]` is non-empty rather than checking HTTP status (GraphQL returns 200 with errors in body).

## Query specs

`spec/queries/*_spec.rb` follow the same `type: :request` / `AuthHelper` / `JsonHelper` pattern as mutations. They tend to set up rich fixture graphs with `let!` (see `room_playlist_spec.rb` for the multi-record ordering setup) and assert on the shape returned by `json_body.dig(:data, :queryName)`. `search_spec.rb` demonstrates stubbing `YoutubeClient` for the fallback path when local search misses.

## Worker specs

`spec/workers/*_spec.rb` are `type: :worker` and call `described_class.new.perform(...)` directly (no Sidekiq enqueuing in between).

- **Broadcast workers** assert on `have_broadcasted_to(target).from_channel(ChannelClass).with do |msg| ... end`. See `broadcast_message_worker_spec.rb`.
- **Email workers** use `spec/workers/email_worker_shared_examples.rb` — a `shared_examples "a mailgun worker"` block that stubs the Mailgun HTTP endpoint via WebMock and runs `described_class.new.perform(*arguments)`. Each email worker spec `require_relative`s the shared file and calls `it_behaves_like "a mailgun worker" do let(:arguments) { ... }; let(:payload) { ... }; end`. Adding a new mailgun worker means adding a spec that reuses this block.
- `queue_management_worker_spec.rb` uses `ActiveSupport::Testing::TimeHelpers#travel_to` for asserting on `playing_until` timestamps, and combines synchronous `worker.perform(...)` with `have_enqueued_sidekiq_job(...)` to verify it dispatches downstream broadcast workers.

`rspec-sidekiq` is the gem providing `have_enqueued_sidekiq_job`. There is no global Sidekiq inline/fake mode set in `rails_helper.rb` — individual specs opt in via `Sidekiq::Testing.inline!` when they want fan-out to execute (currently only `spec/integration/requests_spec.rb` does this).

## Model specs

`spec/models/*_spec.rb` cover **only relationships** — they assert `has_many`, `belongs_to`, and join behavior by creating records and reading back associations. There are **no** validation tests, callback tests, or scope tests in the model specs. Business logic that lives on models is exercised indirectly through the mutation/query specs that call it. If you're adding a method to a model, the convention is to test it through the GraphQL resolver that exposes it, not via a unit spec on the model.

## Lib specs

`spec/lib/` covers plain-Ruby service objects in `app/lib/`:

- `spec/lib/room_playlist_generator_spec.rb` — tests `RoomPlaylistGenerator#playlist` by constructing rooms with specific `user_rotation` arrays and asserting the interleaved record order. Passes the `RoomPlaylistRecord.includes(:song, :user)` relation in explicitly to match the production call site.
- `spec/lib/room_queue_poller_spec.rb` — tests `RoomQueuePoller#poll!` by creating rooms in each "needs polling?" state and asserting which ones trigger `QueueManagementWorker` enqueues. This is the most direct documentation of the poller's selection logic.
- `spec/lib/arel/full_text_search_spec.rb` covers the custom Arel/FTS helper used by selectors.

No specs exist for `YoutubeClient`, `MusicboxUnwound`, or `Unwound` — they are exercised only through the GraphQL specs that call them.

# 20 — tagging

- id: 20
- kind: produce
- feature: Music Tagging
- verify: pass

## Produced
- `autopilot-support/index/features/tagging/map.md`
- `autopilot-support/index/features/tagging/patterns.md`
- `autopilot-support/index/features/tagging/boundaries.md`

## CSV basenames covered (all in `map.md`)
- `tag_create.rb`
- `tag_toggle.rb`
- `tag_type.rb`
- `tag.rb` (model)
- `tag_library_record.rb`
- `20200304014052_create_tags_table.rb`
- `20200304014747_create_tags_songs.rb`
- `20200401223702_add_unique_tags_songs_index.rb`
- `20200513040509_allow_library_record_to_associate_to_tags.rb`
- `tag.rb` (factory)
- `tag_spec.rb`
- `tag_create_spec.rb`
- `tag_toggle_spec.rb`

## Verify run
- All three files non-empty: pass
- Every CSV basename present in `map.md`: pass
- No `:NNN` line-number references in any of the three files: pass

## Notes
- Followed the password-reset feature triad as the structural model.
- Emphasized the user-scoped tag model, the `tags_library_records` plural-plural table-name quirk (because of the in-place rename from `tags_songs`), and the DB-index uniqueness contract as the non-obvious anchor points.
- Did not modify `progress.json`, `app/`, `lib/`, `db/`, `config/`, `spec/`, or any files outside the three feature files and this work log.

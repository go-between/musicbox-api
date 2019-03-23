class SongsController < ApplicationController
  # Mark this as a JSONAPI controller, associating with the given resource
  jsonapi resource: SongResource

  # Reference a strong resource payload defined in
  # config/initializers/strong_resources.rb
  strong_resource :song
  # Run strong parameter validation for these actions.
  # Invalid keys will be dropped.
  # Invalid value types will log or raise based on the configuration
  # ActionController::Parameters.action_on_invalid_parameters
  before_action :apply_strong_params, only: %i[create]

  def create
    return render_jsonapi(persisted_song, scope: false) if persisted_song.present?

    song, success = jsonapi_create.to_a
    if success
      render_jsonapi(song, scope: false)
    else
      render_errors_for(song)
    end
  end

  private

  def persisted_song
    return @_persisted_song if defined? @_persisted_song
    @_persisted_song = Song.find_by(youtube_id: attrs[:youtube_id])
  end
end

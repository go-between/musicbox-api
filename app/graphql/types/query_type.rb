# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    graphql_name "Query"

    field :invitation, Types::InvitationType, null: true do
      argument :token, ID, required: true
      argument :email, String, required: true
    end

    def invitation(token:, email:)
      Invitation.find_by(token: token, email: email&.downcase)
    end

    field :invitations, [Types::InvitationType], null: false do
    end

    def invitations
      confirm_current_user!
      return [] if current_user.active_team_id.blank?

      Invitation.where(inviting_user: current_user, team: current_user.active_team)
    end

    field :message, Types::MessageType, null: false do
      argument :id, ID, required: true
    end

    def message(id:)
      confirm_current_user!
      Message.find(id)
    end

    field :messages, [Types::MessageType], null: false do
      argument :from, Types::DateTimeType, required: false
      argument :to, Types::DateTimeType, required: false
    end

    def messages(from: nil, to: nil) # rubocop:disable Metrics/AbcSize
      confirm_current_user!
      return [] if current_user.active_room.blank?

      t = Message.arel_table
      messages = Message.where(room_id: current_user.active_room_id)
      messages = messages.where(t[:created_at].gteq(from)) if from.present?
      messages = messages.where(t[:created_at].lteq(to)) if to.present?

      messages.order(created_at: :asc)
    end

    field :room, Types::RoomType, null: true do
      argument :id, ID, required: true
    end

    def room(id:)
      confirm_current_user!
      rooms = Room.where(id: id)
      rooms = rooms.where(team: current_user.teams) if current_user.present?
      rooms.first
    end

    field :rooms, [Types::RoomType], null: true do
    end

    def rooms
      confirm_current_user!
      Room.where(team: current_user.active_team)
    end

    field :room_playlist, [Types::RoomPlaylistRecordType], null: true do
      argument :room_id, ID, required: true
    end

    def room_playlist(room_id:)
      confirm_current_user!
      room = Room.find(room_id)
      RoomPlaylist.new(room).generate_playlist
    end

    field :room_playlist_for_user, [Types::RoomPlaylistRecordType], null: true do
      argument :historical, Boolean, required: true
    end

    def room_playlist_for_user(historical:)
      confirm_current_user!
      records = current_user.room_playlist_records.where(room_id: current_user.active_room_id)
      return records.played.order(played_at: :desc) if historical

      records.waiting.order(:order)
    end

    field :song, Types::SongType, null: true do
      argument :id, ID, required: true
    end

    def song(id:)
      confirm_current_user!
      Song.find(id)
    end

    field :songs, [Types::SongType], null: true do
      argument :query, String, required: false
    end

    def songs(query: nil)
      confirm_current_user!

      library = current_user.songs
      library = library.where(Song.arel_table[:name].matches("%#{query}%")) if query.present?

      library
    end

    field :user, Types::UserType, null: false do
    end

    def user
      confirm_current_user!
      current_user
    end

    private

    def current_user
      context[:current_user]
    end

    def confirm_current_user!
      return if context[:override_current_user]
      raise NotAuthenticatedError unless current_user
    end
  end
end

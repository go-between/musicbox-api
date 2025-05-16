# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject # rubocop:disable Metrics/ClassLength
    graphql_name "Query"

    field :invitation, Types::InvitationType, null: true do
      argument :token, ID, required: true
      argument :email, String, required: true
    end

    def invitation(token:, email:)
      Invitation.find_by(token: token, email: email&.downcase)
    end

    field :invitations, [ Types::InvitationType ], null: false do
    end

    def invitations
      confirm_current_user!
      return [] if current_user.active_team_id.blank?

      Invitation.where(inviting_user: current_user, team: current_user.active_team)
    end

    field :library_record, Types::LibraryRecordType, null: true do
      argument :id, ID, required: true
    end

    def library_record(id:)
      confirm_current_user!
      LibraryRecord.find_by(id: id)
    end

    field :library_records, [ Types::LibraryRecordType ], null: true, extras: [ :lookahead ] do
      argument :query, String, required: false
      argument :tag_ids, [ ID ], required: false
      argument :order, Types::OrderType, required: false
    end

    def library_records(lookahead:, query: nil, tag_ids: [], order: nil)
      confirm_current_user!

      Selectors::LibraryRecords
        .new(lookahead: lookahead, user: current_user)
        .for_user
        .with_query(query)
        .with_tags(tag_ids)
        .without_pending_records
        .library_records(order: order)
    end

    field :message, Types::MessageType, null: false do
      argument :id, ID, required: true
    end

    def message(id:)
      confirm_current_user!
      Message.find(id)
    end

    field :messages, [ Types::MessageType ], null: false, extras: [ :lookahead ] do
      argument :from, Types::DateTimeType, required: false
      argument :to, Types::DateTimeType, required: false
    end

    def messages(lookahead:, from: nil, to: nil)
      confirm_current_user!
      return [] if current_user.active_room.blank?

      Selectors::Messages
        .new(lookahead: lookahead)
        .for_room_id(room_id: current_user.active_room_id)
        .in_date_range(to: to, from: from)
        .messages
    end

    field :pinned_messages, [ Types::MessageType ], null: false, extras: [ :lookahead ] do
      argument :song_id, ID, required: true
      argument :room_id, ID, required: false
    end

    def pinned_messages(song_id:, lookahead:, room_id: nil)
      confirm_current_user!
      return [] if current_user&.active_room&.blank? && room_id.blank?

      # Okay sort of gross and it's got some holes in it, but mostly
      # we're calling this with a current_user and no room_id.  Except
      # the broadcast worker which is calling with the opposite.
      select_for_room_id = if current_user&.active_room_id&.present?
                             current_user.active_room_id
      else
                             room_id
      end

      Selectors::Messages
        .new(lookahead: lookahead)
        .for_room_id(room_id: select_for_room_id)
        .when_pinned_to(song_id: song_id)
        .messages
    end

    field :recommendations, [ Types::LibraryRecordType ], null: false, extras: [ :lookahead ] do
      argument :song_id, ID, required: false
    end

    def recommendations(lookahead:, song_id: nil)
      includes = []
      includes << :song if lookahead.selects?(:song)
      includes << :user if lookahead.selects?(:user)
      includes << :from_user if lookahead.selects?(:from_user)

      records = LibraryRecord
      records = records.includes(includes) if includes.any?

      conditions = if song_id
                     { from_user: current_user, song_id: song_id }
      else
                     { source: "pending_recommendation", user: current_user }
      end

      records.where(conditions)
    end

    field :record_listens, [ Types::RecordListenType ], null: true, extras: [ :lookahead ] do
      argument :record_id, ID, required: true
    end

    def record_listens(record_id:, lookahead:)
      includes = []
      includes << :room_playlist_record if lookahead.selects?(:room_playlist_record)
      includes << :song if lookahead.selects?(:song)
      includes << :user if lookahead.selects?(:user)

      listens = RecordListen
      listens = listens.includes(includes) if includes.any?

      listens.where(room_playlist_record_id: record_id)
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

    field :rooms, [ Types::RoomType ], null: true do
    end

    def rooms
      confirm_current_user!
      Room.where(team: current_user.active_team)
    end

    field :room_playlist, [ Types::RoomPlaylistRecordType ], null: true, extras: [ :lookahead ] do
      argument :room_id, ID, required: true
      argument :historical, Boolean, required: false
      argument :from, Types::DateTimeType, required: false
    end

    def room_playlist(room_id:, lookahead:, historical: false, from: nil)
      confirm_current_user!

      Selectors::RoomPlaylistRecords
        .new(lookahead: lookahead)
        .select(room_id: room_id, historical: historical, from: from)
    end

    field :room_playlist_for_user, [ Types::RoomPlaylistRecordType ], null: true do
      argument :historical, Boolean, required: true
    end

    def room_playlist_for_user(historical:)
      confirm_current_user!
      records = current_user.room_playlist_records.where(room_id: current_user.active_room_id)
      return records.played.order(played_at: :desc) if historical

      records.waiting.order(:order)
    end

    field :search, [ Types::SearchResultType ], null: false, extras: [ :lookahead ] do
      argument :query, String, required: true
    end

    def search(query:, lookahead:)
      confirm_current_user!
      return [] if query.blank?

      Selectors::SearchResults
        .new(user: current_user, lookahead: lookahead)
        .search(query: query)
    end

    field :tags, [ Types::TagType ], null: false do
    end

    def tags
      confirm_current_user!
      current_user.tags
    end

    field :team, Types::TeamType, null: true do
      argument :id, ID, required: true
    end

    def team(id:)
      confirm_current_user!
      teams = Team.where(id: id)
      teams = teams.where(id: current_user.teams) if current_user.present?
      teams.first
    end

    field :unwound, Types::UnwoundType, null: false do
      argument :year, Int, required: true
      argument :team_id, ID, required: true
      argument :user_id, ID, required: false
      argument :week, Int, required: false
      argument :song_name, String, required: false
    end
    def unwound(year:, team_id:, user_id: nil, week: nil, song_name: nil)
      Unwound
        .new(
          year: year,
          team_id: team_id,
          user_id: user_id,
          week: week,
          song_name: song_name
        )
        .call
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

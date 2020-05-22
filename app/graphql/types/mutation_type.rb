# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :invitation_accept, mutation: Mutations::InvitationAccept
    field :invitation_create, mutation: Mutations::InvitationCreate

    field :message_create, mutation: Mutations::MessageCreate
    field :message_pin, mutation: Mutations::MessagePin

    field :password_reset_complete, mutation: Mutations::PasswordResetComplete
    field :password_reset_initiate, mutation: Mutations::PasswordResetInitiate

    field :recommendation_accept, mutation: Mutations::RecommendationAccept
    field :recommendation_create, mutation: Mutations::RecommendationCreate

    field :record_listen_create, mutation: Mutations::RecordListenCreate

    field :room_activate, mutation: Mutations::RoomActivate
    field :room_create, mutation: Mutations::RoomCreate

    field :room_playlist_record_abandon, mutation: Mutations::RoomPlaylistRecordAbandon
    field :room_playlist_record_add, mutation: Mutations::RoomPlaylistRecordAdd
    field :room_playlist_record_delete, mutation: Mutations::RoomPlaylistRecordDelete
    field :room_playlist_records_reorder, mutation: Mutations::RoomPlaylistRecordsReorder

    field :song_create, mutation: Mutations::SongCreate

    field :tag_create, mutation: Mutations::TagCreate
    field :tag_toggle, mutation: Mutations::TagToggle

    field :team_activate, mutation: Mutations::TeamActivate
    field :team_create, mutation: Mutations::TeamCreate

    field :library_record_delete, mutation: Mutations::LibraryRecordDelete
    field :user_password_update, mutation: Mutations::UserPasswordUpdate
    field :user_update, mutation: Mutations::UserUpdate
  end
end

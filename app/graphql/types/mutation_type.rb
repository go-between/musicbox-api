# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :invitation_accept, mutation: Mutations::InvitationAccept
    field :invitation_create, mutation: Mutations::InvitationCreate

    field :message_create, mutation: Mutations::MessageCreate

    field :room_activate, mutation: Mutations::RoomActivate
    field :room_create, mutation: Mutations::RoomCreate

    field :room_playlist_record_delete, mutation: Mutations::RoomPlaylistRecordDelete
    field :room_playlist_records_reorder, mutation: Mutations::RoomPlaylistRecordsReorder

    field :song_create, mutation: Mutations::SongCreate

    field :tag_associate, mutation: Mutations::TagAssociate
    field :tag_create, mutation: Mutations::TagCreate

    field :team_activate, mutation: Mutations::TeamActivate
    field :team_create, mutation: Mutations::TeamCreate

    field :user_library_record_delete, mutation: Mutations::UserLibraryRecordDelete
  end
end

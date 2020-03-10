# frozen_string_literal: true

class MessageSelector
  attr_reader :arel, :current_user, :to, :from, :lookahead
  def initialize(current_user:, lookahead:)
    @current_user = current_user
    @lookahead = lookahead

    @arel = Message.arel_table
  end

  def select(to: nil, from: nil, room_id: nil, song_id: nil)
    messages = record_context.where(room_id: current_user.active_room_id)

    messages = with_date_filtering(messages, to, from)
    messages = when_pinned_to(messages, room_id, song_id)
    messages.order(created_at: :asc)
  end

  private

  def record_context
    includes = []
    includes << :room if lookahead.selects?(:room)
    includes << :room_playlist_record if lookahead.selects?(:room_playlist_record)
    includes << :song if lookahead.selects?(:song)
    includes << :user if lookahead.selects?(:user)
    return Message if includes.blank?

    Message.includes(includes)
  end

  def with_date_filtering(messages, to, from)
    messages = messages.where(arel[:created_at].lteq(to)) if to.present?
    messages = messages.where(arel[:created_at].gteq(from)) if from.present?

    messages
  end

  def when_pinned_to(messages, room_id, song_id)
    return messages unless room_id.present? && song_id.present?

    messages.where(song_id: song_id, room_id: room_id, pinned: true)
  end
end

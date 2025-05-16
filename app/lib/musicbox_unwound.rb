# frozen_string_literal: true

class MusicboxUnwound
  attr_reader :ref_time, :team, :users, :invalid_songs

  def initialize(ref_time: Time.zone.now)
    @ref_time = ref_time
    @start = ref_time.beginning_of_year
    @finish = ref_time.end_of_year

    @team = Team.find_by(name: "Plug Dot DJ Expats")
    @users = @team.users
    @invalid_songs = Song.where(Song.arel_table[:duration_in_seconds].gteq(60 * 60 * 1.5))
  end

  def call
    all_time_popular
    users.each { |user| top_10_for(user) }
    total_plays_by
    approvals_by_song
    top_5_historic
    # New this year, all time & per-person
    # Total play duration, all time & per-person

    nil
  end

  private

  def all_time_popular
    top_25 = plays_this_year.group(:song_id).order(count: :desc).count(:id).take(25).to_h

    top_25_songs = Song.where(id: top_25.keys).group_by(&:id)
    rows = top_25.map do |song_id, count|
      [ top_25_songs[song_id].first.name, count ]
    end

    puts Terminal::Table.new(title: "Most Played", headings: %w[Song Plays], rows: rows)
  end

  def top_10_for(user)
    top_25 = plays_this_year.where(user: user).group(:song_id).order(count: :desc).count(:id).take(25).to_h
    return if top_25.blank?

    top_25_songs = Song.where(id: top_25.keys).group_by(&:id)
    rows = top_25.map do |song_id, count|
      [ top_25_songs[song_id].first.name, count ]
    end

    puts Terminal::Table.new(title: "#{user.name} Most Played", headings: %w[Song Plays], rows: rows)
  end

  def total_plays_by
    user_plays = plays_this_year.group(:user_id).count(:id)
    user_group = users.group_by(&:id)

    rows = user_plays.map do |user_id, count|
      [ user_group[user_id].first.name, count ]
    end

    puts Terminal::Table.new(title: "Plays by User", headings: %w[User Plays], rows: rows)
  end

  def top_5_historic
    current_period = ref_time

    loop do
      top_5 = plays_in_period(current_period.beginning_of_year, current_period.end_of_year).group(:song_id).order(count: :desc).count(:id).take(5).to_h
      break if top_5.blank?

      top_5_songs = Song.where(id: top_5.keys).group_by(&:id)
      rows = top_5.map do |song_id, count|
        [ top_5_songs[song_id].first.name, count ]
      end

      puts Terminal::Table.new(title: "Most Played - #{current_period.year}", headings: %w[Song Plays], rows: rows)
      current_period -= 1.year
    end
  end

  def approvals_by_song
    top_25 = record_listens_this_year.group(:song_id).order(count: :desc).sum(:approval).take(25).to_h
    top_25_songs = Song.where(id: top_25.keys).group_by(&:id)
    rows = top_25.map do |song_id, count|
      [ top_25_songs[song_id].first.name, count ]
    end

    puts Terminal::Table.new(title: "Most Approved", headings: %w[Song Approval], rows: rows)
  end

  def record_listens_this_year
    record_listens_in_period(ref_time.beginning_of_year, ref_time.end_of_year)
  end

  def plays_this_year
    plays_in_period(ref_time.beginning_of_year, ref_time.end_of_year)
  end

  def plays_in_period(beginning_period, end_period)
    arel = RoomPlaylistRecord.arel_table
    RoomPlaylistRecord
      .where(arel[:created_at].gteq(beginning_period))
      .where(arel[:created_at].lteq(end_period))
      .where(user: users)
      .where.not(song: invalid_songs)
  end

  def record_listens_in_period(beginning_period, end_period)
    arel = RecordListen.arel_table
    RecordListen
      .where(arel[:created_at].gteq(beginning_period))
      .where(arel[:created_at].lteq(end_period))
      .where(user: users)
      .where.not(song: invalid_songs)
  end
end

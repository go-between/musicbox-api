# frozen_string_literal: true

# Unwound.new(
#   year: 2023,
#   team_id: "24a354b9-2b43-41e2-8dd3-66dc401213b5",
#   user_id: nil,
#   week: nil,
#   song_name: nil
# ).call

class Unwound
  attr_reader :year, :team_id, :user_id, :week, :song_name

  def initialize(year:, team_id:, user_id:, week:, song_name:)
    @year = year
    @team_id = team_id
    @user_id = user_id
    @week = week
    @song_name = song_name
  end

  def call
    {
      team_plays: team_plays,
      team_approvals: team_approvals,
      top_plays_over_time: top_plays_over_time,
      top_plays: top_plays,
      top_approvals: top_approvals,
      song_plays_over_time: song_plays_over_time
    }
  end

  def team_plays
    plays_in_period
      .group(:user_id)
      .select("room_playlist_records.user_id as user_id, count(room_playlist_records.id) as total_plays, sum(songs.duration_in_seconds) as total_length")
      .map do |record|
        {
          label: team.users.find(record.user_id).name,
          count: record.total_plays,
          length: record.total_length
        }
      end
  end

  def team_approvals
    record_listens_in_period
      .group(:song_id)
      .select("record_listens.song_id as song_id, sum(record_listens.approval) as total_approval")
      .order("total_approval desc")
      .take(10)
      .map do |record|
        {
          label: Song.find(record.song_id).name,
          count: record.total_approval,
          length: 0
        }
      end
  end

  def top_plays_over_time
    []
  end

  def top_plays
    []
  end

  def top_approvals
    plays_in_period
      .group(:user_id)
      .select("room_playlist_records.user_id as user_id, count(room_playlist_records.id) as total_plays, sum(songs.duration_in_seconds) as total_length")
      .map do |record|
        {
          label: team.users.find(record.user_id).name,
          count: record.total_plays,
          length: record.total_length
        }
      end
  end

  def song_plays_over_time
    {
      name: "",
      plays: []
    }
  end

  private

  def start_day
    return @start_day if defined? @start_day

    # NOTE:  January first is not always in the first week because
    #        of leap days and also just because dates are weird.
    first_day_of_week_one = "#{year}-01-01".to_date
    first_day_of_week_one += 1.day while first_day_of_week_one.cweek != 1

    return @start_day = first_day_of_week_one + ((week - 1) * 7).days if week.present?

    @start_day = first_day_of_week_one
  end

  def invalid_songs
    return @invalid_songs if defined? @invalid_songs

    @invalid_songs = Song.where(Song.arel_table[:duration_in_seconds].gteq(60 * 60 * 1.5))
  end

  def period_start
    return @period_start if defined? @period_start
    return @period_start = start_day.beginning_of_week if week.present?

    @period_start = start_day.beginning_of_year
  end

  def period_end
    return @period_end if defined? @period_end
    return @period_end = start_day.end_of_week if week.present?

    @period_end = start_day.end_of_year
  end

  def plays_in_period
    arel = RoomPlaylistRecord.arel_table
    RoomPlaylistRecord
      .joins(:song)
      .where(arel[:created_at].gteq(period_start))
      .where(arel[:created_at].lteq(period_end))
      .where(user: users)
      .where.not(song: invalid_songs)
  end

  def record_listens_in_period
    arel = RecordListen.arel_table
    RecordListen
      .joins(:song)
      .where(arel[:created_at].gteq(period_start))
      .where(arel[:created_at].lteq(period_end))
      .where(user: users)
      .where.not(song: invalid_songs)
  end

  def team
    return @team if defined? @team

    @team = Team.find(team_id)
  end

  def users
    return @users if defined? @users
    return @users = User.find(user_id) if user_id.present?

    @users = team.users
  end
end

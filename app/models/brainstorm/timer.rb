class Brainstorm::Timer
  include Kredis::Attributes

  kredis_integer  :duration_proxy, key: ->(t) { "brainstorm_id_duration_#{t.id}" }
  kredis_datetime :started_at

  def initialize(brainstorm)
    @brainstorm = brainstorm

    if previous_started_at = Kredis.hash("brainstorm_id_timer_running_#{id}").hget("timer_start_timestamp").presence
      started_at.value = DateTime.parse(previous_started_at)
    end
  end

  def duration() = duration_proxy.value || 10.minutes.to_i
  def duration=(duration); duration_proxy.value = duration; end

  def start
    started_at.value = Time.now
    check_expiry_later
    broadcast :start, duration
  end

  def check_expiry_later
    ExpiryJob.set(wait: duration).perform_later(brainstorm)
  end

  def check_expiry
    if expired?
      brainstorm.timer_expired
      broadcast :expired
    end
  end


  def running?
    remaining_seconds.positive?
  end

  def expired?
    remaining_seconds.zero?
  end

  def remaining_seconds
    [ duration - elapsed_seconds, 0 ].max
  end

  def elapsed_seconds
    if value = started_at.value
      Time.now.to_i - value.to_i
    else
      0
    end
  end


  def id() = brainstorm.token

  private

  attr_reader :brainstorm

  def broadcast(event, duration = nil)
    TimerChannel.broadcast_to brainstorm, { event: event, duration: duration }
  end
end
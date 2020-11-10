class ApplicationController < ActionController::Base
  MAX_VOTES_PER_USER = 6
  private

  def set_session_id
    if cookies[:user_id].nil?
      cookies[:user_id] = SecureRandom.uuid
      @session_id = cookies[:user_id]
    else
      @session_id = cookies[:user_id]
    end
  end

  def idea_build_votes
    @idea_build_votes = REDIS.smembers(user_idea_build_votes_key).map(&:to_i)
  end

  def idea_votes
    @idea_votes = REDIS.smembers(user_idea_votes_key).map(&:to_i)
  end

  def user_idea_votes_key
    "user_idea_votes_#{@session_id}_#{@brainstorm.token}"
  end

  def user_idea_build_votes_key
    "user_idea_build_votes_#{@session_id}_#{@brainstorm.token}"
  end

  def votes_left
    @votes_left = MAX_VOTES_PER_USER-(REDIS.smembers(user_idea_votes_key).count + REDIS.smembers(user_idea_build_votes_key).count)
  end

  def votes_cast
    @votes_cast = REDIS.smembers(user_idea_votes_key).count + REDIS.smembers(user_idea_build_votes_key).count
  end

end

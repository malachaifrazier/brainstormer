class BrainstormsController < ApplicationController
  before_action :set_brainstorm, only: [:show, :start_timer, :start_brainstorm, :start_voting]
  before_action :set_brainstorm_ideas, only: [:show]
  before_action :set_session_id, only: [:show, :create]
  before_action :facilitator?, only: [:show]
  before_action :facilitator_name, only: [:show]
  before_action :get_state, only: [:show]
  before_action :votes_left, only: [:show]
  before_action :votes_cast, only: [:show]
  before_action :idea_votes, only: [:show]
  before_action :idea_build_votes, only: [:show]

  def index
    @brainstorm = Brainstorm.new
  end

  def create
    @brainstorm = Brainstorm.new(brainstorm_params)
    @brainstorm.token = generate_token
    respond_to do |format|
      if @brainstorm.save
        REDIS.set @session_id, @brainstorm.name
        REDIS.srem "no_user_name", @session_id
        REDIS.set brainstorm_state_key, "setup"
        set_facilitator
          format.js { render :js => "window.location.href = '#{brainstorm_path(@brainstorm.token)}'" }
      else
        @brainstorm.errors.messages.each do |message|
          flash.now[message.first] = message[1].first
          format.js
        end
      end
    end
  end

  def show
    @idea = Idea.new
    @current_user_name = REDIS.get(@session_id)
  end

  def set_user_name
    respond_to do |format|
      if REDIS.set set_user_name_params[:session_id], set_user_name_params[:user_name]
          REDIS.srem "no_user_name", set_user_name_params[:session_id]
          ActionCable.server.broadcast("brainstorm-#{params[:token]}-presence", event: "name_changed", name: set_user_name_params[:user_name] )
          format.html {}
          format.js
      else
          format.html {}
          format.js
      end
    end
  end

  def send_ideas_email
    respond_to do |format|
      if IdeasMailer.with(token: params[:token], email: params[:email]).ideas_email.deliver_later
          format.html {}
          format.js
      else
          format.html {}
          format.js
      end
    end
  end

  def go_to_brainstorm
    respond_to do |format|
      if !Brainstorm.find_by(token: params[:token].sub("#", "")).nil?
        format.js { render :js => "window.location.href = '#{brainstorm_path(params[:token].sub("#", ""))}'" }
      else
          flash.now["token"] = "It looks like this ID doesn't exist"
          format.js
      end
    end
  end

  def start_timer
    respond_to do |format|
      if REDIS.hget(brainstorm_timer_running_key, "timer_start_timestamp").nil?
        ActionCable.server.broadcast("brainstorm-#{params[:token]}-timer", event: "start_timer")
        REDIS.hset(brainstorm_timer_running_key, "timer_start_timestamp", Time.now)
          format.js
      else
        ActionCable.server.broadcast("brainstorm-#{params[:token]}-timer", event: "reset_timer")
        REDIS.hdel(brainstorm_timer_running_key, "timer_start_timestamp")
          format.js
      end
    end
  end

  def start_brainstorm
      REDIS.set(brainstorm_state_key, "ideation")
      ActionCable.server.broadcast("brainstorm-#{params[:token]}-timer", event: "set_brainstorm_state", state: "ideation")
  end

  def start_voting
      REDIS.set(brainstorm_state_key, "vote")
      ActionCable.server.broadcast("brainstorm-#{params[:token]}-timer", event: "set_brainstorm_state", state: "vote")
  end

  private

  def generate_token
    "BRAIN" + SecureRandom.hex(3).to_s
  end

  def set_brainstorm
    @brainstorm = Brainstorm.find_by token: params[:token]
  end

  def brainstorm_params
    params.require(:brainstorm).permit(:problem, :name)
  end

  def set_brainstorm_ideas
    @ideas = @brainstorm.ideas.order('id DESC')
  end

  def set_user_name_params
    params.require(:set_user_name).permit(:user_name, :session_id)
  end

  def set_facilitator
    REDIS.set brainstorm_facilitator_key, @session_id
  end

  def facilitator?
    @is_user_facilitator = REDIS.get(brainstorm_facilitator_key) == @session_id
  end

  def facilitator_name
    @brainstorm_facilitator_name = REDIS.get(REDIS.get(brainstorm_facilitator_key))
  end

  def brainstorm_facilitator_key
    "brainstorm_facilitator_#{@brainstorm.token}"
  end

  def brainstorm_timer_running_key
    "brainstorm_id_timer_running_#{@brainstorm.token}"
  end

  def brainstorm_state_key
    "brainstorm_state_#{@brainstorm.token}"
  end

  def get_state
    @state = REDIS.get(brainstorm_state_key)
  end
end
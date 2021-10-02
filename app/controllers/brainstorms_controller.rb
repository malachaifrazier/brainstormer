class BrainstormsController < ApplicationController
  include BrainstormScoped, Ideated

  before_action :set_session, only: [:show, :create, :done_voting]

  def new
    @brainstorm = Brainstorm.new
  end

  def create
    @brainstorm = Brainstorm.new(brainstorm_params)
      if @brainstorm.save
        REDIS.set @session_id, @brainstorm.name
        @brainstorm.state = :setup
        @brainstorm.facilitator_session_id = @session_id
        redirect_to "/#{@brainstorm.token}"
      else
        render :new
      end

  end

  def show
    @ideas = @brainstorm.ideas
    @idea  = @ideas.new

    @current_facilitator = @brainstorm.facilitator.id == @session_id

    @voting = Session::Voting.new(@brainstorm, @session_id)
  end

  def go_to_brainstorm
    token = params[:token].remove("#")
    brainstorm = Brainstorm.find_sole_by_token(token)

    respond_to do |format|
      if !brainstorm.nil? && token.length >= 6
        format.js { render :js => "window.location.href = '#{brainstorm_path(brainstorm.token)}'" }
      elsif token.length == 0
        flash.now["token"] = "You forgot to write an ID! If you don't have one you should ask the facilitator"
        format.js
      elsif token.length < 6
        flash.now["token"] = "It looks like this ID is too short"
        format.js
      else
        flash.now["token"] = "It looks like this ID doesn't exist"
        format.js
      end
    end
  end

  def done_brainstorming
    start_voting
    @brainstorm.timer.reset
  end

  def start_brainstorm
    @brainstorm.state = :ideation
    StateChannel.broadcast_to @brainstorm, { event: "set_brainstorm_state", state: "ideation" }
    @brainstorm.timer.start
  end

  def start_voting
    @brainstorm.state = :vote
    StateChannel.broadcast_to @brainstorm, { event: "set_brainstorm_state", state: "vote" }
    transmit_ideas(sort_by_id_desc)
  end

  def done_voting
    @voting = Session::Voting.new(@brainstorm, @session_id)
    @voting.toggle_voting_done
    ActionCable.server.broadcast("brainstorm-#{@brainstorm.token}-presence", { event: "toggle_done_voting_badge", state: "vote", user_id: @session_id })
  end

  def end_voting
    @brainstorm.state = :voting_done
    ActionCable.server.broadcast("brainstorm-#{params[:token]}-presence", { event: "remove_done_tags_on_user_badges" })
    StateChannel.broadcast_to @brainstorm, { event: "set_brainstorm_state", state: "voting_done" }
    transmit_ideas(sort_by_votes_desc)
  end

  def change_state
    @brainstorm.state = params[:new_state].to_sym
    StateChannel.broadcast_to @brainstorm, { event: "set_brainstorm_state", state: params[:new_state] }
  end

  private

  def brainstorm_params
    params.require(:brainstorm).permit(:problem, :name)
  end

  def brainstorm_key
    "brainstorm_id_#{@brainstorm.token}"
  end
end

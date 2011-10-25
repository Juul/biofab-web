class Admin::TasksController < ApplicationController

  # TODO should only be available to admins

  def index
    
  end

  def delay
    if !current_user
      render :text => "please log in"
      return
    end

    # deliver mail immediately
    # ProcessMailer.flowcyte_completed(current_user).deliver

    # deliver mail delayed
    ProcessMailer.delay.flowcyte_completed(current_user)

    # delay method
    # current_user.delay.foowriter

    render :text => 'delaying!'
  end

end

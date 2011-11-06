class ProcessMailer < ActionMailer::Base

  # Make helpers available for views
  add_template_helper(ApplicationHelper)

  default :from => Settings['admin_email']

  def flowcyte_completed(user, id)
    # TODO settings.yml
    @id = id

    if system("which fortune > /dev/null")
      @fortune = `fortune`
    else
      @fortune = nil
    end

    mail(:to => user.email, 
         :subject => "[FabIO] Flow cytometer analysis results ready!")

  end

  def error(user, exception)
    @e = exception
    mail(:to => user.email, 
         :subject => "[FabIO] An error occurred")
  end
  
end

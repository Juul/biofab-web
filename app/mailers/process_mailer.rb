class ProcessMailer < ActionMailer::Base
  # TODO create a settings.yml for this
  default :from => "mjchristoffersen@lbl.gov"

  def flowcyte_completed(user, id)
    # TODO settings.yml
    @url = "http://localhost:3000/plate_layout/data/#{id}"

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

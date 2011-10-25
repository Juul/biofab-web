class ProcessMailer < ActionMailer::Base
  # TODO create a settings.yml for this
  default :from => "mjchristoffersen@lbl.gov"

  def flowcyte_completed(user)
    # TODO settings.yml
    @url = "http://localhost:8080/plates/3#!data"

    if system("which fortune > /dev/null")
      @fortune = `fortune`
    else
      @fortune = nil
    end

    mail(:to => user.email, 
         :subject => "[FabIO] Flow cytometer analysis results ready!")

  end
  
end

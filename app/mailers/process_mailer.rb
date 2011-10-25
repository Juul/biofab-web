class ProcessMailer < ActionMailer::Base
  # TODO create a settings.yml for this
  default :from => "mjchristoffersen@lbl.gov"

  def flowcyte_completed(user)
    # TODO settings.yml
    @url = "http://localhost:8080/plates/3#!data"

    mail(:to => user.email, 
         :subject => "[BIOFABio] Flow cytometer analysis results ready!")

  end
  
end

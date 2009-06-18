
require 'singleton'
require 'net/smtp'
require File.dirname(__FILE__)+'/hook_logger'
require 'date'
require File.dirname(__FILE__)+'/configuration'
  
##
# Utility class to send email notifications.
#
# == Examples
#
# === Sending messages
#
#     MailSender.instance.send_mail("this is the body.")
#
module Util
  class MailSender
    include Singleton
    include HookLogger
    attr_reader :message
    
    def initialize
      init_log
    end
    
    ##
    # Send an email to release engineers.
    
    def send_mail(recipients,subject, body)
      
      begin
        Net::SMTP.start('smtp.federated.fds') do |smtp|
          make_message(subject, body)
          smtp.send_message @message,
                            'subversion@macys.com', recipients
        end
      rescue Exception => e
        # log the error at least
        @logger.error(e)
        raise
      end
    end
    
    ##
    # Assembles the message. 
    def make_message(subject, body)
      now=DateTime::now().to_s
      @message= "From: Subversion <subversion@macys.com>\n"
      @message << "To: Rel Engineer <mcom.SB@macys.com>\n"
      @message << "Date: #{now}\n"
      @message << "Subject: #{subject}\n\n"
      @message << body
    end
  end
end

#Util::MailSender.instance.send_mail("second test")

require 'test/unit'
require File.dirname(__FILE__)+"/../ruby/mail_sender"
  
class MailSenderTestCase < Test::Unit::TestCase
  
  def setup
  end
  
  def test_make_body
    mail_sender=Util::MailSender.instance
    mail_sender.make_message("this is subject", "my body")
    assert_match("\n\nmy body", mail_sender.message)
  end
end

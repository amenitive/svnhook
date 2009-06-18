require 'test/unit'
require File.dirname(__FILE__)+"/../ruby/symlink_verifier"
  
class SymlinkVerifierTestCase < Test::Unit::TestCase
  
  def setup
    @verifier=Hooks::SymlinkVerifier.new
  end
  
  def test_check_for_changes
    #override those two methods
    class << @verifier
      def change_checker
        ['A  john', 'U  joe', 'A  jill']
      end
      def attribute_checker(changed_file)
        if changed_file=='joe'
          ret='*'
        end
        ret='' if ret!='*'
        ret
      end
    end

    block_called=false
    @verifier.check_for_changes do |symlinks|
      assert symlinks.size==1
      block_called=true
    end
    assert block_called
    
    # test happy path
    class << @verifier
      def attribute_checker(changed_file)
        ''
      end
    end
    @verifier.check_for_changes do |symlinks|
      assert false
    end
  end
  
  def test_send_mail
    author = "janos"
    date_committed = "2009"
    log_message="link for no reason"
    hash={:author => author, :date => date_committed, :log=>log_message}
    block_invoked=false
    @verifier.send_mail ['trunk/link'], hash do |subject,body|
      
      puts block_invoked
      assert subject.index("Symbolic links checked in")!=nil
      assert body.index("janos")!=nil
      assert body.index("2009")!=nil
      assert body.index("link for no reason")!=nil
      assert body.index("symlinks")!=nil
      assert body.index("trunk/link")!=nil
      block_invoked=true
    end
    assert block_invoked
  end
end

require 'test/unit'
require File.dirname(__FILE__)+"/../ruby/comment_checker"
  
class CommentCheckerTestCase < Test::Unit::TestCase
  
  def setup
    @checker=Hooks::CommentChecker.new
  end
  
  def test_verify_comment
    @checker.comment_retriever=Proc.new {|repo,txn| "added\n" }
    assert @checker.verify_comment('repo', 'txn')
  end
  
  def test_check_comment
    
    @checker.comment='this is comment 2'
    assert @checker.checkComment
    
    @checker.comment='short'
    assert_raise RuntimeError do
      @checker.checkComment
    end
    
    @checker.comment='added'
    assert @checker.checkComment
    
    @checker.comment='removed'
    assert @checker.checkComment
  end
end

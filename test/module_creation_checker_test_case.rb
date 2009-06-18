require 'test/unit'
require File.dirname(__FILE__)+"/../ruby/module_creation_checker"
  
class ModuleCreationCheckerTestCase < Test::Unit::TestCase
  
  def setup
    @checker=Hooks::ModuleCreationChecker.new
    @checker.change_list_finder=Proc.new { |repo,txn| ['U  scripts/blah.rb', 
          'A   codebase/newmodule/',
          'U   codebase/newmodule/',
          'D   codebase/newmodule/',
          'A  Joe.java'] }
    @checker.author_finder=Proc.new { |repo,txn| "jill" }
  end
  
  def test_check_module
    Configuration.config[:module_root]="turtle"
    block_invoked=false
    @checker.check_module("A   turtle/newmodule/") do
      block_invoked=true
    end
    assert block_invoked
    
    @checker.check_module("A   turtle/newmodule/blah.java") do
      assert false, "Module detected for no reason."
    end
    
    @checker.check_module("U   turtle/newmodule/") do
      assert false, "Module detected while updating."
    end
    
  end
  
  def test_resolve_new_modules
    Configuration.config[:module_root]="codebase"
    block_invoked=false
    @checker.resolve_new_modules("repo","txn") do |author, new_modules|
      assert_equal "jill", author, "Did not provide author"
      assert_equal 1, new_modules.size, "Did not detect modules."
      block_invoked=true
    end
    assert block_invoked
  end
  
  def test_check_for_new_modules
    
    Configuration.config[:users_allowed_to_create_modules]=['jill']
    ret=@checker.check_for_new_modules("repo","txn")
    assert_nil ret
    
    @checker.author_finder=Proc.new { |repo,txn| "jack" }
    ret=@checker.check_for_new_modules("repo","txn")
    assert_not_nil ret
    assert_not_nil ret.index("jack"), "Message did not contain user jack"
    assert_not_nil ret.index("A   codebase/newmodule"), "Message did not contain module"
    
    #let everybody create new modules
    Configuration.config[:users_allowed_to_create_modules]=['*']
    ret=@checker.check_for_new_modules("repo","txn")
    assert_nil ret
  end
end

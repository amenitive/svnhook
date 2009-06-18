require 'test/unit'

require File.dirname(__FILE__)+"/../ruby/mixed_resource_checker"
  
class MixedResourceCheckerTestCase < Test::Unit::TestCase
  
  def setup
    @checker=Hooks::MixedResourceChecker.new
  end
  
  def test_check_mixed_resource
    class << @checker
      def change_list_finder(repo, txn)
        [ 'A  src/main/java/MyClazz.java',
          'U  src/main/java/com/macys',
          'A  src/main/resources/com/macys/spring.xml']
      end
      def author_check(repo, revision_or_txn)
        "joe"
      end
    end

    assert @checker.check_for_mixed_resources('repo','txn'), "Error for valid files."
   
    class << @checker
      def change_list_finder(repo, txn)
        ['A  src/main/java/MyClazz.java',
          'U  src/main/java/com/macys',
          'A  src/main/java/com/macys/spring.xml']
      end
    end
    
    assert !@checker.check_for_mixed_resources('repo','txn'), "Not false returned for invalid file(s)."
  end
  
  def test_check_changes
    
    assert @checker.check_mixin_for_file('src/main/java/MyClazz.java')
    assert @checker.check_mixin_for_file('src/main/java/com/macys') # no ext, ok
    assert @checker.check_mixin_for_file('src/test/java/com/macys') # no ext, ok
    assert @checker.check_mixin_for_file('src/test/java/com/macys/MyClazz.java')
    assert @checker.check_mixin_for_file('src/main/resources/com/macys/spring.xml')
    assert !@checker.check_mixin_for_file('src/main/java/com/macys/picture.gif')
    assert !@checker.check_mixin_for_file('src/test/java/com/macys/picture.xml')
    assert @checker.check_mixin_for_file('src/main/java/com/macys/package.html')
  end

  def test_excluded_user
    class << @checker
      attr_accessor :called
      def author_check(repo, revision_or_txn)
        MCYWAS
      end
      # since we return the special user mcywas, this can not be called. This is how we detect if the call is made.
      def change_list_finder(repo,txn)
         @called=true
         []
       end
    end
    @checker.execute("myrepo", "mytxn")
    assert(! @checker.called, "Called change_list_finder in spite of exempt user.")
  end
  
end

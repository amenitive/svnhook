require 'test/unit'
require File.dirname(__FILE__)+"/../ruby/mixed_case_checker"
  
class MixedCaseCheckerTestCase < Test::Unit::TestCase
  
  def setup
    @checker=Hooks::MixedCaseChecker.new
    class << @checker
      def author_check(repo, revision_or_txn)
        "joe" # let the good user go
      end
    end
  end
  
  def test_check_mixed_case
    class << @checker
      def change_list_finder(repo, txn)
        ['A   turtle/stuff.txt','A  turtle/Boo.java']
      end
      def subversion_tree(dir)
         ['turtle/',' turtle/stuff2.txt',' turtle/Booo.java', '  turtle/snake/Boo.java']
      end
    end
   
    assert_nil @checker.check_mixed_case("repo","txn"), "Does not work with non-conflicting files."
  end
  
  def test_check_mixed_case_unhappy
    class << @checker
      def change_list_finder(repo, txn)
        ['A   turtle/stuff.txt',
         'A   turtle/Boo.java','A   parrot/foo/bar.txt']
      end
      def subversion_tree(dir)
         if dir=='turtle/'
            ['turtle/']
         else
            ['foo/', ' baR.txt']
         end
      end
    end

    msg=@checker.check_mixed_case("repo","txn")
    assert_not_nil msg, "Does not recognize case difference."
    assert_not_nil msg.index("parrot/foo/bar.txt"), "Does not include offending file in message."
  end

  def test_check_mixed_case_directory_unhappy
    class << @checker
      def change_list_finder(repo, txn)
        ['A   trunk/turtle/']
      end
      def subversion_tree(dir)
        ['trunk/', ' Turtle/']
      end
    end

    msg=@checker.check_mixed_case("repo","txn")
    assert_not_nil msg, "Does not recognize case difference."
  end

  def test_check_mixed_case_unhappy2
    class << @checker
      def change_list_finder(repo, txn)
        ['A  turtle/stuff.txt',
         'A  turtle/Boo.java',
         'A  parrot/foo/bar/horse/mouse/' ]
      end
      def subversion_tree(dir)
        if dir=='parrot/foo/bar/horse/'
          ['horse/', ' mousE/']
        else
          [dir]
        end
      end
    end

    msg=@checker.check_mixed_case("repo","txn")
    assert_not_nil msg,"Does not recognize case difference."
    assert_not_nil msg.index("mouse"), "Does not include offending directory in message."
  end

  ##
  # Should not report error since the other file is deleted.

  def test_check_mixed_case_delete
    class << @checker
      def change_list_finder(repo, txn)
        ['A  parrot/foo/bar/horse/mouse','D  parrot/foo/bar/horse/mousE']
      end
      def subversion_tree(dir)
        [dir]
      end
    end 

    assert_nil @checker.check_mixed_case("repo","txn"), "Does not exclude deleted path."
  end
  
  def test_check_siblings
    class << @checker
      def subversion_tree(dir)
        [dir]
      end
    end
    
    assert_nil @checker.check_siblings("turtle/pic.gif")
    assert_not_nil @checker.check_siblings("turtle/pIc.gif")
    # check directory or file with no extension
    assert_nil @checker.check_siblings("turtle/parrot/")
    assert_not_nil @checker.check_siblings("turtle/Parrot/")
    
    # check deeper
    assert_nil @checker.check_siblings("turtle/parrot/horse/")
    assert_not_nil @checker.check_siblings("turtle/parrot/horSe/")
  end

  def test_excluded_user
    class << @checker
      attr_accessor :called
      def author_check(repo, revision_or_txn)
        MCYWAS
      end
      # since we return the special user mcywas, this can not be called. This is how we detect if the call is made.
      def change_list_finder(repo, txn)
        @called=true
        []
      end
    end

    @checker.execute("myrepo", "mytxn")
    assert(! @checker.called, "Called change_list_finder in spite of exempt user.")
  end
end
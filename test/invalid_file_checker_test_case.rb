require 'test/unit'

require File.dirname(__FILE__)+"/../ruby/invalid_file_checker"
  
class InvalidFileCheckerTestCase < Test::Unit::TestCase
  
  def setup
    @checker=Hooks::InvalidFileChecker.new
  end
  
  def test_check_target

    class << @checker
      def change_list_finder(txn)
        ['A  parrot/target/bar/horse/mousE', 'A  parrot/foo/bar/horse/mouse']
      end
    end

    assert_not_nil @checker.execute('repo','txn'), "No error for path containing /target/."
    
  end

  def test_check_target_with_class_files

    class << @checker
      def change_list_finder(txn)
        ['A  parrot/target/com/Stuff.class']
      end
    end

    assert_not_nil @checker.execute('repo','txn'), "No error for path containing /target/../.class."

  end

  def test_bad_directory_only

    class << @checker
      def change_list_finder(txn)
        ['A  parrot/target/']
      end
    end

    assert_not_nil @checker.execute('repo','txn'), "No error for directory ending in target/."

  end

  def test_happy_path

    class << @checker
      def change_list_finder(txn)
        ['A  parrot/foo/bar/horse/mouse','A  parrot/boo/bar/horse/mousE']
      end
    end

    assert_nil @checker.execute('repo','txn'), "Why the error?"

  end

  def test_delete

    class << @checker
      def change_list_finder(txn)
        ['D  parrot/foo/bar/target/mouse', 'D  parrot/foo/bar/target/mouse/DoIt.class']
      end
    end

    assert_nil @checker.execute('repo','txn'), "Why the error for delete?"

  end

  # do not update .class files or anything under /target/
  def test_update

    class << @checker
      def change_list_finder(txn)
        ['U  parrot/target/com/Stuff.class']
      end
    end

    assert_not_nil @checker.execute('repo','txn'), "No error for updating path containing /target/../.class."

    class << @checker
      def change_list_finder(txn)
        ['_U  parrot/target/com/Stuff.class']
      end
    end

    assert_not_nil @checker.execute('repo','txn'), "No error for updating (_U) path containing /target/../.class."

  end

  def test_lib

    class << @checker
      def change_list_finder(txn)
        ['A  RegistryService/lib/blah.jar' ]
      end
    end
    # do not allow lib anywhere ...
    assert_not_nil @checker.execute('repo','txn'), "No error for path containing lib/."

    class << @checker
      def change_list_finder(txn)
        ['U  buildtools/lib/mouse.jar', 'D  parrot/foo/bar/target/mouse/DoIt.class']
      end
    end
    #... except in buildtools/lib
    assert_nil @checker.execute('repo','txn'), "Why the error for buildtools/lib?"
  end
  
end

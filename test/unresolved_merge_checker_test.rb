require 'test/unit'
require File.dirname(__FILE__)+"/../ruby/unresolved_merge_checker"

class UnresolvedMergeCheckerTestCase < Test::Unit::TestCase

  def setup
    @checker=Hooks::UnresolvedMergeChecker.new
    class << @checker
      def author_check(repo, revision_or_txn)
        "robby"
      end
      def change_list_finder(repo,txn)
        ['U   blah']
      end
    end
  end

  def test_no_check

    Hooks::UnresolvedMergeChecker.no_check_for :robby
    assert_nil(@checker.execute("repo", "txn"), "Should have returned nil")

    Hooks::UnresolvedMergeChecker.no_check_for "robby"
    assert_nil(@checker.execute("repo", "txn"), "Should have returned nil 2")
  end

  def test_bad_content

    class << @checker
      def file_content_looker(repo, txn, path)
        <<-EOV
<<<<<<< .mine
Change2
=======
Change1
>>>>>>> .r572
Top piece of bread
Mayonnaise
        EOV
      end
    end
    Hooks::UnresolvedMergeChecker.no_check_for :mcywas
    assert_not_nil(@checker.execute("repo", "txn"), "Should have returned not nil")
  end

  def test_good_content

    class << @checker
      def file_content_looker(repo, txn, path)
        <<-EOV
Change2
Change1
Top piece of bread
Mayonnaise
        EOV
      end
    end
    Hooks::UnresolvedMergeChecker.no_check_for :mcywas
    assert_nil(@checker.execute("repo", "txn"), "Should have returned nil for good content.")
  end
end
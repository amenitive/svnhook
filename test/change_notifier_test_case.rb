require 'test/unit'
require File.dirname(__FILE__)+"/../ruby/change_notifier"
  
class ChangeNotifierTestCase < Test::Unit::TestCase
  
  def setup
    @notifier=Hooks::ChangeNotifier.new
  end
  
  def test_check_changes
    
    changed_paths=["A   blah/", "U   buildtools2/stuff.rb", "D   buildtools2/foo/stuff.rb",
      "U   codebase2/bar/ignore.txt" ]
    config = Configuration.config[:paths_to_watch_for_changes]
    config << {:name=>'buildtools2/',
                           :authorized_to_checkin=>['bob','jill'], 
                           :notify_on_change=>['bob@macys.com', 'john@macys.com']}
    config << {:name=>'codebase2/',
                           :authorized_to_checkin=>['john', 'rob'],
                           :notify_on_change=>['john@macys.com', 'rob@macys.com']}
    block_invoked=false
    @notifier.check_changes(changed_paths, "joe") do |changed_watched_paths,watched_paths_by_user|
      
      assert_not_nil changed_watched_paths["buildtools2/"], "Did not detect buildtools2/"
      assert_equal 2, changed_watched_paths["buildtools2/"].size, "Did not add both buildtools2 to array"
      assert_not_nil changed_watched_paths["codebase2/"], "Did not detect codebase/"
      assert_equal 1, changed_watched_paths["codebase2/"].size, "Did not add 1 codebase to array"
      assert_nil changed_watched_paths["blah/"], "Detected blah/ unnecessarily"
      # check the other hash
      assert_equal 3, watched_paths_by_user.size, "Did not create 3 entries for second hash."
      assert_equal 1, watched_paths_by_user["bob@macys.com"].size, "Did not detect one path for bob"
      assert_equal 2, watched_paths_by_user["john@macys.com"].size, "Did not detect 2 paths for john"
      assert_equal 1, watched_paths_by_user["rob@macys.com"].size, "Did not detect 1 path for rob"
      
      block_invoked=true
    end
    assert block_invoked
    
  end

  def test_check_changes_with_regexp

    changed_paths=["A   relBranches-56.0.6/macys-apps/macys-war/src/main/xslt/xml/render.xml", 
                   "D   relBranches-56.0.6/macys-apps/macys-war/src/main/xslt/xml/page_render.xml",
                   "U   relBranches-57.0.20/macys-apps/macys-war/src/main/xslt/xml/shopping_cart.xml" ]
    Configuration.config[:paths_to_watch_for_changes]=[]
    config=Configuration.config[:paths_to_watch_for_changes]
    config << { :name=>/relBranches.*6/,
                :notify_on_change => [ 'bob@macys.com' ]}
    block_invoked=false
    @notifier.check_changes(changed_paths, "joe") do |changed_watched_paths, watched_paths_by_user|
      obj = changed_watched_paths[/relBranches.*6/]
      assert_equal 2, changed_watched_paths[/relBranches.*6/].size, "Did not detect 2 changed paths"
      assert_equal 1, watched_paths_by_user["bob@macys.com"].size, "Did not detect 1 path for rob"

      block_invoked=true
    end
    assert block_invoked

  end
  
  def test_send_mail
    
    hash={:author => 'janos', :date => '2009', :log=>'changed stuff', :rev=>"123"}
    paths_by_watched_path={"codebase/" => ['A   codebase/blah.txt'],
                           "buildtools/" => ["D   buildtools/ignoreme.txt","A   buildtools/hello.gif"] }
    users_by_watched_path={"bob@macys.com"  => ["buildtools/"], 
                           "john@macys.com" => ["buildtools/", "codebase/"],
                           "rob@macys.com"  => ["codebase/"]}
    #refactory this
    calls={}
    @notifier.send_mail(paths_by_watched_path, hash, users_by_watched_path) do |user_email,subject,body|
    
      if user_email=="john@macys.com"
        #assert subject.index("trunk")!=nil
        assert body.index("janos")!=nil
        assert body.index("2009")!=nil
        assert body.index("changed stuff")!=nil
        assert_not_nil body.index("A   codebase/blah.txt")
        assert_not_nil body.index("D   buildtools/ignoreme.txt")
        calls["john"]=""
      end
      if user_email=="bob@macys.com"
        assert_not_nil subject.index("buildtools/")
        assert body.index("janos")!=nil
        assert body.index("2009")!=nil
        assert body.index("changed stuff")!=nil
        assert_nil body.index("A   codebase/blah.txt")
        assert_not_nil body.index("D   buildtools/ignoreme.txt")
        calls["bob"]=""
      end
      if user_email=="rob@macys.com"
        assert_not_nil subject.index("codebase/")
        assert body.index("janos")!=nil
        assert body.index("2009")!=nil
        assert body.index("changed stuff")!=nil
        assert_not_nil body.index("A   codebase/blah.txt")
        assert_nil body.index("D   buildtools/ignoreme.txt")
        calls["rob"]=""
      end
      
    end
    assert_equal 3,calls.size, "Did not yield 3 times."
  end
  
  ##
  # Test whether branch is correctly calculated.
  
  def test_extract_branch

    assert_equal 'trunk', @notifier.extract_branch( ['A   trunk', 'a/b']), 'Did not resolve trunk.'
      
    assert_equal 'ab/cd/ef/', @notifier.extract_branch(['A   ab/cd/ef/gh/em', 'a/b']), 'Did not resolve top dirs.'
      
    assert_equal 'ab/cd/ef/', @notifier.extract_branch(['D   ab/cd/ef/Clazz.java', 'x/y']), 'Did not resolve top dirs.'
      
    assert_equal 'ab/cd/', @notifier.extract_branch(['G   ab/cd/Clazz.java', 'x/y']), 'Did not resolve 2 top dirs.'
      
    assert_equal 'ab/', @notifier.extract_branch(['U   ab/test.gif', 'x/y']), 'Did not resolve 1 top dir.'
  end

  def test_ignore_mcywas
      # reopen the class
      Hooks::ChangeNotifier.class_eval do
        def author_check(revision,repo)
          "mcywas"
        end
        def changed_paths_check(revision,repo)
          ["buildtools2/"]
        end
      end
      Configuration.config[:paths_to_watch_for_changes]=[]
      Configuration.config[:paths_to_watch_for_changes] << {:name=>'buildtools2/',
                           :notify_on_change=>['bob@macys.com', 'john@macys.com'],
                           :if_commit_user_matches => /joe/ }
      @notifier.notify_changes("repo","revision")
  end

  def test_ignorable_user
    assert((@notifier.ignorable_user?(/p139/, /p139mjh/, "p139mjh")), "Does not recognize exclusion")
    assert((not @notifier.ignorable_user?(/p139/, /p139kak/, "p139mjh")), "Does not recognize good inclusion and exclusion")

    assert(@notifier.ignorable_user?(/[^mario]/, /maria/, "maria"), "Does not recognize exclusion 1")
    
    assert((not @notifier.ignorable_user?(/[^mario]/, /joe/, "mariu")), "Does not recognize exclusion 2")
    assert(@notifier.ignorable_user?(/[^mario]/, /joe/, "mario"), "Does not recognize exclusion 3")

    assert((not @notifier.ignorable_user?(nil, nil, "user")), "Does not recognize nil expressions")

    # when only exclusion exists
    assert(@notifier.ignorable_user?(nil, /foo2/, "foo2"), "Does not recognize nil inclusion 1")
    assert(@notifier.ignorable_user?(nil, /[^janos]/, "foo2"), "Does not recognize nil inclusion")
    assert((not @notifier.ignorable_user?(nil, /[^janos]/, "janos")), "Does not recognize nil inclusion")

    # when only match exists
    assert(@notifier.ignorable_user?(/foo2/, nil, "fox"), "Does not recognize nil exclusion 1")
    assert((not @notifier.ignorable_user?(/[^janos]/, nil, "foo2")), "Does not recognize nil exclusion 2")
  end
end

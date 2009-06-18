## Super-class containing all the calls to Subversion
# 
# janos.mucsi@janosmucsi.net
# Ray Gebbie

module Hooks
  class SubversionLike

    def execute(repo, txn)
      ret=true
      if respond_to?("proceed_with_execute?")
        ret=proceed_with_execute?(repo, txn) # true if ok
      end
      if ret
        do_execute(repo, txn)
      else
        nil # nothing to do, all is well
      end
    end

    #placeholder
    def do_execute(repo, txn)
    end
    
    ## Make the call to Subversion to determine author (user) of changes.
    # revision_or_txn is a hash and must contain either the transaction (:txn) or revision (:revision) entry.
    #
    def author_check(repo, revision_or_txn)
      if revision_or_txn[:revision]
        ret=`svnlook author -r #{revision_or_txn[:revision]} #{repo}`.strip
      else
        ret=`svnlook author -t #{revision_or_txn[:txn]} #{repo}`.strip
      end
      # check for error message such as "svnlook: Can't open file 'myrepo/format': No such file or directory""
      raise ("Can not get author "+ret) if ret.start_with?("svnlook:")
      ret
    end

    # Make the call to Subversion to determine changed paths.
    # Change this so it supports revisions too

    def change_list_finder(repo,txn)
      `svnlook changed -t #{txn} #{repo}`.split("\n")
    end

    ## Extract path after change code and spaces.
    # change the full change info such as 'U   trunk/training-module/Sandwich.txt'
    #
    def change_to_path(change)
      /.+\s+(.*)/.match(change)[1]
    end

    ##
    # Adds the instance method 'proceed_with_execute?'.
    # There has to be a smarter way to do this.
    # I want to create a singleton method that would call the the instance method when
    # the check is required.
    #
    def self.no_check_for(users)
      @@users=users
     
      return if instance_methods(false).include?("proceed_with_execute?")

        ## this is not the best solution since this method is explicitly looked for
        class_eval <<-EOV
          def proceed_with_execute?(repo, txn)
            author=author_check(repo, {:txn=>txn})
            @logger.debug("Entering proceed_with_execute? with "+@@users.to_s+" committer="+author)
            case @@users
              when String
                @@users!=author
              when Symbol
                @@users.to_s!=author
              when Array
                true
              end
          end
        EOV
    end
  end
end
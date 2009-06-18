require File.dirname(__FILE__)+'/hook_logger'
require File.dirname(__FILE__)+'/configuration'

module Hooks
  
  ##
  # This class blocks checkins when certain file patterns are committed.

  class InvalidFileChecker

    include HookLogger
    
    def initialize
      init_log
    end

    ##
    # Return changed paths.
    def change_list_finder(txn)
      `svnlook changed -t #{txn} #{@repo}`.split("\n")
    end
    
    # Block /target/. We will correct this later if the need arises.
    # 
    def execute(repo, txn)
      @repo = repo
      authorize_changes(change_list_finder(txn))
    end
    ##
    # The main entry point into this class.
    # This method will return a message if any of the changes are not authorized.
    
    def authorize_changes(changed_paths)
      
      ret=nil
      bad_paths=[/\/target\//, /\/lib\//] # move this to config file
      @logger.debug("InvalidFileChecker authorize_changes " << changed_paths.to_s)
      changed_paths.each do |path|
        if /A|U/=~path[0,1] or /A|U/=~path[1,2]
          bad_paths.each do |bad_path|
            if (bad_path=~path) and not (/buildtools\/lib/=~path) and not (/ant\/lib/=~path)
              ret="Such directories or files under are not allowed to be checked in. " << path
              break
            end
          end
        end
        break if ret
      end
      ret
    end

  end
end

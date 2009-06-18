##
# This class checks for merge markers in files being committed.
# Author: janos.mucsi@janosmucsi.net
# Date: 2009

require File.dirname(__FILE__)+'/hook_logger'
require File.dirname(__FILE__)+'/subversion_like'

module Hooks
  ##
  #
  class UnresolvedMergeChecker < SubversionLike
    
    include HookLogger
    
    no_check_for :mcywas
    
    def initialize
      init_log
    end

    ##
    # Check each changed file for markers.
    # Return non-nil value when any marker is detected.
    def do_execute(repo, txn)
      msg=nil
      changes = change_list_finder(repo, txn)
      @logger.debug("UnresolvedMergeChecker paths=>" + changes.to_s)
      changes.each do |change|
        path=change_to_path(change)  # extract path after change code and spaces
        content = file_content_looker(repo, txn, path)
        @logger.debug("UnresolvedMergeChecker content=>" + content + "<<END")
        if unresolved_mark?(content)
          msg = "Unresolved merge in " +path + ". Please resolve and recommit."
          break
        end
      end
      msg
    end
    
  private
    ##
    # Return the contents of the file specified.

    def file_content_looker(repo, txn, path)
      @logger.debug("UnresolvedMergeChecker checking "+path)
      `svnlook cat -t #{txn} #{repo} #{path}`
    end

    ##
    # Returns a message when a marker is discovered in the file.
    def unresolved_mark?(content)
      content.include? "< .mine" or content.include? "> .r"
    end
  end 
end


require File.dirname(__FILE__)+'/hook_logger'
require File.dirname(__FILE__)+'/subversion_like'
  
module Hooks
  ##
  # Check whether the user is trying to mix in resources into Java 
  # directories.
  # The commit should be aborted when that happens.
  
  class MixedResourceChecker < SubversionLike
    include HookLogger

    attr_reader :rejected
    MCYWAS='mcywas'
    
    ##
    # Set up the two outside calls to Subversion.
    
    def initialize
      
      init_log
    end

    # Main entry point to the hook.
    # Return nill if no further action is to be taken.
    #
    def execute(repo,txn)
      # we do not check mcywas - it would be too time-consuming
      unless author_check(repo, {:txn=>txn})==MCYWAS
        if !check_for_mixed_resources(repo,txn)
            msg="Checking in non-Java files into /java directories is not allowed. " << rejected.to_s
            msg
        end
      else
          @logger.debug("MixedResourceChecker exiting for user mcywas")
          nil # logger.debug returns [] for some reason
      end
    end
    
    ##
    # Check whether the user is trying to mix in resources into Java 
    # directories.
    
    def check_for_mixed_resources(repo,txn)
      @logger.debug("MixedResourceChecker Entering repo"<< repo << " txn=" << txn)
      begin
        paths = change_list_finder(repo, {:txn => txn })
        @logger.debug("paths=" << paths.to_s)
        # for src/main/java or src/test/java folders the extension can not be
        # anything other than .java
        # Only check for additions - code A.
        @rejected = paths.reject do |changed_file|
          if changed_file[0,1]=='A'
            to_check=changed_file[1..-1].strip! # strip status code and spaces
            check_mixin_for_file(to_check)
          else
            true
          end
        end
        @logger.debug("MixedResourceChecker rejected " << rejected.to_s)
        @rejected.size==0
      rescue Exception => e
        # log the error at least
        @logger.error(e)
        raise
      end    
    end
    
    ##
    # Determine whether the file checked in in the java area has non-java
    # extension. Return true if the checked in file does not look like a mixed
    # in resource. html files are allowed in /java/ folders for javadocs.
    
    def check_mixin_for_file(to_check)
      @logger.debug("to_check #{to_check}") 
      patterns=['/java/']
      # regular expression would be better?
      patterns.each do |pattern|
        @logger.debug("pattern=" << pattern)
        to_check.scan(pattern) do |found|
          # isolate the extension 
          to_check.scan(/(.*\.)(.*)/) do |found, ext|
            @logger.debug("ext=#{ext}") 
            if(ext!='java' and ext!='html')
              return false
           end
          end
        end
      end
      return true
    end
  end
 end

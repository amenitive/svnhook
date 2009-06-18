require File.dirname(__FILE__)+'/hook_logger'
require File.dirname(__FILE__)+'/subversion_like'

module Hooks
  
  ##
  # This class ensures that two files whose names only differ in case can not
  # be checked into the same directory.
  
  class MixedCaseChecker < SubversionLike
    include HookLogger

    MCYWAS='mcywas'
    
    ##
    # Refactor so that all precommit and postcommit hooks reuse the call's result. 
    
    def initialize
      init_log

      @dir_hash={} #create a hash for each directory for siblings
    end

    ##
    # Return children under given directory.
    def subversion_tree(dir)
      `svnlook tree #{@repo} #{dir}`.split("\n")
    end

    # Main entry point to the hook.
    # Return nill if no further action is to be taken.
    #
    def execute(repo, txn)
      @logger.debug("MixedCaseChecker entering execute")
      # we do not check mcywas - it would be too time-consuming
      unless author_check(repo, {:txn=>txn})==MCYWAS
        check_mixed_case(repo, txn)
      else
	      @logger.debug("MixedCaseChecker exiting for user mcywas")
        nil
      end

    end

    ##
    # The main method in this class that calls Subversion and inspects the changes
    # for mixed-case files.
    # Return nil when no conflict is detected, return a string when there is one.

    def check_mixed_case(repo,txn)
      @logger.debug("MixedCaseChecker entering check_mixed_case")
      @repo=repo
      paths = change_list_finder(@repo, txn)
      ret=nil

      paths.each do |path|
        if path[0,1]=="A"
          changed_file=path[1..-1]
          changed_file.strip! # strip the change code
          ret=check_siblings(changed_file)
          if ret
            @logger.debug("check_mixed_case check_siblings rejected '#{ret}'")
            break
          end
        end
      end
      if ret
        ret="File(s) with same name and differing case can not be checked into the same directory: #{ret}"
      end
      ret
    end

    ##
    # Return array of top-level siblings of in the requested directory in the repository.    
    def siblings_for_dir(dir)
      children= subversion_tree(dir)
      children.shift # drop off the requested dir on first line such as trunk/codebase/
      siblings=children.select do |relative|
        not (/\s/=~relative[0,1]).nil? and (/\s/=~relative[1,2]).nil?
      end
      # at this point we only have the siblings with leading space, directories have trailing /
      siblings.collect! do |path|
        @logger.debug("siblings_for_dir processing '#{path}'")
        if directory?(path)
          path.strip!.chop! 
        else
          path.strip!
        end
      end
    end


    ##
    # Return nil if there is no conflict detected. Return file name when there are
    # files/directories with the same name with differing case.
    
    def check_siblings(path)
      ret=nil
      @logger.debug("check_siblings entering with '#{path}'")
        index=last_slash_index_for(path)
        @logger.debug("check_siblings index=" << index.to_s)
        if directory?(path)
          file=path[(index+1)..-2]
        else
          file=path[(index+1)..-1]
        end
        dir=path[0..index]
        @logger.debug("check_siblings dir='#{dir}' file='#{file}'")
        # make sure there is no such a file with differing case already
        if !@dir_hash[dir]
          start=Time.now
          @dir_hash[dir]= siblings_for_dir(dir)
          endtime=Time.now
          @logger.debug("MixedCaseChecker " << (endtime-start).to_s << "s. In #{dir}: " << @dir_hash[dir].join(","))
        end
        
        @dir_hash[dir].each do |file1|
          @logger.debug("check_siblings comparing with '#{file1}'")
          if file1.upcase==file.upcase
            ret=path
            break
          end
        end
        if !ret
          @dir_hash[dir] << file
        end

      ret
    end

    def last_slash_index_for(path)
      @logger.debug("last_slash_index_for entering with #{path}") 
      if directory?(path)
          # directories, last character is /
          index=path[0..-2].rindex("/")
        else
          # files
          index=path.rindex("/")
      end
    end

    def directory?(path)
      /.+?\/$/=~path
    end
    
  end
end

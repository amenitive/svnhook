require File.dirname(__FILE__)+'/hook_logger'
require File.dirname(__FILE__)+'/configuration'
  
module Hooks
  ##
  # Verifies whether the new module was created by an authorized user.
  
  class ModuleCreationChecker
    include HookLogger
    attr_accessor :change_list_finder
    attr_accessor :author_finder
    
    def initialize
      init_log
      @change_list_finder=Proc.new { |repo,txn| `svnlook changed -t #{txn} #{repo}`.split("\n") }
      @author_finder=Proc.new { |repo,txn| `svnlook author -t #{txn} #{repo}`.strip }
    end

    # Main entry point to the hook.
    #
    def execute(repo, txn)
      message=check_for_new_modules(repo,txn)
      message
    end

    ##
    # Return a message if a new module is about to be created with 
    # unauthorized user.
    # Return nil otherwise.
        
    def check_for_new_modules(repo,txn)
      ret=nil
      resolve_new_modules(repo,txn) do |author,new_modules|
        @logger.debug("ModuleCreationChecker author=#{author}<-")
        users=Configuration.config[:users_allowed_to_create_modules]
        if !users.include?("*") && !users.include?(author)
          ret=author << " is not allowed to create new modules\n" << new_modules.join(", ")
        end
      end
      ret
    end
    
    ##
    # Resolve and return all the modules that are new.
    
    def resolve_new_modules(repo,txn)
      
      changed_list=@change_list_finder.call(repo, txn)
      new_modules=changed_list.collect do |changed_file| 
        check_module changed_file do 
          changed_file
        end        
      end
      new_modules.compact!
      if new_modules.size>0
        author=@author_finder.call(repo,txn)
        yield(author,new_modules)
      end
    end
    
    ##
    # Invoke supplied block if the passed in path is a new module i.e. top-level
    # directory relative to a root
    # @param the full path with status code such as 'A  buildtools/hooks/' 
    
    def check_module(changed_file)
      @logger.debug("ModuleCreationChecker check_module with " << changed_file)
      if changed_file[0,1]=="A"
        # strip status code and whitespaces, find the last /
        to_check=changed_file[1..-2].strip
        @logger.debug("to_check " << to_check)
        index=to_check.rindex("/")
        if(index!=nil)
          if to_check[0..(index-1)]==Configuration.config[:module_root]
            @logger.debug("ModuleCreationChecker check_module detected new module " << to_check[index..-1])
            yield
          end
        end
      end
    end
  end
end

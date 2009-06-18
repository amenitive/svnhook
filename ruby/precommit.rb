start=Time.now

# Entry point for precommit.
require File.dirname(__FILE__)+'/hook_logger'
require File.dirname(__FILE__)+'/comment_checker'
require File.dirname(__FILE__)+'/mixed_resource_checker'
require File.dirname(__FILE__)+'/module_creation_checker'
require File.dirname(__FILE__)+'/mixed_case_checker'
require File.dirname(__FILE__)+'/invalid_file_checker'
require File.dirname(__FILE__)+'/unresolved_merge_checker'

class Precommit
  include HookLogger
  
  def initialize
    init_log
    @change_list_finder=Proc.new { |repo,txn| `svnlook changed -t #{txn} #{repo}`.split("\n") }
    @author_finder=Proc.new { |repo,txn| `svnlook author -t #{txn} #{repo}`.strip }
  end
  
  def execute(repo,txn)
    
    ##
    # Execute the checkers one after the other.
    # Refactor this to eliminate duplications.
    #
    begin
      
      change_list=@change_list_finder.call(repo,txn)
      
      @logger.debug("Precommit execute repo=#{repo} txn=#{txn} changes=" << change_list.to_s)
      # Hooks::ChangeAuthorizer,Hooks::MixedResourceChecker, Hooks::ModuleCreationChecker, Hooks::MixedCaseChecker, 
      hooks=[ Hooks::UnresolvedMergeChecker, 
              Hooks::CommentChecker,
              Hooks::ModuleCreationChecker,
              Hooks::InvalidFileChecker, 
              Hooks::MixedCaseChecker, 
              Hooks::MixedResourceChecker ]
      hooks.each do |hookclazz|
        hook=hookclazz.new
        @logger.debug("Precommit executes hook " << hook.to_s)
        msg=hook.execute(repo, txn)
        if msg!=nil
          @logger.debug("Precommit msg is " << msg)
          STDERR.puts(msg)
          exit(1)
        end
      end
    rescue SystemExit => e2
      exit(1)      
    rescue Exception => e
      @logger.error(e)
      @logger.error(e.backtrace.join("\n"))
      # do not exit, do not let hook bugs stop commits - let's err on that side...
    end
  end
  
  def print_time(start)
    @logger.info("Precommit total time " << (Time.now-start).to_s << " s")
  end
end

# process ARGV
repo = ARGV.shift
txn = ARGV.shift
raise "bad args" if !repo || !txn

precommit=Precommit.new
precommit.execute(repo,txn)
precommit.print_time(start)

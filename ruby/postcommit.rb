start=Time.now

# Entry point for postcommit.
require File.dirname(__FILE__)+'/symlink_verifier'
require File.dirname(__FILE__)+'/change_notifier'


class Postcommit
  include HookLogger
  
  def initialize
    init_log
  end
  
  def execute(repo,revision)
    #
    # Get the overview information.
    #

    hooks=[ Hooks::SymlinkVerifier,
            Hooks::ChangeNotifier ]
    hooks.each do |hookclazz|
      hook=hookclazz.new
      @logger.debug("Postcommit executes hook " << hook.to_s)
      hook.execute(repo, revision)
    end
  end
  
  def print_time(start)
    @logger.info("Postcommit total time " << (Time.now-start).to_s << " s")
  end
end
# process ARGV
repo = ARGV.shift
revision = ARGV.shift
raise "bad args" if !repo || !revision

postcommit=Postcommit.new
postcommit.execute(repo,revision)
postcommit.print_time(start)

require 'log4r'
include Log4r
require File.dirname(__FILE__)+'/configuration'
  
## Logger to track what the hooks are doing.
#
module HookLogger
  ##
  # Find a way not to have to call init_log explicitly in the including class.
  
  def HookLogger.included(mod)
  end

  ##
  # Initialize the log. 
  
  def init_log

    config = {
      "filename" => Configuration.config[:log_file] || "/svnhook.log",
      "trunc" => false
    }  

    @logger = Logger.new 'SvnHook'
    outputter=FileOutputter.new("SvnHook", config)
    outputter.formatter=Log4r::PatternFormatter.new({:pattern=>"[%l] %d %m"} )
    @logger.outputters = outputter
    @logger.level = Configuration.config[:log_level] ? eval(Configuration.config[:log_level]) : INFO
  end

end
require File.dirname(__FILE__)+'/hook_logger'
require File.dirname(__FILE__)+'/configuration'

module Hooks
  
  ##
  # Checks whether any of the changed paths are symbolic links.
  # If the path is a symlink it should not be allowed to be checked in.
  
  class SymlinkVerifier
    
    include HookLogger

    def initialize
      
      init_log
     
    end

    ##
    # Set up the two outside calls to Subversion.
    
    def change_checker
      `svnlook changed #{@repo} -r #{@revision}`.split("\n")
    end

    def attribute_checker(changed_file)
      `svnlook propget #{@repo} svn:special #{changed_file}`
    end

    def execute(repo, revision)
      @repo=repo
      @revision=revision
      check_sym_links
    end
    
    ##
    # Checks whether any of the changed paths are symbolic links.
    # Returns false if any of the changed files is a symlink.
      
    def check_sym_links
      
      @logger.debug("SymlinkVerifier Entering with repo=> #{@repo} rev #{@revision}")
      ret=true
      check_for_changes do |symlinks|
        author = `svnlook author #{@repo}`.strip
        date_committed = `svnlook date #{@repo}`
        log_message=`svnlook log #{@repo}`
        hash={:author => author, :date => date_committed, :log=>log_message}
        send_mail symlinks, hash do |subject,body|
          
          @logger.debug("SymlinkVerifier about to send mail " << body)
          recipients=[]
          recipients << Configuration.config[:symlink_notification_recipients]
          if author.size
            recipients << author.sub!("FEDERATED.FDS", "macys.com")
          end
          recipients.flatten!
          @logger.debug("SymlinkVerifier recipients " << recipients.to_s)
          Util::MailSender.instance.send_mail(recipients,subject, body)
          ret=false
        end
      end
      
      @logger.debug("SymlinkVerifier verified " << ret.to_s)
      ret
    end
    
    def check_for_changes
      # svn:special
      paths = change_checker

      # check each path
      ret = paths.reject do |changed_file|
        check_sym_link_for_file(changed_file)
      end
      if ret.size>0
        yield(ret)
      end
    end
    
    ##
    # Checks whether the specific path is a symbolic links.
    
    def check_sym_link_for_file(changed)
      changed_file=changed[1..-1]
      changed_file.strip!
      @logger.debug("SymlinkVerifier check_sym_link_for_file with changed_file=>" + changed_file)
      special_prop_value = attribute_checker(changed_file)
      @logger.debug("SymlinkVerifier check_sym_link_for_file prop=> #{special_prop_value}")
      if special_prop_value=="*" 
        
        @logger.debug("SymlinkVerifier check_sym_link_for_file link detected: "<< changed_file )
        return false
      end
      return true
    end
    
    ##
    # Assemble subject and body, then call the mail sender utility
      
    def send_mail(symlinks, hash)
      
      subject="Subversion notification. Symbolic links checked in!"
      
      body="The following symlinks have been checked in:\n\n" << symlinks.join("\n") 
      body << "\n\nuser: " << hash[:author]
      body << "\ndate: " << hash[:date]
      body << "comment: " << hash[:log] 
      body << "\n\nPlease remove the above link(s) from Subversion."
      yield(subject, body)
    end
  end
end

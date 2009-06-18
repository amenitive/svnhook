##
# This class sends out emails when any of the watched directories change.
# Author: janos.mucsi@janosmucsi.net
# Date: 2009

require File.dirname(__FILE__)+'/hook_logger'
require File.dirname(__FILE__)+'/mail_sender'  
require File.dirname(__FILE__)+'/configuration'

module Hooks
  ##
  # This class sends email notifications when certain directories are affected
  # by checkins.
  class ChangeNotifier
    
    include HookLogger
    
    def initialize
      init_log
      @subject_prefix="Notification of commit in branch "
      @body_prefix="The following files/directories have been modified:\n\n"
    end

    # Make the call to Subversion to determine author (user) of changes.
    #
    def author_check(revision,repo)
      `svnlook author -r #{revision} #{repo}`
    end

    # Make the call to Subversion to determine changed paths.
    #
    def changed_paths_check(revision,repo)
      `svnlook changed -r #{revision} #{repo}`.split("\n")
    end

    def execute(repo, revision)
      notify_changes(repo,revision)
    end
    
    ##
    # The main entry point into this class.
    # This method makes the calls to Subversion to find out what happened
    # and then triggers email sending.
    
    def notify_changes(repo,revision)
      
      @logger.debug("ChangeNotifier Entering with repo="<< repo)
      @logger.debug("ChangeNotifier Entering with revision="<< revision)
      begin
        author = author_check(revision,repo)
        @logger.debug("Author is #{author}")

        paths = changed_paths_check(revision, repo)
        @logger.debug("svnlook changed returned " << paths.join(" "))
        
        check_changes(paths, author) do |watched_paths,paths_by_users|

          date_committed = `svnlook date -r #{revision} #{repo}`
          log_message=`svnlook log -r #{revision} #{repo}`
          hash={:author => author, :date => date_committed, :log=>log_message, :rev=>revision}
          # send email only to interested parties
          threads=[]
          send_mail watched_paths, hash, paths_by_users do |user_email, subject,body|
            t1 = Thread.new do
              @logger.debug("ChangeNotifier about to send mail for " << body)
              Util::MailSender.instance.send_mail(user_email, subject, body)
            end
            threads << t1
          end
          threads.each do |thread|
            thread.join
            @logger.debug("ChangeNotifier joined " << thread.to_s)
          end
        end
      rescue Exception => e
        # log the error at least
        @logger.error(e)
        raise
      end
    end
    
    ##
    # Check the array of files for the paths we are watching.
    # Produce a hash with changed paths, keyed with watched_paths.
    #
    def check_changes(paths, user)
      paths_by_watched_path={}
      paths_by_users={}
      # look for each path as well
      paths_to_watch=Configuration.config[:paths_to_watch_for_changes]

      paths_to_watch.each do |pathtowatch|
        next if ignorable_user?(pathtowatch[:if_commit_user_matches],pathtowatch[:if_commit_user_not_matches], user)
        paths.each do |path|
          path.scan(pathtowatch[:name]) do |w|
            watched_path=pathtowatch[:name]
            paths_by_watched_path[watched_path] ||= [] #make sure entry exists
            paths_by_watched_path[watched_path] << path
            # build the hash keyed by email, containing watched paths
            pathtowatch[:notify_on_change].each do |email|
              paths_by_users[email] ||= []
              paths_by_users[email] << watched_path if !paths_by_users[email].include?(watched_path)  
            end
            
          end 
        end
      end
      if paths_by_watched_path.size>0 
        yield(paths_by_watched_path,paths_by_users)
      end
    end
    
    ##
    # Assemble subject and body, for each user, then call the mail sender utility.
    # @param changed_watched_paths hash of changed paths, keyed by watched paths
    # @param hash containing :author,:date and :log
    # @param paths_by_users watched paths by users
    
    def send_mail(changed_watched_paths, hash, paths_by_users)
      
      # send one email for email address
      paths_by_users.keys.each do |user_email|
        subject=nil
        body=String.new @body_prefix
        
        # merge in the changed paths this user is interested in
        paths_by_users[user_email].each do |watched_path|
          
          if changed_watched_paths[watched_path]
            
            body << "\n" << changed_watched_paths[watched_path].join("\n")
            # take any to generate the branch
            if !subject
              
              subject= String.new @subject_prefix
              subject << extract_branch(changed_watched_paths[watched_path])
              subject << " by user "
              subject << hash[:author]
	      @logger.debug("Subject is="<< subject)
            end
          end  
        end
                
        body << "\n\nuser: " << hash[:author]
        body << "revision: " << hash[:rev]
        body << "\ndate: " << hash[:date]
        body << "comment: " << hash[:log] 
        
        yield(user_email, subject, body)
       
      end
    end

    ##
    # Pick 'trunk' or first 3 top-level directories
    # Uses changed_watched_paths to determine "branch"
    
    def extract_branch(changed_watched_paths)
      
		first_path=changed_watched_paths[0][1..-1]
		first_path.strip!
		@logger.debug("first_path is="<< first_path)
    
		ret=''
		if first_path =~ /trunk/
			@logger.debug("returning="<< "trunk")
			return "trunk"
		end
		if first_path =~ /ceDev/
			@logger.debug("returning="<< "ceDev")
			return "ceDev"
		end
       ret=''
       for i in 1..2
		@logger.debug("i="<< i)
         if(first_path.length>ret.length)
           index=first_path.index('/', ret.length)
           if(index!=nil)
             ret << first_path[ret.length .. index]
           else
             break
           end
         end
       end
		@logger.debug("returning="<< ret)
       return ret

	end

    # Return true if the regular expression matches the user and the exclusion expression does not match.
    # Return false otherwise.
    # regexp, regexp, string
    # Check out the tests for more use cases.
    #
    # Example:
    # Arguments /j/, /janos/, "janos" would result in true being returned.
    #
    def ignorable_user?(expression, not_match_expression, user)
      @logger.debug("ignorable_user? #{user} " << expression.to_s << not_match_expression.to_s)
      if (expression and not_match_expression)
        inc=!!(expression=~user)
        exc=!!(not_match_expression=~user)
        return ((!inc) or (inc && exc))
      end
      return (!(expression=~user)) if expression
      return (!!(not_match_expression=~user)) if not_match_expression

      false # both are nil
    end
  end 
end


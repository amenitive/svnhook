require File.dirname(__FILE__)+'/hook_logger'

module Hooks
  class CommentChecker
    
    include HookLogger
    attr_accessor :comment
    attr_accessor :comment_retriever
    
    def initialize
      init_log
      @comment_retriever=Proc.new {|repo,txn| `svnlook log -t #{txn} #{repo}`}
    end

        # Main entry point to the hook.
    #
    def execute(repo, txn)
      message=verify_comment(repo, txn)
      message
    end
          
    ##
    # Call svnlook log to see what the transaction comment is.
    def verify_comment(repo, txn)
      @logger.debug("CommentChecker Entering with repo=>" + repo+" txn=>"+txn)
      @comment = @comment_retriever.call(repo, txn).strip!
    
      checkComment
    end
    
    ##
    # Checks whether the comment has at least two words.
    # Call this with a clean comment (line feed, etc. has been removed) 
    
    def checkComment
      msg=nil
      @logger.debug("CommentChecker Comment=>"+@comment)
      if @comment!='added' && @comment!='removed'
        words=@comment.split(" ")
        if words.size<2
          msg="Please include a meaningful comment. Commit will not proceed, you need to recommit."
        end
      end
      msg
    end

  end
end

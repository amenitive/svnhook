

class B 
  def self.retrieve_users
    #puts instance_methods(false).include?(:proceed_with_execute?).to_s
    puts instance_methods(false).to_s
   class_eval <<-EOV
      def proceed_with_execute?(repo, txn)
        puts "doing it"
      end
   EOV
    #puts instance_methods(false).include?(:proceed_with_execute?).to_s
  puts instance_methods(false).to_s
  end

end

class C < B

end

C.retrieve_users
C.retrieve_users
C.retrieve_users


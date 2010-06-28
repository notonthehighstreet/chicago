module Chicago
  module ETL

    class TaskInvocation < Sequel::Model
      set_dataset :etl_task_invocations
      many_to_one :etl_batch

      # Executes a block of code.
      #
      # Sets the state to "Error" and re-raises any exception that the
      # block of code raises.
      def perform
        raise RuntimeError.new("The task #{name} in batch #{batch_id} has already run") if finished?
        update(:state => "Started", :attempts => attempts + 1)
        begin
          yield
        rescue Exception => e
          update(:state => "Error")
          raise e
        end
        update(:state => "Finished", :finished_at => Time.now)
      end

      # Returns true if this task has finished running successfully.
      def finished?
        state == "Finished"
      end
    end

  end
end

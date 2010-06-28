require 'FileUtils'

module Chicago
  module ETL
    # A particular "run" of the ETL process.
    #
    # All ETL tasks should be executed in the context of a Batch.
    #
    # A batch creates a temporary directory under tmp/batches/:id
    # where it stores various logs and extract files.
    class Batch < Sequel::Model
      set_dataset :etl_batches

      # Starts a new batch, or resumes a previous batch that ended in
      # an error state.
      def self.start
        if last_batch.nil? || last_batch.finished?
          create
        else
          last_batch
        end
      end
      
      # Returns the last batch run, or nil if this is the first batch.
      def self.last_batch
        order(:started_at).last
      end

      # Returns the directory files & batch logs will be written to.
      def dir
        @dir ||= File.join(Chicago.project_root, "tmp", "batches", id.to_s)
      end

      # Finishes this batch, and sets the finished_at timestamp.
      def finish
        update(:state => "Finished", :finished_at => Time.now)
      end

      # Sets this batch to the Error state.
      def error
        update(:state => "Error")
      end

      # Returns true if this batch is finished.
      def finished?
        state == "Finished"
      end

      # Returns true if in the error state
      def in_error?
        state == "Error"
      end

      def after_create # :nodoc:
        FileUtils.mkdir_p dir
      end
    end
  end
end

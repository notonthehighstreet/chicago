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
      
      # Returns the directory files & batch logs will be written to.
      def dir
        @dir ||= File.join(Chicago.project_root, "tmp", "batches", id.to_s)
      end

      # Finishes this batch, and sets the finished_at timestamp.
      def finish
        update(:finished_at => Time.now)
      end

      def after_create # :nodoc:
        FileUtils.mkdir_p dir
      end
    end
  end
end

require 'FileUtils'

module Chicago
  module ETL
    class Batch < Sequel::Model
      set_dataset :etl_batches
      
      def dir
        @dir ||= File.join(Chicago.project_root, "tmp", "batches", id.to_s)
      end

      def after_create
        FileUtils.mkdir_p dir
      end
    end
  end
end

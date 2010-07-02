module Sequel
  class Dataset
    def insert_replace
      clone(:replace => true)
    end
  end
end

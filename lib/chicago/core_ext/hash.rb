class Hash
  # Ensure AcitveSupport related methods are present if ActiveSupport
  # not loaded.
  #
  # Code taken from ActiveSupport.
  unless method_defined?(:symbolize_keys)
    def symbolize_keys
      dup.symbolize_keys!
    end
    
    def symbolize_keys!
      keys.each do |key|
        self[(key.to_sym rescue key) || key] = delete(key)
      end
      self
    end
  end
end

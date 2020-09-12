module Bhm
  module Utils
    module_function

    # Transform a stringified module to an accessible hash key
    # Assume we want symbols by default
    def transform_module_casing(module_name, key_casing, key_type)
      transformed_module = case key_casing
      when :lower_snake
        module_name.to_s.gsub(/[A-Z]/) { |mtch| "_" + mtch.downcase }.sub(/^_/, "")
      when :lowerCamel
        module_name.to_s.sub(/^./) { |first_char| first_char.downcase }
      when :UpperCamel
        module_name.to_s
      when :SCREAMING_SNAKE
        module_name.to_s.gsub(/[A-Z]/) { |mtch| "_" + mtch }.upcase.sub(/^_/, "")
      else
        fail ArgumentError, "invalid casing provided: #{key_casing.inspect}"
      end

      # Coerce into symbols if key_type was explicitly passed as `nil`
      key_type ||= :symbols
      transformed_module = transformed_module.to_sym if key_type == :symbols
      transformed_module
    end

    # Take a hash which includes Bhm::Validation & traverse upward nested module which also includes Validation
    def traverse_ancestors(hash)
      all = hash.singleton_class.included_modules.select { |mod| mod.include? Validation }
      current = all.first
      traversed_ancestors = []

      while current.include?(Validation)
        as_ary = current.to_s.split("::")
        # Truncating the final ::(string), then rejoin

        # Now that we have the module in question, transform the case using the module's method, if it has it defined
        accessed_key = as_ary[-1]

        # HACK: make an instance which extends the current module to use its #default_key values
        transformed_key = -> do
          hack = {}.extend(current)
          key_casing = hack.default_key_case
          key_type = hack.default_key_type

          transform_module_casing(accessed_key, key_casing, key_type)
        end.call

        traversed_ancestors << transformed_key

        last = current
        current = Object.const_get(as_ary[0, (as_ary.length - 1)].join("::"))
      end

      # Array
      # idx 0 is an array of the module names as formatted strings
      # idx 1 is the apex, highest "entry" module
      [traversed_ancestors, last]
    end
  end
end

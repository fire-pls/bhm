module Hsah
  module Utils
    module_function

    # Transform a stringified module to an accessible hash key
    def transform_module_casing(module_name, key_casing)
      case key_casing
      when :lowerCamelCase
        module_name.to_s.sub(/^./) { |first_char| first_char.downcase }
      when :UpperCamelCase
        module_name.to_s
      when :lower_snake_case
        module_name.to_s.gsub(/[A-Z]/) { |mtch| "_" + mtch.downcase }.sub(/^_/, "")
      else
        fail ArgumentError, "invalid casing provided: #{key_casing}"
      end
    end

    # Take a hash which includes HashValidation & traverse upward nested module which also includes Validation
    def traverse_ancestors(hash)
      all = hash.singleton_class.included_modules.select { |mod| mod.include? Hsah::Validation }
      current = all.first
      traversed_ancestors = []

      while current.include?(Hsah::Validation)
        as_ary = current.to_s.split("::")
        # Truncating the final ::(string), then rejoin

        # Now that we have the module in question, transform the case using the module's method, if it has it defined
        accessed_key = as_ary[-1]

        # HACK: make an instance which extends the current module to use its :key_casing
        transformed_key = -> do
          transform_module_casing(accessed_key, {}.extend(current).key_casing)
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

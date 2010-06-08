# encoding: utf-8
module Mongoid #:nodoc:
  module Associations #:nodoc:
    class EmbedsMany < Proxy
      def initialize_with_custom_fields(parent, options, target_array = nil)
        if custom_fields?(parent, options.name)
          options = options.clone # 2 parent instances should not share the exact same option instance
          
          custom_fields = parent.send(:"ordered_#{custom_fields_association_name(options.name)}")
        
          klass = options.klass.to_klass_with_custom_fields(custom_fields)
        
          options.instance_eval <<-EOF
            def klass=(klass); @klass = klass; end
            def klass; @klass || class_name.constantize; end
          EOF
        
          options.klass = klass
        end
        
        initialize_without_custom_fields(parent, options, target_array)
      end
      
      alias_method_chain :initialize, :custom_fields
      
      def build_with_custom_field_settings(attrs = {}, type = nil)
        document = build_without_custom_field_settings(attrs, type)
        
        if @association_name.ends_with?('_custom_fields')
          document.class_eval <<-EOV
            self.associations = {} # prevent associations to be nil
            embedded_in :#{@parent.class.to_s.underscore}, :inverse_of => :#{@association_name}
          EOV
          
          document.send(:set_unique_name!)
          document.send(:set_alias)
        end
        document
      end
      
      alias_method_chain :build, :custom_field_settings
    end
  end
end
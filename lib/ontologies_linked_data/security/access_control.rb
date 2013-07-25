require 'set'

module LinkedData::Security
  module AccessControl
    DEFAULT_OWNER_ATTRIBUTES = [:creator]

    def read_restricted?
      based_on = (self.class.access_control_settings[:read_restriction_based_on] || []).first
      return read_restricted_based_on?(based_on) if based_on

      restricted_proc = (self.class.access_control_settings[:read_restriction] || []).first
      if restricted_proc.is_a?(Proc)
        restricted = restricted_proc.call(self)
      elsif restricted_proc.is_a?(Symbol)
        restricted = self.send(restricted_proc)
      else
        restricted = restricted_proc || false
      end
      restricted
    end

    def readable?(user)
      return true if user.admin?
      return true unless read_restricted?
      allowed_user_ids = allowed_user_ids(:read_access)
      allowed_user_ids.include?(user.id)
    end

    def writable?(user)
      return true if user.admin?
      allowed_user_ids = allowed_user_ids(:write_access)
      allowed_user_ids.include?(user.id)
    end

    private

    def read_restricted_based_on?(based_on)
      if based_on.is_a?(Proc)
        instance_to_base_on = based_on.call(self)
        restricted = instance_to_base_on.read_restricted?
      elsif based_on.is_a?(LinkedData::Models::Base)
        restricted = based_on.read_restricted?
      elsif based_on.is_a?(Symbol)
        instance_to_base_on = based_on.send(based_on)
        restricted = instance_to_base_on.read_restricted?
      else
        restricted = false
      end
      restricted
    end

    def allowed_user_ids(settings)
      target = based_on? ? based_on_target : self
      attributes = target.class.access_control_settings[settings].dup
      attributes = attributes + DEFAULT_OWNER_ATTRIBUTES
      user_ids = Set.new
      attributes.each do |attr|
        next unless target.respond_to?(attr)
        users = target.send(attr)
        users = users.is_a?(Array) ? users : [users]
        users.each {|u| user_ids << u.id}
      end
      user_ids
    end

    def based_on?
      not self.class.access_control_settings[:read_restriction_based_on].empty?
    end

    def based_on_target
      based_on = (self.class.access_control_settings[:read_restriction_based_on] || []).first

      if based_on.is_a?(Proc)
        target = based_on.call(self)
      elsif based_on.is_a?(LinkedData::Models::Base)
        target = based_on
      elsif based_on.is_a?(Symbol)
        target = based_on.send(based_on)
      end
      target
    end

    # Internal

    def self.included(base)
      base.extend(ClassMethods)
    end

    def self.store_settings(cls, type, setting)
      cls.access_control_settings ||= {}
      cls.access_control_settings[type] = Set.new(setting)
    end

    module ClassMethods
      attr_accessor :access_control_settings

      # Methods with these names will be created
      # for each entry, allowing values to be
      # stored on a per-class basis
      SETTINGS = [
        :read_restriction,
        :read_restriction_based_on,
        :read_access,
        :write_access,
        :access_control_load
      ]

      ##
      # Write methods on the class based on settings names
      SETTINGS.each do |method_name|
        define_method method_name do |*args|
          AccessControl.store_settings(self, method_name, args)
        end
      end

      ##
      # Gets called by each class that inherits from this module
      # or classes that include this module
      def inherited(cls)
        super(cls)
        SETTINGS.each do |type|
          AccessControl.store_settings(cls, type, Set.new)
        end
      end
    end
  end
end
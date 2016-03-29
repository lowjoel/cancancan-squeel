# frozen_string_literal: true
class CanCanCan::Squeel::ActiveRecordDisabler
  ::CanCan::ModelAdapters::ActiveRecord4Adapter.class_eval do
    def self.for_class?(_)
      false
    end
  end
end

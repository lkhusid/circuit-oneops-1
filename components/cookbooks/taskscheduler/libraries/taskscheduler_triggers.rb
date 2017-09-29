require 'ostruct'
require_relative "ext_string"
require_relative "ext_kernel"


module OO
  class TaskScheduler
    class Triggers

      silence_warnings do
        TRIGGER_TYPE = {
          'once'   => 1,
          'daily'  => 2,
          'weekly' => 3
        }

        TRIGGERS = {
          'once'   => 'trigger_once',
          'daily'  => 'trigger_daily',
          'weekly' => 'trigger_weekly'
        }

        WEEKLY_TASK = {
          'Sunday'     => 0x1,
          'Monday'     => 0x2,
          'Tuesday'    => 0x4,
          'Wednesday'  => 0x8,
          'Thursday'   => 0x10,
          'Friday'     => 0x20,
          'Saturday'   => 0x40,
        }

        ATTRIBUTES = {
          'once'   => [],
          'daily'  => ['days_interval'],
          'weekly' => ['days_of_week', 'weeks_interval']
        }
      end

      def initialize task_definition
        @task_triggers = task_definition.Triggers
      end

      def remove_triggers
        @task_triggers.Remove(1) if @task_triggers.Count > 0
      end

      def create_triggers trigger_type
        @task_triggers.Create(trigger_type)
      end

      def get_current_triggers
        @task_triggers.Item(1)
      end

      def trigger_once triggers_attributes, current_trigger
        assign_date_and_time triggers_attributes, current_trigger
      end

      def trigger_daily triggers_attributes, current_trigger
        assign_date_and_time triggers_attributes, current_trigger
        current_trigger.DaysInterval = triggers_attributes['days_interval'] if triggers_attributes.has_key? 'days_interval'
      end

      def trigger_weekly triggers_attributes, current_trigger
        assign_date_and_time triggers_attributes, current_trigger
        current_trigger.DaysOfWeek = WEEKLY_TASK[triggers_attributes['days_of_week']] if triggers_attributes.has_key? 'days_of_week'
        current_trigger.WeeksInterval = triggers_attributes['weeks_interval'] if triggers_attributes.has_key? 'weeks_interval'
      end

      def assign_date_and_time triggers_attributes, current_trigger
        start_day = triggers_attributes.has_key?('start_day') ? triggers_attributes['start_day'] : current_trigger.StartBoundary.split('T').first
        start_time = triggers_attributes.has_key?('start_time') ? triggers_attributes['start_time'] : current_trigger.StartBoundary.split('T').last
        start_boundary =   start_day + 'T' + start_time
        current_trigger.StartBoundary = start_boundary unless start_boundary == current_trigger.StartBoundary
      end

      def attributes
        attributes = {}
        triggers = get_current_triggers
        attributes['type'] = triggers.Type
        start_boundary = triggers.Startboundary
        attributes['start_day'] = start_boundary.split('T').first unless start_boundary.nil?
        attributes['start_time'] = start_boundary.split('T').last unless start_boundary.nil?
        ATTRIBUTES[TRIGGER_TYPE.key(triggers.Type)].each do | property |
          attributes[property] = triggers.send(property.camelize)
        end

        attributes['type'] = TRIGGER_TYPE.key(attributes['type'])
        attributes['days_of_week'] = WEEKLY_TASK.key(attributes['days_of_week']) if attributes.has_key? 'days_of_week'

        OpenStruct.new(attributes)
      end

      def assign_attributes triggers_attributes
        if triggers_attributes.has_key? 'type'
          remove_triggers
          current_trigger = create_triggers TRIGGER_TYPE[triggers_attributes['type']]
        else
          current_trigger = get_current_triggers
        end

        triggers_attributes['type'] = TRIGGER_TYPE.key current_trigger.Type
        self.send(TRIGGERS[triggers_attributes['type']], triggers_attributes, current_trigger)
      end

    end
  end
end

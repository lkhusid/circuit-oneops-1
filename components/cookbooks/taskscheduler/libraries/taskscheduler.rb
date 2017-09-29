require 'win32ole'

require_relative "taskscheduler_actions"
require_relative "taskscheduler_general"
require_relative "taskscheduler_settings"
require_relative "taskscheduler_triggers"
require_relative "taskscheduler_principal"


module OO
  class TaskScheduler
      TASK_VALIDATE_ONLY = 0x1
      TASK_CREATE = 0x2
      TASK_UPDATE = 0x4
      TASK_CREATE_OR_UPDATE = 0x6
      TASK_DISABLE = 0x8

      TASK_LOGON_NONE = 0
      TASK_LOGON_PASSWORD = 1
      TASK_LOGON_S4U = 2
      TASK_LOGON_INTERACTIVE_TOKEN = 3
      TASK_LOGON_GROUP = 4
      TASK_LOGON_SERVICE_ACCOUNT = 5
      TASK_LOGON_INTERACTIVE_TOKEN_OR_PASSWORD = 6


      def initialize(task_name)
        @schedule_task_service = WIN32OLE.new('Schedule.Service')
        @schedule_task_service.Connect
        @root_folder = @schedule_task_service.GetFolder('\\')
        @task_name = task_name
        @task_definition = task_exists? ? get_task_definition : get_new_task_definition
      end

      def task_root_folder
        @root_folder.GetTasks(0).each.select { |registered_task| registered_task.Name == @task_name }
      end

      def get_task_definition
        @root_folder.GetTask(@task_name).Definition
      end

      def get_new_task_definition
        @schedule_task_service.NewTask(0)
      end

      def task_exists?
        task = task_root_folder
        !task.empty?
      end

      def get_task_status
        @root_folder.GetTask(@task_name).State
      end

      def start
        task = task_root_folder
        task[0].run(nil) unless task.empty?
      end

      def stop
        task = task_root_folder
        task[0].stop(nil) unless task.empty?
      end

      def general
        General.new(@task_definition).attributes
      end

      def actions
        Actions.new(@task_definition).attributes
      end

      def triggers
        Triggers.new(@task_definition).attributes
      end

      def settings
        Settings.new(@task_definition).attributes
      end

      def principal
        Principal.new(@task_definition).attributes
      end


      private :get_new_task_definition, :get_task_definition

      def create_task task_attributes
        assign_attributes_to_task(task_attributes)
      end

      def update_task task_attributes
        if task_exists?
          assign_attributes_to_task(task_attributes)
        end
      end

      def delete
        @root_folder.DeleteTask(@task_name, 0) if task_exist?(@task_name)
      end

      def assign_attributes_to_task(task_attributes)

        actions_attributes = task_attributes['actions']
        settings_attributes = task_attributes['settings']
        general_attributes = task_attributes['general']
        triggers_attributes = task_attributes['triggers']
        principal_attributes = task_attributes['principal']

        Actions.new(@task_definition).assign_attributes(actions_attributes)
        Settings.new(@task_definition).assign_attributes(settings_attributes)
        General.new(@task_definition).assign_attributes(general_attributes)
        Triggers.new(@task_definition).assign_attributes(triggers_attributes)
        Principal.new(@task_definition).assign_attributes(principal_attributes)

        @root_folder.RegisterTaskDefinition(
          @task_name,
          @task_definition,
          TASK_CREATE_OR_UPDATE,
          task_attributes['authentication']['user_id'],
          task_attributes['authentication']['password'],
          TASK_LOGON_INTERACTIVE_TOKEN_OR_PASSWORD
        )

      end
  end
end

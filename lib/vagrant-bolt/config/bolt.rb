require 'vagrant-bolt/config/global'

class VagrantBolt::Config::Bolt < VagrantBolt::Config::Global

  # @!attribute [rw] task
  #   @return [String] The name of task to run
  #   @since 0.0.1
  attr_accessor :task

  # @!attribute [rw] plan
  #   @return [String] The name of plan to run
  #   @since 0.0.1
  attr_accessor :plan

  # @!attribute [rw] parameters
  #   @return [Hash] The paramater hash for the task or plan
  #   @since 0.0.1
  attr_accessor :parameters

  # @!attribute [rw] nodes
  #   @return [Array[string]] The nodes to run the task or plan on. This defaults to the current node.
  #   @since 0.0.1
  attr_accessor :nodes

  def initialize
    super
    @task       = UNSET_VALUE
    @plan       = UNSET_VALUE
    @parameters = UNSET_VALUE
    @nodes      = UNSET_VALUE
  end

  def finalize!
    super
    @task       = nil if @task == UNSET_VALUE
    @plan       = nil if @plan == UNSET_VALUE
    @parameters = {} if @parameters == UNSET_VALUE
    @nodes      = nil if @nodes == UNSET_VALUE
  end

  def validate(machine)
    global_errors = super
    errors = []

    if @task.nil? && @plan.nil?
      errors << I18n.t('vagrant-bolt.config.bolt.errors.no_task_or_plan')
    elsif !@task.nil? && !@plan.nil?
      errors << I18n.t('vagrant-bolt.config.bolt.errors.task_and_plan_configured',
                        :task => @task,
                        :plan => @plan,
                      )
    end

    errors |= global_errors.values.flatten
    {"Bolt" => errors }
  end
end

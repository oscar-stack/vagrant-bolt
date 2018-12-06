# frozen_string_literal: true

shared_examples 'provider/virtualbox' do |provider, options|
  include_context "acceptance"
  let(:extra_env) { options[:env_vars] }

  before do
    environment.skeleton('base')
    assert_execute('vagrant', 'box', 'add', 'box', options[:box])
  end

  after do
    execute('vagrant', 'destroy', '-f', log: false)
  end

  describe 'bolt provisioner' do
    before(:each) do
      environment.skeleton('provisioner')
      @result = assert_execute('vagrant', 'up', "--provider=#{provider}")
    end

    it 'runs a task, plan, and command' do
      expect(@result.exit_code).to eq(0)
      expect(@result.stdout).to match(%r{Bolt: Running bolt command locally: \/[^\ ]+bolt task run 'facts'})
      expect(@result.stdout).to match(%r{Bolt: Running bolt command locally: \/[^\ ]+bolt plan run 'facts'})
      expect(@result.stdout).to match(%r{Bolt: Running bolt command locally: \/[^\ ]+bolt command run})
      expect(@result.stdout.scan(%r{Successful on 1 node}).size).to eq(3)
    end
  end

  describe 'bolt trigger' do
    before(:each) do
      environment.skeleton('trigger')
      @result = assert_execute('vagrant', 'up', "--provider=#{provider}")
    end

    it 'runs a task, plan, and command' do
      expect(@result.exit_code).to eq(0)
      expect(@result.stdout).to match(%r{Bolt: Running bolt command locally: \/[^\ ]+bolt task run 'facts'})
      expect(@result.stdout).to match(%r{Bolt: Running bolt command locally: \/[^\ ]+bolt plan run 'facts'})
      expect(@result.stdout).to match(%r{Bolt: Running bolt command locally: \/[^\ ]+bolt command run})
      expect(@result.stdout.scan(%r{Successful on 1 node}).size).to eq(3)
    end
  end

  describe 'bolt command' do
    before(:each) do
      @result = assert_execute('vagrant', 'up', "--provider=#{provider}")
    end

    it 'runs a task, plan, and command' do
      expect(@result.exit_code).to eq(0)
      result = assert_execute('vagrant', 'bolt', 'task', 'run', 'facts', '-n', 'server')
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to match(%r{Bolt: Running bolt command locally: '\/[^\ ]+bolt' 'task' 'run' 'facts'})
      expect(result.stdout.scan(%r{Successful on 1 node}).size).to eq(1)
      result = assert_execute('vagrant', 'bolt', 'plan', 'run', 'facts', '-n', 'server')
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to match(%r{Bolt: Running bolt command locally: '\/[^\ ]+bolt' 'plan' 'run' 'facts'})
      expect(result.stdout.scan(%r{Successful on 1 node}).size).to eq(1)
      result = assert_execute('vagrant', 'bolt', 'command', 'run', 'hostname', '-n', 'server')
      expect(result.exit_code).to eq(0)
      expect(result.stdout).to match(%r{Bolt: Running bolt command locally: '\/[^\ ]+bolt' 'command' 'run'})
      expect(result.stdout.scan(%r{Successful on 1 node}).size).to eq(1)
    end
  end

  describe 'bolt advanced use cases' do
    before(:each) do
      environment.skeleton('advanced')
      @result = assert_execute('vagrant', 'up', "--provider=#{provider}")
    end

    # This is a mashup of many tests combined. In an effort to cut down the time, this tests many items.
    it 'runs bolt' do
      # Ensure the machines came online
      expect(@result.exit_code).to eq(0)
      ## Allnodetest
      # Check for root level triggers
      result = assert_execute('vagrant', 'provision')
      expect(result.exit_code).to eq(0)
      # Ensure that the trigger is run on both nodes
      expect(result.stdout.scan(%r{server[12]:\s+allnodetest}).size).to eq(4)
      # Ensure that 'nodes = all' includes both nodes
      expect(result.stdout).to match(%r{Bolt: Running bolt command locally: \/[^\ ]+bolt command run[^\n]+allnodetest[^\n]+server[12],server[12]})
      # Ensure that the root level `run_as` is used
      expect(result.stdout).to match(%r{Bolt: Running bolt command locally: \/[^\ ]+bolt command run[^\n]+allnodetest[^\n]+--run-as 'root'})
      ## Configtest
      # Ensure excludes overrides nodes
      expect(result.stdout).to match(%r{Bolt: Running bolt command locally: \/[^\ ]+bolt command run[^\n]+configtest[^\n]+server2})
      # Ensure verbose and debug flags are correctly handled
      expect(result.stdout).to match(%r{Bolt: Running bolt command locally: \/[^\ ]+bolt command run[^\n]+configtest[^\n]+--verbose})
      expect(result.stdout).not_to match(%r{Bolt: Running bolt command locally: \/[^\ ]+bolt command run[^\n]+configtest[^\n]+--debug})
      # Ensure run_as override
      expect(result.stdout).to match(%r{Bolt: Running bolt command locally: \/[^\ ]+bolt command run[^\n]+configtest[^\n]+--run-as 'vagrant'})
    end
  end
end

# frozen_string_literal: true

shared_examples 'provider/virtualbox' do |provider, options|
  include_context "acceptance"
  let(:extra_env) { options[:env_vars] }

  before do
    assert_execute('vagrant', 'box', 'add', 'box', options[:box])
  end

  after do
    execute('vagrant', 'destroy', '-f', log: false)
  end

  describe 'bolt provisioner' do
    before(:each) do
      environment.skeleton('base')
      environment.skeleton('provisioner')
      @result = assert_execute('vagrant', 'up', "--provider=#{provider}")
    end

    it 'runs a task, plan, and command' do
      expect(@result.stdout).to match(%r{Bolt: Running bolt command locally: \/[^\ ]+bolt task run 'facts'})
      expect(@result.stdout).to match(%r{Bolt: Running bolt command locally: \/[^\ ]+bolt plan run 'facts'})
      expect(@result.stdout).to match(%r{Bolt: Running bolt command locally: \/[^\ ]+bolt command run})
      expect(@result.stdout.scan(%r{Successful on 1 node}).size).to eq(3)
    end
  end

  describe 'bolt trigger' do
    before(:each) do
      environment.skeleton('base')
      environment.skeleton('trigger')
      @result = assert_execute('vagrant', 'up', "--provider=#{provider}")
    end

    it 'runs a task, plan, and command' do
      expect(@result.stdout).to match(%r{Bolt: Running bolt command locally: \/[^\ ]+bolt task run 'facts'})
      expect(@result.stdout).to match(%r{Bolt: Running bolt command locally: \/[^\ ]+bolt plan run 'facts'})
      expect(@result.stdout).to match(%r{Bolt: Running bolt command locally: \/[^\ ]+bolt command run})
      expect(@result.stdout.scan(%r{Successful on 1 node}).size).to eq(3)
    end
  end

  describe 'bolt command' do
    before(:each) do
      environment.skeleton('base')
      @result = assert_execute('vagrant', 'up', "--provider=#{provider}")
    end

    it 'runs a task, plan, and command' do
      result = assert_execute('vagrant', 'bolt', 'task', 'run', 'facts', '-n', 'server')
      expect(result.stdout).to match(%r{Bolt: Running bolt command locally: \/[^\ ]+bolt task run facts})
      expect(result.stdout.scan(%r{Successful on 1 node}).size).to eq(1)
      result = assert_execute('vagrant', 'bolt', 'plan', 'run', 'facts', '-n', 'server')
      expect(result.stdout).to match(%r{Bolt: Running bolt command locally: \/[^\ ]+bolt plan run facts})
      expect(result.stdout.scan(%r{Successful on 1 node}).size).to eq(1)
      result = assert_execute('vagrant', 'bolt', 'command', 'run', 'hostname', '-n', 'server')
      expect(result.stdout).to match(%r{Bolt: Running bolt command locally: \/[^\ ]+bolt command run})
      expect(result.stdout.scan(%r{Successful on 1 node}).size).to eq(1)
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'
require 'vagrant-bolt/config'

describe VagrantBolt::Config::Bolt do
  let(:machine) { double("machine") }

  context "validation" do
    it "validates with the defaults" do
      subject.finalize!
      expect(subject.validate(machine)).to eq("Bolt" => [])
    end

    it "allows for a task" do
      subject.command = :task
      subject.name = "foo"
      subject.finalize!
      expect(subject.validate(machine)).to eq("Bolt" => [])
    end

    it "allows for a plan" do
      subject.command = :plan
      subject.name = "foo"
      subject.finalize!
      expect(subject.validate(machine)).to eq("Bolt" => [])
    end

    it "allows for a command" do
      subject.command = :command
      subject.name = "foo"
      subject.finalize!
      expect(subject.validate(machine)).to eq("Bolt" => [])
    end

    it "reports invalid options" do
      subject.foo = "bar"
      subject.finalize!
      expect(subject.validate(machine)["Bolt"][0]).to eq("The following settings shouldn't exist: foo")
    end

    it "reports an error when the command is invalid" do
      subject.command = "bar"
      subject.name = "foo"
      subject.finalize!
      expect(subject.validate(machine)["Bolt"][0]).to match(%r{Type can only be})
    end

    it "reports an error when the name is not specified" do
      subject.command = "task"
      subject.name = nil
      subject.finalize!
      expect(subject.validate(machine)["Bolt"][0]).to match(%r{No name set})
    end

    it "reports an error when the command is not specified" do
      subject.command = nil
      subject.name = "foo"
      subject.finalize!
      expect(subject.validate(machine)["Bolt"][0]).to match(%r{No command set})
    end

    it "reports an error when noop is used without a task" do
      subject.command = :plan
      subject.name = "foo"
      subject.noop = true
      subject.finalize!
      expect(subject.validate(machine)["Bolt"][0]).to match(%r{Noop is not compatible})
    end
  end

  context "defaults" do
    expected_values = {
      nodes: [],
      targets: [],
      excludes: [],
    }
    expected_values.each do |val, expected|
      it "defaults #{val} to #{expected}" do
        subject.finalize!
        expect(subject.send(val)).to eq(expected)
      end
    end

    expected_nil = [
      "name",
      "command",
      "params",
      "node_list",
      "target_list",
      "user",
      "password",
      "port",
      "sudo_password",
      "private_key",
      "tmpdir",
      "run_as",
      "args",
      "ssl",
      "ssl_verify",
      "verbose",
      "debug",
      "host_key_check",
      "machine_alias",
      "machine_name",
      "modulepath",
      "bolt_exe",
      "boltdir",
      "project",
      "noop",
    ]
    expected_nil.each do |val|
      it "defaults #{val} to nil" do
        subject.finalize!
        expect(subject.send(val)).to eq(nil)
      end
    end
  end

  context "inventory config" do
    let(:default_hash) do
      {
        "config" => {
          "ssh" => {
            "password" => "foo",
            "port" => "22",
            "run-as" => "root",
            "host-key-check" => false,
          },
          "winrm" => {
            "password" => "foo",
            "port" => "22",
            "run-as" => "root",
            "ssl" => false,
          },
        },
      }
    end
    before(:each) do
      subject.password = 'foo'
      subject.run_as = 'root'
      subject.port = '22'
      subject.ssl = false
      subject.host_key_check = false
      subject.finalize!
    end

    it 'generates the basic hash structure' do
      expect(subject.inventory_config).to include(default_hash)
    end
    it 'converts names with _ to -' do
      expect(subject.inventory_config['config']['ssh']['run-as']).to eq('root')
    end
  end
end

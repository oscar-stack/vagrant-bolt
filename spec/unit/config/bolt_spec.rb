# frozen_string_literal: true

require 'spec_helper'
require 'vagrant-bolt/config'

describe VagrantBolt::Config do
  let(:machine) { double("machine") }

  context "validation" do
    it "validates with the defaults" do
      subject.finalize!
      expect(subject.validate(machine)).to eq("Bolt" => [])
    end

    it "reports invalid options" do
      subject.foo = "bar"
      subject.finalize!
      expect(subject.validate(machine)["Bolt"][0]).to eq("The following settings shouldn't exist: foo")
    end

    it "reports an error when the type is invalid" do
      subject.type = "bar"
      subject.name = "foo"
      subject.finalize!
      expect(subject.validate(machine)["Bolt"][0]).to eq("Type can only be task or plan, not bar")
    end

    it "reports an error when the name is not specified" do
      subject.type = "task"
      subject.name = nil
      subject.finalize!
      expect(subject.validate(machine)["Bolt"][0]).to eq("No name set. A task or a plan must be specified to use the bolt provisioner")
    end

    it "reports an error when the type is not specified" do
      subject.type = nil
      subject.name = "foo"
      subject.finalize!
      expect(subject.validate(machine)["Bolt"][0]).to eq("No type set. Please specify either task or plan")
    end

    it "reports an error when depenencies is not an array" do
      subject.dependencies = "foo"
      subject.finalize!
      expect(subject.validate(machine)["Bolt"][0]).to match(%r{Invalid data type for})
    end
  end

  context "defaults" do
    expected_values = {
      host_key_check: false,
      ssl: false,
      ssl_verify: false,
      verbose: false,
      debug: false,
      modulepath: "modules",
      bolt_command: "bolt",
      boltdir: ".",
      dependencies: [],
      nodes: [],
    }
    expected_values.each do |val, expected|
      it "defaults #{val} to #{expected}" do
        subject.finalize!
        expect(subject.send(val)).to eq(expected)
      end
    end

    expected_nil = [
      "name",
      "type",
      "parameters",
      "node_list",
      "user",
      "password",
      "port",
      "sudo_password",
      "private_key",
      "tmpdir",
      "run_as",
      "args",
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
        "ssh" => {
          "host-key-check" => false,
          "password" => "foo",
          "port" => "22",
          "run-as" => "root",
        },
        "winrm" => {
          "password" => "foo",
          "port" => "22",
          "run-as" => "root",
          "ssl" => false,
          "ssl-verify" => false,
        },
      }
    end
    before(:each) do
      subject.password = 'foo'
      subject.run_as = 'root'
      subject.port = '22'
      subject.finalize!
    end

    it 'generates the basic hash structure' do
      expect(subject.inventory_config).to include(default_hash)
    end
    it 'converts names with _ to -' do
      expect(subject.inventory_config['ssh']['run-as']).to eq('root')
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'
require 'vagrant-bolt/config'

describe VagrantBolt::Config::Global do
  let(:machine) { double("machine") }

  context "validation" do
    it "validates with the defaults" do
      subject.finalize!
      expect(subject.validate(machine)).to eq("GlobalBolt" => [])
    end

    it "reports invalid options" do
      subject.foo = "bar"
      subject.finalize!
      expect(subject.validate(machine)["GlobalBolt"][0]).to eq("The following settings shouldn't exist: foo")
    end
  end

  context "defaults" do
    before(:each) do
      allow(File).to receive(:file?).with('/opt/puppetlabs/bin/bolt').and_return(true)
    end

    expected_values = {
      bolt_exe: "/opt/puppetlabs/bin/bolt",
      boltdir: ".",
    }
    expected_values.each do |val, expected|
      it "defaults #{val} to #{expected}" do
        subject.finalize!
        expect(subject.send(val)).to eq(expected)
      end
    end

    expected_nil = [
      "user",
      "password",
      "port",
      "sudo_password",
      "private_key",
      "tmpdir",
      "run_as",
      "ssl",
      "ssl_verify",
      "connect_timeout",
      "host_key_check",
      "verbose",
      "debug",
      "facts",
      "vars",
      "features",
      "modulepath",
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

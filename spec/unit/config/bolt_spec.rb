require 'spec_helper'
require 'vagrant-bolt/config'

describe VagrantBolt::Config do
  let (:machine) { double("machine") }

  describe "bolt config" do

    context "validation" do
      it "should validate with the defaults" do
        subject.finalize!
        expect(subject.validate(machine)).to eq({"Bolt"=>[]})
      end

      it "should report invalid options" do
        subject.foo = "bar"
        subject.finalize!
        expect(subject.validate(machine)).to eq({"Bolt"=>["The following settings shouldn't exist: foo"]})
      end

    end
    context "defaults" do
      expected_values = {
        hostkeycheck: false,
        ssl: false,
        sslverify: false,
        verbose: false,
        debug: false,
        modulepath: "modules",
        boltcommand: "bolt",
        boltdir: ".",
      }
      expected_values.each do |val, expected|
        it "should default #{val} to #{expected}" do
          subject.finalize!
          expect(subject.send(val)).to eq(expected)
        end
      end

      expected_nil = [
        "name",
        "type",
        "parameters",
        "nodes",
        "username",
        "password",
        "sudopassword",
        "privatekey",
        "tmpdir",
        "run_as",
        "args",
      ]
      expected_nil.each do |val|
        it "should default #{val} to nil" do
          subject.finalize!
          expect(subject.send(val)).to eq(nil)
        end
      end
    end
  end
end

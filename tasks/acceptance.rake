namespace :acceptance do
  desc "displays components that can be tested"
  task :components do
    exec("vagrant-spec components --config=acceptance/vagrant-spec.config.rb")
  end

  task :setup do
    box = 'alpine/alpine64'
    box_version = '3.7.0'
    provider_name = 'virtualbox'
    box_owner, box_name = box.split('/')
    box_path = File.join('acceptance', 'artifacts', "#{provider_name}.box")
    if !File.exist?(box_path)
      $stderr.puts "Downloading guest box #{box}"
      cmd = "curl -Lf -o #{box_path} https://app.vagrantup.com/#{box_owner}/boxes/#{box_name}/versions/#{box_version}/providers/#{provider_name}.box"
      result = system(cmd)
      if !result
        $stderr.puts
        $stderr.puts "ERROR: Failed to download guest box #{guest_box} for #{provider_name}!"
        exit 1
      end
    end
  end

  desc "runs acceptance tests"
  task :run do
    args = [
      "--config=acceptance/vagrant-spec.config.rb",
    ]

    if ENV["COMPONENTS"]
      args << "--components=\"#{ENV["COMPONENTS"]}\""
    end

    command = "vagrant-spec test #{args.join(" ")}"
    puts command
    puts
    exec(command)
  end
end

task :acceptance do
  Rake::Task['acceptance:setup'].invoke
  Rake::Task['acceptance:run'].invoke
end

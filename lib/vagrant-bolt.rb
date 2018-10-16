module VagrantBolt
  require 'vagrant-bolt/version'
  require 'vagrant-bolt/plugin'
  require 'pry' #REMOVEME

  def self.source_root
    @source_root ||= File.expand_path('..', __FILE__)
  end

end

I18n.load_path << File.expand_path('../templates/locales/en.yml', File.dirname(__FILE__))

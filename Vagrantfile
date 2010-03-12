Vagrant::Config.run do |config|
  config.vm.box = "base" # TODO "debian_lenny"

  config.chef.enabled = true
  config.chef.cookbooks_path = "cookbooks"

  config.vm.forward_port("web", 80, 8080)
end

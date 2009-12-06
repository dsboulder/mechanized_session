require 'rubygems'
gem 'hoe', '>= 2.1.0'
require 'hoe'
require 'fileutils'
require './lib/mechanized_session'

Hoe.plugin :newgem
# Hoe.plugin :website
# Hoe.plugin :cucumberfeatures

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.spec 'mechanized_session' do
  self.developer 'David Stevenson', 'stellar256@hotmail.com'
#  self.post_install_message = 'PostInstall.txt' # TODO remove if post-install message not required
#  self.rubyforge_name       = self.name # TODO this is default value
   self.extra_deps         = [['mechanize','>= 0.9.3']]

end

require 'newgem/tasks'
Dir['tasks/**/*.rake'].each { |t| load t }

# TODO - want other tests/tasks run by default? Add them to the list
# remove_task :default
# task :default => [:spec, :features]

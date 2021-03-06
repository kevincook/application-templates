plugin 'exception_notifier', :git => 'http://github.com/rails/exception_notification.git'
plugin 'rspec', :git => 'http://github.com/dchelimsky/rspec.git'
plugin 'rspec-rails', :git => 'http://github.com/dchelimsky/rspec-rails.git'
plugin 'paperclip', :git => 'http://github.com/thoughtbot/paperclip.git'
plugin 'restful-authentication', :git => 'http://github.com/technoweenie/restful-authentication.git'
plugin 'asset_packager', :git => 'http://synthesis.sbecker.net/pages/asset_packager'
plugin 'role_requirement', :git => 'http://github.com/timcharper/role_requirement.git'
plugin 'haml', :git => "http://github.com/nex3/haml.git"
plugin 'activemerchant', :git => 'http://github.com/Shopify/active_merchant.git'
plugin 'cucumber', :git => "http://github.com/aslakhellesoy/cucumber.git"
plugin 'will_paginate', :git => 'http://github.com/mislav/will_paginate.git'

gem 'sqlite3-ruby', :lib => 'sqlite3'

rake('gems:install', :sudo => true) if yes?('Install gems on local system? (y/n)')

# Use database (active record) session store
rake('db:sessions:create')

# Generate restful-authentication user and session
generate('authenticated', 'user session')

# Generate roles for User
generate('roles', 'Role User')

# Run rspec generator
generate("rspec")

# blueprint/css
run "curl -L http://github.com/joshuaclayton/blueprint-css/tarball/master > public/stylesheets/blueprint.tar && tar xf public/stylesheets/blueprint.tar"
run 'rm public/stylesheets/blueprint.tar'
blueprint_dir = Dir.entries('.').grep(/blueprint/).first
run "mv #{blueprint_dir}/blueprint/*.css public/stylesheets"
run "rm -rf #{blueprint_dir}"

# Run Ryanb's Nifty Layout generator
# generate("nifty_layout")

generate :controller, "welcome index"
route "map.root :controller => 'welcome'"

# Set up database session store
initializer 'session_store.rb', <<-FILE
ActionController::Base.session = { :session_key => '_#{(1..6).map { |x| (65 + rand(26)).chr }.join}_session',
:secret => '#{(1..40).map { |x| (65 + rand(26)).chr }.join}' }
ActionController::Base.session_store = :active_record_store
FILE

rake('db:migrate')

run "curl -L http://jqueryjs.googlecode.com/files/jquery-1.2.6.min.js > public/javascripts/jquery.js"
run "curl -L http://jqueryjs.googlecode.com/svn/trunk/plugins/form/jquery.form.js > public/javascripts/jquery.form.js"

run "touch tmp/.gitignore log/.gitignore vendor/.gitignore"
run %{find . -type d -empty | grep -v "vendor" | grep -v ".git" | grep -v "tmp" | xargs -I xxx touch xxx/.gitignore}
run 'cp config/database.yml config/database.yml.example'
run 'rm README'
run 'rm public/index.html'
run 'rm public/favicon.ico'
run 'rm public/robots.txt'
run 'rm public/images/rails.png'

# Install and configure capistrano
run 'sudo gem install capistrano' if yes?('Install Capistrano on your local system? (y/n)')

capify!

file 'Capfile', <<-FILE
load 'deploy' if respond_to?(:namespace) # cap2 differentiator
Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }
load ‘config/deploy’
FILE

# Set up git repository
git :init
run "echo 'TODO add readme content' > README"
run "touch tmp/.gitignore log/.gitignore vendor/.gitignore"
run "cp config/database.yml config/example_database.yml"

file '.gitignore', <<-END
.DS_Store
log/*.log
tmp/**/*
config/database.yml
db/*.sqlite3
END

git :add => '.', :commit => "-m 'initial commit'"

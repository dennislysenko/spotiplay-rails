# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'spotiplay-rails'
set :repo_url, 'git@github.com:dennislysenko/spotiplay-rails.git'

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/home/deploy/spotiplay-rails'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, fetch(:linked_files, []).push('.env')#push('config/database.yml', 'config/secrets.yml')

# Default value for linked_dirs is []
# set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

set :bundle_roles, %w{web app sidekiq_worker sidekiq_scheduler}
set :assets_roles, %w{app}
set :rvm_roles, %w{web app sidekiq_worker sidekiq_scheduler}
set :migration_role, 'app'

namespace :deploy do

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end

# assumes one web role
namespace :logs do
  task :web do
    on roles(:web) do
      execute "sudo tail -n 100 -f /var/log/nginx/spotiplay-rails_#{fetch(:stage)}.access.log"
    end
  end

  task :app do
    on roles(:app) do
      execute "tail -n 100 -f #{shared_path}/log/unicorn.stdout.log"
    end
  end

  task :sidekiq do
    on roles(:sidekiq) do
      execute "tail -n 100 -f #{shared_path}/log/sidekiq.log"
    end
  end
end

after 'deploy:publishing', 'deploy:restart'
after 'deploy:restart', 'sidekiq:restart'


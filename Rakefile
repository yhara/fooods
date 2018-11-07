require 'irb'

namespace :db do
  task :load_config do
    require "./app"
  end
end

desc "console"
task :console do
  require "./app"
  ARGV.clear  # To prevent `Errno::ENOENT: No such file or directory @ rb_sysopen - console`
  IRB.start
end

desc "git ci, git tag and git push"
task :release_and_deploy do
  v = "v#{ENV.fetch('VERSION')}"
  sh "git diff"
  puts "release as #{v}? [y/N]"
  if $stdin.gets.chomp == "y"
    sh "git ci -am '#{v}'"
    sh "git tag '#{v}'"
    sh "git push origin master --tags"
    sh "bundle exec cap production deploy"
  end
end

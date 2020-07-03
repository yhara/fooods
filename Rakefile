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

VERSION = File.read('CHANGELOG.md')[/v([\d\.]+) /, 1]
desc "git ci, git tag and git push"
task :release do
  v = "v#{VERSION}"
  sh "git diff"
  puts "release as #{v}? [y/N]"
  if $stdin.gets.chomp == "y"
    sh "git ci -am '#{v}'"
    sh "git tag '#{v}'"
    sh "git push origin master --tags"
    #sh "bundle exec cap production deploy"
  end
end

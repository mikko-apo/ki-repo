require_relative 'lib/ki_repo_all'

include Ki

sh = HashLogShell.new
sh.root_log(DummyHashLog.new).detach(true).spawn("nohup (sleep 20 && echo 1 && date > foo.txt)")

puts sh.previous.out
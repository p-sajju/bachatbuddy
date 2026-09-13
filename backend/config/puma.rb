# This configuration file will be evaluated by Puma.
threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
threads threads_count, threads_count

# BachatBuddy API listens on 3000 locally (Next.js uses 3001).
port ENV.fetch("PORT", 3000)

plugin :tmp_restart
pidfile ENV["PIDFILE"] if ENV["PIDFILE"]

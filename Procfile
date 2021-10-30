web: bundle exec ruby app.rb
guard: bundle exec guard -i
redis: redis-server
worker: env QUEUE="*" COUNT=2 bundle exec rake resque:workers
resque-web: bundle exec resque-web --foreground

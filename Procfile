web: bundle exec rackup -p 5000
guard: bundle exec guard -i
redis: redis-server
worker: env QUEUE="download" COUNT=2 bundle exec rake resque:workers
resque-web: bundle exec resque-web --foreground

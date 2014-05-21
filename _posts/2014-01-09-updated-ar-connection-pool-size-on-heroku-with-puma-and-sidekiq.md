---
title: UPDATED - Setting ActiveRecord's connection pool size on Heroku with Puma or Sidekiq
layout: post
description: (Long overdue) An update to the original post, with less DATABASE_URL hacking
author: Jesse
---

[Last I wrote]({% post_url 2013-02-16-activerecord-connection-pool-on-heroku-with-puma-and-sidekiq %}) we
were (almost) mangling the `DATABASE_URL` on Heroku to get the connection pool size we wanted for both Puma and Sidekiq.

Since then, Heroku came out with a [DevCenter article](https://devcenter.heroku.com/articles/concurrency-and-database-connections#connection-pool)
that found the right bits in Rails to get the database config settings (I swear, I looked!) and I could see the error of my ways.

So, without further ado, let's look at the changes.

First, I ditched the `set_db_connection_pool_size!` method in `Platform` and created an initializer.

`config/initializers/database_connection.rb`

{% highlight ruby %}
module Platform
  module Database
    def connect(size=35)
      config = Rails.application.config.database_configuration[Rails.env]
      config['reaping_frequency'] = ENV['DB_REAP_FREQ'] || 10 # seconds
      config['pool']              = ENV['DB_POOL']      || size
      ActiveRecord::Base.establish_connection(config)
    end

    def disconnect
      ActiveRecord::Base.connection_pool.disconnect!
    end

    def reconnect(size)
      disconnect
      connect(size)
    end

    module_function :disconnect, :connect, :reconnect
  end
end

Rails.application.config.after_initialize do
  Platform::Database.disconnect

  ActiveSupport.on_load(:active_record) do
    if Puma.respond_to?(:cli_config)
      size = Puma.cli_config.options.fetch(:max_threads)
      Platform::Database.reconnect(size)
    else
      Platform::Database.connect
    end

    Sidekiq.configure_server do |config|
      size = Sidekiq.options[:concurrency]
      Platform::Database.reconnect(size)
    end
  end
end
{% endhighlight %}

You can see that we make sure to `disconnect` after Rails is done initializing the app.
Then, we reconnect specifically for Puma to match its `max_threads` setting. After that,
do the same for Sidekiq and we're good to go.

Not nearly as ugly and doesn't hack an `ENV` var. I think it's a nice compromise.

### What else does this help?

I recently switched from [Zeus](https://github.com/burke/zeus) to [Spring](https://github.com/rails/spring) and I noticed that when I ran the specs with `./bin/rspec` (provided by the [spring-commands-rspec](https://github.com/jonleighton/spring-commands-rspec) gem) my dev database would get wiped.

I had a hunch it was from having a `DATABASE_URL` env var, so I was extra motivated to refactor this.

#### Hope that helps!

This was deployed to production yesterday, and we haven't seen any issues.

\- *{{ page.author }}*

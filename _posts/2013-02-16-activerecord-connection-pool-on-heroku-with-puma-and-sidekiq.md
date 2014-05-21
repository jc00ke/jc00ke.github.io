---
title: Setting ActiveRecord's connection pool size on Heroku with Puma and Sidekiq
layout: post
description: Our solution to set the pool size from either Puma or Sidekiq.
author: Jesse
---

UPDATE: [A better way to set the connection pool size]({% post_url 2014-01-09-updated-ar-connection-pool-size-on-heroku-with-puma-and-sidekiq %}).

Watsi has used [Puma](http://puma.io) since the beginning. Even
though we run on CRuby 1.9.3 on Heroku (so we don't get any
actual parallelism) I just love how simple & effective Puma is. One
of the few options I set with Puma is the thread min & max.

{% highlight bash %}
$> bundle exec puma -p $PORT -c 4:8
{% endhighlight %}

Since ActiveRecord's default connection pool size is 5, one might
(and we did) see errors that the pool is not big enough when running
Puma, or Unicorn, with more than 5 threads/workers. How might we bump
that up?

#### change the database.yml

If you have control over your `database.yml` file, you can just change
the pool size.

{% highlight yaml %}
production:
  pool: 10
{% endhighlight %}

#### ... or establish a new AR connection

I thought I could [establish a new connection](http://api.rubyonrails.org/classes/ActiveRecord/Base.html#method-c-establish_connection)
and pass in an option, but unfortunately that doesn't work. I wish I could pass options
all the way to the `ConnectionResolver` class but I can't. Plus,
[`connection_url_to_hash`](https://github.com/rails/rails/blob/e7a6b92959012ffde730b2daa38ecd006570779c/activerecord/lib/active_record/connection_adapters/abstract/connection_specification.rb#L60-L77)
just looks at the query string for options like `pool` anyway. Kind of a bust.

So, we're on Heroku, and our only option is to mangle the `DATABASE_URL`.
We could get the `DATABASE_URL`

{% highlight bash %}
$> heroku config | ack DATABASE_URL
DATABASE_URL:      postgres://foo:bar@baz.com/my_db
$> heroku config:add DATABASE_URL=postgres://foo:bar@baz.com/my_db?pool=35
{% endhighlight %}

(Don't do this!)

But how would we ever handle a change to our `DATABASE_URL` by Heroku themselves?
Sounds like trouble. Heroku doesn't recommended this (just asked during
YC office hours) so we need to change the `DATABASE_URL` in a safe way.

#### What about Sidekiq?

Yes, we also want to set the connection pool for Sidekiq to the total number
of workers, like Mike recommends in the [wiki](https://github.com/mperham/sidekiq/wiki/Advanced-Options).

{% highlight ruby %}
Sidekiq.configure_server do |config|
  config.redis = { url: 'redis://redis.example.com:7372/12', namespace: 'mynamespace' }

  database_url = ENV['DATABASE_URL']
  if(database_url)
    ENV['DATABASE_URL'] = "#{database_url}?pool=25"
    ActiveRecord::Base.establish_connection
  end

end
{% endhighlight %}

#### How we do it

Let's take a look at our `config/application.rb`

{% highlight ruby %}

require File.expand_path('../boot', __FILE__)
require "rails/all"

if defined?(Bundler)
  Bundler.require(:default, :assets, Rails.env)
end

module Platform

  def set_db_connection_pool_size!(size=35)
    # bump the AR connection pool
    if ENV['DATABASE_URL'] !~ /pool/
      pool_size = ENV.fetch('DATABASE_POOL_SIZE', size)
      db = URI.parse ENV['DATABASE_URL']
      if db.query
        db.query += "&pool=#{pool_size}"
      else
        db.query = "pool=#{pool_size}"
      end
      ENV['DATABASE_URL'] = db.to_s
      ActiveRecord::Base.establish_connection
    end
  end

  module_function :set_db_connection_pool_size!

  class Application < Rails::Application
    if Puma.respond_to?(:cli_config)
      max = Puma.cli_config.options.fetch(:max_threads)
      ::Platform.set_db_connection_pool_size! max
    end

    # ...
  end

end
{% endhighlight %}

With a [commit](https://github.com/puma/puma/commit/211aef15899a8e5b21174e74519193ead07768c9)
added in `puma 2.0.0.b6` we can now get at the `max_threads` setting. Puma only responds to
`cli_config` when it's started from the command line, so we're cool.

For Sidekiq, we do the same thing in `config/initializers/sidekiq.rb`

{% highlight ruby %}

Sidekiq.configure_server do |config|
  Platform.set_db_connection_pool_size!(Sidekiq.options[:concurrency])
end
{% endhighlight %}

#### Don't mangle Heroku's DATABASE_URL!

That being said, inside your app it's not so bad to tack on a query param.
I did it the safest way I knew how. If you know of a better way, please share!

#### Hope that helps

This has been deployed for a few weeks now and we don't see any connection pool issues anymore.
If you have a way you do it, please tweet [@watsi](https://twitter.com/watsi).

\- *{{ page.author }}*

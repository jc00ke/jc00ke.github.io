---
layout: post
title: Primitive Obsession: Part 2
---

_Read [part 1](/2016/12/26/primitive-obsession/) to see how we got here._

Now, if you're going to make classes like this, like all your classes, it's important to think about the
interface to that class. A custom collection class we recently introduced, which was a long time coming, had a
subtle bug that made it's way to production. Luckily it was easy to track down.

Here's the gist: We store config data as a blob of `JSON` but our UI didn't enforce the types we needed these
values to be. In the beginning they were all strings, and after a fantastic refactor we had strings, booleans,
integers, text, and a few more. One of these settings is a `true/false` that was stored as `"0" or "1"`
because that's how Rail's checkboxes work. We wanted to convert them to be booleans, and our code did that
beautifully. Until...

{% highlight ruby %}
# lib/key.rb
class Key
  def configuration
    @configuration ||= load_from_json
  end

  def configuration_set
    @configuration_set ||= Config.new(configuration)
  end
end

# lib/config.rb
class Config
  def initialize
    @config = Hash.new
  end
end

# lib/thing.rg
class Thing
  def do_something
    return if skip?
    # do things
  end

  def skip?
    key.configuration["should_i_skip"] == "1"
  end
end

# spec/lib/thing_spec.rb
RSpec.describe Thing do
  describe "#skip?" do
    context "when config is set to skip" do
      before do
        # this reaches in too far to something that is now a Boolean :(
        key.configuration["should_i_skip"] = "1"
      end

      its(:skip?) { is_expected.to be_truthy }
    end

    context "when config is not set to skip" do
      before do
        key.configuration["should_i_skip"] = "0"
      end

      its(:skip?) { is_expected.to be_falsey }
    end
  end
end
{% endhighlight %}

The bug showed up when customers complained things weren't being skipped that should be. Without seeing all
the code, can you spot the bug? Remember when I said that after the refactor we had `Booleans`? Well, that
config setting, `"should_i_skip"` is now a boolean, so `key.configuration["should_i_skip"]` will only ever
return `true|false` and our test doesn't catch it!

Changing `Thing#skip?` to be just `key.configuration["should_i_skip"]` fixed the bug, and changing the specs
to set that to `true` and `false` fix the test. But the design is still vulnerable because we expose
`Hash#[]=` on the storage of our custom class, and that's ripe for more bugs in the future.

Here we need to restrict access to that `Hash` that's acting as our underlying storage, thereby removing from
use methods like `#[]=`. Does that method even really belong in our `Config` class? Probably not. It's
something we'll look at removing right away.

To wrap this up, while primitives are rich in functionality in Ruby, and extensible with libraries like
`ActiveSupport`, that doesn't mean you should use them for everything. `ValueObject` and collection classes
(collections of `ValueObject`s) are powerful tools in your toolbox. When you use them, be careful of the API
you expose though, and make sure to not leak the underlying collection.




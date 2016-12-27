---
layout: post
title: Primitive obsession
---

I've been wanting to write about primitive obsession, specifically in Ruby, for a long time. A bug that made
its way to production last week has given me the kick I need to get this post out.

So, what is primitive obsession? Taken from [C2 Wiki](http://wiki.c2.com/?PrimitiveObsession)

> Primitive Obsession is using primitive data types to represent domain ideas.
> For example, we use a String to represent a message, an Integer to represent an amount of money,
> or a Struct/Dictionary/Hash to represent a specific object.

We're all guilty of this because in general we're all kinda lazy. It's certainly not a "rookie mistake".
Here it is in the latest version of
[redis.rb](https://github.com/redis/redis-rb/blob/27759c01626762c818e6699e8d1a781530fe7d39/lib/redis.rb#L1395)

{% highlight ruby %}
# Get all the members in a set.
#
# @param [String] key
# @return [Array<String>]
def smembers(key)
  synchronize do |client|
    client.call([:smembers, key])
  end
end
{% endhighlight %}

Spot the issue?

Members of a set are a subset. A set's members, by definition, are unique from one another. An `Array` is
not a collection that enforces uniqueness. Have you ever done the following?

{% highlight ruby %}
array_of_things << thing unless array_of_things.include?(thing)
{% endhighlight %}

Congratulations, you've just recreated Ruby's `Set` class. That's not a good thing. One reason why that's not
a good thing is (with the caveat that you should always do your own benchmarks) that checking to see if an
array includes an object is `O(n)` where checking to see if a `Set` includes an object is `O(1)`.

Let me clarify: at _best_ and at _worst_ an array is `O(n)` because it's always `O(n)` for search. At _best_ a
`Set`, [backed by a
`Hash`](https://github.com/ruby/ruby/blob/7e8b910a5629fe025137e890ec6d57e538fd7811/lib/set.rb#L84), is `O(1)` which is quite good, `O(n)` at _worst.

So there are consequences to using the wrong type, not just from a congnitive point of view but performance as
well. Ok, let's leave `Array/Set` alone for now. If you're curious, read up on the [Atomic
Object](https://spin.atomicobject.com/2012/09/04/when-is-a-set-better-than-an-array-in-ruby/) blog, that's a
great writeup.

Back to primitive obsession. I think that Ruby developers are lucky but burdened by Rails, specifically when
it comes to "good OO". `ActiveSupport` is a rad library, and I fondly remember reading the Rails book in 2006
and being blown away by the ability to do `2.days.from_now`.

One of the things I appreciate from `Arel` is that when you make a query you get back an instance of
`ActiveRecord::Relation` not an `Array`. You can ask this relation questions you couldn't, and shouldn't, ask
an `Array`. This brings me to something I don't often see in Ruby... collection classes.

A collection class is a class that represents a collection of objects. Why might you use a collection class
over an `Array` or a `Hash`, or even a `Set`? Most likely because you want to ask that collection questions
that `Array`, `Hash`, and even `Set` have no idea about. We reach for these custom classes because a
primitive is too simple, too basic, and we end up asking questions in the wrong places.

I had to interact with a remote API that did not give back good error messages. An example of how this works:

{% highlight ruby %}
class WidgetCollection
  include Enumerable

  attr_accessor :errors

  def initialize(widgets)
    @widgets = Set.new(widgets)
  end

  def each
    return enum_for(:each) unless block_given?

    @widgets.each do |widget|
      yield widget
    end

    self
  end

  def invalid_widget_present?
    return false unless errors
    !!/some pattern that we hope works for a long time/.match(errors.to_s)
  end
end

class Widget
  def self.fetch
    api_results = Fetch.call
    WidgetCollection.new(api_results).tap do |widgets|
      widgets.errors = api_results.fault_code # a string, could be anything :(
    end
  end
end

# elsewhere...

widgets = Widget.fetch
log(a_message) if widgets.invalid_widget_present?
{% endhighlight %}

It's unfortunate that the remote API gives us a fault code like that, but at least we can hide it in a class
and keep our code a bit cleaner. Granted, there are more moving parts in our production code, but this way of
dealing with the remote API feels like the right way. Much better than using an `Array` and checking the
status further out. That's certainly not "good" `OO`!

What would that code have looked like?

{% highlight ruby %}
# elsewhere...

widgets = Widget.fetch
log(a_message) if WidgetCollection::ERROR_MESSAGE.match(widgets.errors)
{% endhighlight %}

That requires you to know way too much, and it's a sign that you're relying too heavily on primitives.

This got a bit longer than I expected, so I'll kick the actual production bug to a separate post.

---
title: A kind of map/reduce using CTE's
layout: post
description: Using Common Table Expressions to perform a version of map/reduce.
author: Jesse
tags:
- sql
---

I was once tasked with writing a pretty complicated query to quantify
[Watsi](https://watsi.org)'s weekly growth. We wanted to take into
account monthly donations though. How does one do that when monthly
donations are all charged on the first of the month? How do we include
tips to our overhead fund?

I recognize there are all sorts of ways to do this. Hell, I could have
written this in `Ruby`, and I almost did, but we used Heroku's
[Dataclips](http://j.mp/1u1OVxN) which allowed us to get near-realtime results[1].

Let's take a slightly simpler example: A small business sells widgets.
Widgets are sold for all different prices, and you can even set up a
recurring order that is charged on the first of the month.

Imagine we have a very simple table `purchases` that looks something
like this:

| name        | type                        |
| ----------- | --------------------------- |
| id          | int                         |
| amount      | int                         |
| created_at  | timestamp without time zone |
| refunded_at | timestamp without time zone |
| recurring   | bool                        |

Some sample data:

| id | amount | created_at          | refunded_at         | recurring |
| -- | ------ | ------------------- | ------------------- | --------- |
| 1  | 1300   | 2014-08-01 08:00:00 | null                | true      |
| 2  | 900    | 2014-08-03 13:30:00 | null                | false     |
| 3  | 1300   | 2014-08-24 23:30:00 | 2014-08-24 23:31:00 | false     |
| 3  | 1400   | 2014-08-24 17:30:00 | null                | false     |
| 4  | 1700   | 2014-09-01 08:00:00 | null                | true      |
| 5  | 1200   | 2014-09-03 17:27:00 | null                | false     |

So, given this info, we calculate our weekly amount as:

```
(daily totals + avg daily totals from recurring) / # of weeks in month
```

*Note:* I'm going to ignore time zones for brevity, but assume I'm setting
everything to `America/Los_Angeles`.

In any other database I would have had to either use `temp tables` or `sub-selects`
but PostgreSQL has what are called [Common Table Expressions](http://www.postgresql.org/docs/9.3/static/queries-with.html)
or `WITH` queries.

`WITH` queries allow us to turn `sub-selects` into named tables without the need
to generate actual `temp tables`.

{% highlight sql %}
select
  foo,
  bar
from
  (
    select
      foo,
      bar_id
    from
      foos
    where
      something > 1
  ) as some_foos inner join bars on
  some_foos.bar_id = bars.id
{% endhighlight %}

can be turned into this:

{% highlight sql %}
with some_foos as (
  select
    foo,
    bar_id
  from
    foos
  where
    something > 1
)

select
  foo,
  bar
from
  some_foos inner join bars on
  some_foos.bar_id = bars.id
{% endhighlight %}

This trivial example doesn't do the greatest job in showing the power of CTE's,
but the final query below will.

OK, so let's see some SQL:

{% highlight sql %}
with daily_purchases as (
  select
    date(date_trunc('day', created_at)) as day,
    sum(amount)::money / 100 as purchased
  from
    purchases
  where
    refunded_at is null
    and
    recurring = false
  group by
    1
  order by
    1
)
{% endhighlight %}

which will yield results like so:

| day        | purchased |
| ---------- | --------- |
| 2014-08-03 | $9.00     |
| 2014-08-24 | $14.00    |
| 2014-09-03 | $12.00    |

Now let's add the month to this result set, which wasn't possible before
because of the `group by` clause.

{% highlight sql %}
daily_purchases_with_month as (
  select
    date(date_trunc('month', day)) as month,
    day,
    purchased
  from
    daily_purchases
)
{% endhighlight %}

| month      | day        | purchased |
| ---------- | ---------- | --------- |
| 2014-08-01 | 2014-08-03 | $9.00     |
| 2014-08-01 | 2014-08-24 | $14.00    |
| 2014-09-01 | 2014-09-03 | $12.00    |

Now we need to calculate each month's recurring revenue:

{% highlight sql %}
per_month_recurring as (
  select
    date(date_trunc('month', created_at)) as month,
    sum(amount)::money / 100 as purchased
  from
    purchases
  where
    recurring = true
  group by
    1
  order by
    1
)
{% endhighlight %}

| month      |  purchased |
| ---------- |  --------- |
| 2014-08-01 |  $13.00    |
| 2014-09-01 |  $17.00    |

But now we have to average in the recurring into each day. How can we
handle the different number of days in a month? With another query:

{% highlight sql %}
per_day_recurring as (
  select
    date_part('days',
        date_trunc('month', month)
        + '1 month'::interval
        - date_trunc('month', month)
    ) as days_per_month,
    month,
    purchased
  from
    per_month_recurring
)
{% endhighlight %}

| days_per_month | month      |  purchased |
| -------------- | ---------- |  --------- |
| 31             | 2014-08-01 |  $13.00    |
| 30             | 2014-09-01 |  $17.00    |

August has 31 days, September has 30. This approach handles leap years
in February too.

We now need to find the actual average per day based on the month:

{% highlight sql %}
average_per_day_recurring as (
  select
    month,
    purchased  / days_per_month as recurring_purchases_per_day
  from
    per_day_recurring
)
{% endhighlight %}

So now we have:

| month      |  purchased |
| ---------- |  --------- |
| 2014-08-01 |  $0.42     |
| 2014-09-01 |  $0.57     |

Now it's time to start mashing these tables together:

{% highlight sql %}
totals as (
  select
    dpwm.day,
    dpwm.purchased,
    apdr.recurring_purchases_per_day
  from
    daily_purchases_with_month dpwm left outer join average_per_day_recurring apdr on
    dpwm.month = apdr.month
)
{% endhighlight %}

| day        | purchased | recurring_purchases_per_day |
| ---------- | --------- | --------------------------- |
| 2014-08-03 | $9.00     | $0.42                       |
| 2014-08-24 | $14.00    | $0.42                       |
| 2014-09-03 | $12.00    | $0.57                       |

OK, we're close! We have `daily totals` and `avg daily totals from recurring`.
Last calculation we need to do is add up the amounts and `group by` the week.
This is the reduction I alluded to above:

{% highlight sql %}
reduced as (
  select
    date(date_trunc('week', day)) as week,
    sum(purchased + recurring_purchases_per_day) as total_purchased
  from
    totals
  group by
    1
  order by
    1
)

{% endhighlight %}

Finally, we get our actual weekly totals:

| week       | total_purchased |
| ---------- | --------------- |
| 2014-07-28 | $9.42           |
| 2014-08-18 | $14.42          |
| 2014-09-01 | $12.57          |

Notice that the start of the week shifted. Take heed!

## The final query

In all its glory, or something:

{% highlight sql %}
with daily_purchases as (
  select
    date(date_trunc('day', created_at)) as day,
    sum(amount)::money / 100 as purchased
  from
    purchases
  where
    refunded_at is null
    and
    recurring = false
  group by
    1
  order by
    1
  ), daily_purchases_with_month as (
  select
    date(date_trunc('month', day)) as month,
    day,
    purchased
  from
    daily_purchases
), per_month_recurring as (
  select
    date(date_trunc('month', created_at)) as month,
    sum(amount)::money / 100 as purchased
  from
    purchases
  where
    recurring = true
  group by
    1
  order by
    1
), per_day_recurring as (
  select
    date_part('days',
        date_trunc('month', month)
        + '1 month'::interval
        - date_trunc('month', month)
    ) as days_per_month,
    month,
    purchased
  from
    per_month_recurring
), average_per_day_recurring as (
  select
    month,
    purchased  / days_per_month as recurring_purchases_per_day
  from
    per_day_recurring
), totals as (
  select
    dpwm.day,
    dpwm.purchased,
    apdr.recurring_purchases_per_day
  from
    daily_purchases_with_month dpwm left outer join average_per_day_recurring apdr on
    dpwm.month = apdr.month
), reduced as (
  select
    date(date_trunc('week', day)) as week,
    sum(purchased + recurring_purchases_per_day) as total_purchased
  from
    totals
  group by
    1
  order by
    1
)

select
  *
from
  reduced
{% endhighlight %}

I hope you enjoyed this venture into using CTE's to build up a simple result from a
decently complex, for SQL, report. I've grown quite fond of CTE's and luckily I
used PostgreSQL exclusively for my last several projects. The expressive power
to compose SQL queries like this is one of the many things I love about
PostgreSQL.

ps: My friend [Jacob](https://twitter.com/jacobrothstein) asked how well this
performs. From what I can tell it performs really well, but I haven't had the
chance to benchmark it yet. I'm hoping to write up how it performs 1) with more
data and 2) against an implementation in Ruby.

[1] I say "near-realtime" because Heroku caches the results for some period.

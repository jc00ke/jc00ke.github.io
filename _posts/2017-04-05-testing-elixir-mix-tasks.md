---
layout: post
title: Testing Elixir Mix tasks
description: Tips on testing custom Mix tasks & task output
author: Jesse
tags:
- elixir
- mix
- testing
---

What's the best way to test your [Mix tasks](https://hexdocs.pm/mix/Mix.Task.html)? I needed
to write a custom `Mix` task yesterday, and I wanted to start off right by
writing a test. I wanted to reuse some code that generates & verifies a [JWT](https://jwt.io) and
spits it out in the terminal.

The code has always been relatively simple:

```elixir
defmodule Mix.Tasks.Jwt.Gen do
  use Mix.Task

  @shortdoc "Generates a JWT"

  @moduledoc """
  Generates a JWT far far into the future.

      mix jwt.gen
  """

  def run(_argv) do
    exp =   Joken.current_time + 1_000_000
    jti =   :rand.uniform
    iss =   "Jesse"

    jwt = Jwt.generate_jwt(%{exp: exp, jti: jti, iss: iss)
    Mix.shell.info(jwt)
  end
end
```

My test started off looking like this:

```elixir
defmodule Mix.Tasks.Jwt.GenTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  describe "run/1" do
    test "prints a valid JWT" do
      jwt = capture_io(fn ->
        Mix.Tasks.Jwt.Gen.run([])
      end) |> String.trim

      token = Jwt.verify(jwt)
      refute token.errors
    end
  end
end
```

OK, this is fine, but there was an annoying side effect: the JWT was printed to `:stdio`
when I ran the tests. I thought `capture_io` was supposed to actually capture _and_ suppress
the output... I was wrong. Or, I was missing something, and that ended up being the case.

I figured the best guidance I could get would be to see what [Phoenix](http://www.phoenixframework.org/) did,
and I found an example in the [routes task
test](https://github.com/phoenixframework/phoenix/blob/b6db9a268e68cb2c975dde20f9c103e6442a8265/test/mix/tasks/phx.routes_test.exs#L17):

```elixir
test "format routes for specific router" do
  Mix.Tasks.Phx.Routes.run(["PhoenixTest.Web.Router"])
  assert_received {:mix_shell, :info, [routes]}               # <---- ooh!
  assert routes =~ "page_path  GET  /  PageController :index"
end
```

Yes, [assert_received](https://hexdocs.pm/ex_unit/ExUnit.Assertions.html#assert_received/2) seems like a
cleaner way to go. How did this change my tests?

```elixir
defmodule Mix.Tasks.Jwt.GenTest do
  use ExUnit.Case, async: true

  describe "run/1" do
    test "prints a valid JWT" do
      Mix.Tasks.Jwt.Gen.run([])

      assert_received {:mix_shell, :info, [jwt]}    # pattern matching FTW

      token = Jwt.verify(jwt)
      refute token.errors
    end
  end
end
```

Much nicer!

Still though, the JWT was being printed to `:stdio`! I didn't even know where to begin
searching for how to handle this, so I went back to the Phoenix tests and noticed a helper
was being required.

```elixir
Code.require_file "../../../installer/test/mix_helper.exs", __DIR__
```

The key was at the [top of that
file!](https://github.com/phoenixframework/phoenix/blob/b6db9a268e68cb2c975dde20f9c103e6442a8265/installer/test/mix_helper.exs#L1-L3)

```elixir
# Get Mix output sent to the current
# process to avoid polluting tests.
Mix.shell(Mix.Shell.Process)
```

Once I changed my tests to include that, the unwanted output went away and I was happy
with the shape of the tests.

```elixir
# Get Mix output sent to the current
# process to avoid polluting tests.
Mix.shell(Mix.Shell.Process)

defmodule Mix.Tasks.Jwt.GenTest do
  use ExUnit.Case, async: true

  describe "run/1" do
    test "prints a valid JWT" do
      Mix.Tasks.Jwt.Gen.run([])

      assert_received {:mix_shell, :info, [jwt]}    # pattern matching FTW

      token = Jwt.verify(jwt)
      refute token.errors
    end
  end
end
```

I hope this saves you some trouble, and I'd love to hear how you test your tasks. Mention
me on [Twitter](https://twitter.com/jc00ke) with a link to a Gist and I'll add it here.

### On options

I ended up using `OptionParser` so I could pass in `exp`, `iss` and `jti`. My final test looked like this:

```elixir
Code.require_file("../mix_test_helper.exs", __DIR__)

defmodule Cerebro.Jwt.GenTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Jwt.Gen

  describe "run/1" do

    setup context do
      Gen.run(context[:argv])

      assert_received {:mix_shell, :info, [jwt]}

      token = Cerebro.Jwt.verify_jwt(jwt)

      {:ok, claims: token.claims, token: token}
    end

    @tag argv: []
    test "prints a valid JWT with no args", %{token: token} do
      refute token.error
    end

    @tag argv: ["--exp", "123"]
    test "prints a valid JWT when passed an expiration", %{claims: claims} do
      assert_in_delta claims["exp"], Joken.current_time, 124
    end

    @tag argv: ["--jti", "fdsa"]
    test "prints a valid JWT when passed a jti", %{claims: claims} do
      assert claims["jti"] == "fdsa"
    end

    @tag argv: ["--iss", "logan"]
    test "prints a valid JWT when passed an iss", %{claims: claims} do
      assert claims["iss"] == "logan"
    end

    @tag argv: ["--token", "asdf"]
    test "prints a valid JWT when passed a token", %{claims: claims} do
      assert claims["token"] == "asdf"
    end
  end
end
```

I'm really happy with the way that turned out.

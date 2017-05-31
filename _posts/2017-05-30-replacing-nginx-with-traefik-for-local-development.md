---
layout: post
title: Replacing Nginx with Træfik for local development
description: How I simplified my setup by favoring Træfik over Nginx
author: Jesse
tags:
- træfik
- nginx
- rails
---

At [$work](https://inquicker.com/) most of the team uses Docker to develop our core Rails app. Before that,
they used Vagrant. This is fine, for them. I strongly dislike working with these tools, so I always
set up my projects to also run locally. Using processes. And commands. And things that are not black boxes.
But this can be a bit of a PITA when you work on an app that requires both subdomains and SSL.

## Previously

I would turn to Nginx, where I would `apt-get install nginx` and then go install
[nginx_ensite](https://github.com/perusio/nginx_ensite) then setup a config and some SSL certs, like so:

```nginx
# /etc/nginx/sites-enabled/inquicker

server {
  listen 80;
  server_name inquickerlocal.com;

  return 301 https://iqapp.inquickerlocal.com$request_uri;
}

server {
  listen 80;
  server_name *.inquickerlocal.com;

  return 301 https://${host}${request_uri};
}

server {
  listen 443 ssl;
  server_name inquickerlocal.com www.inquickerlocal.com;

  include /etc/nginx/iqapp-ssl-settings.conf;

  return 301 https://iqapp.inquickerlocal.com$request_uri;
}

server {
  listen 443 ssl;
  server_name *.inquickerlocal.com;

  include /etc/nginx/iqapp-ssl-settings.conf;

  root /path/to/iqapp/public;
  try_files $uri $uri/index.html @app;

  location @app {
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto https;
    proxy_set_header Host $host;
    proxy_redirect off;
    proxy_pass http://localhost:3000;
  }
}
```

I'd then have to go into that file and change things to work with my local setup, like

```nginx
root /path/to/iqapp/public;
```

Ain't nobody got time for that.

## Enter Træfik.

> Træfik (pronounced like traffic) is a modern HTTP reverse proxy and load balancer made
> to deploy microservices with ease.

It's quite powerful, and you can find out all about it [here](https://traefik.io/). I'll save you some time if
you just want to set up a reverse proxy that also serves your local development site over SSL. This is our
setup for a typical Rails app:

```toml
[web]
address = ":8080"

traefikLogsFile = "log/traefik.log"
accessLogsFile = "log/access.log"

defaultEntryPoints = ["http", "https"]
[entryPoints]
  [entryPoints.http]
  address = ":80"
    [entryPoints.http.redirect]
    entryPoint = "https"
  [entryPoints.https]
  address = ":443"
    [entryPoints.https.tls]
      [[entryPoints.https.tls.certificates]]
      certFile = "config/development-cert.pem"
      keyFile = "config/development-key.pem"

[file]

[backends]
  [backends.puma]
    [backends.puma.servers.rails]
      url = "http://127.0.0.1:3000"

[frontends]
  [frontends.my_app]
  entrypoints = ["https"]
  backend = "puma"
  passHostHeader = true
    [frontends.my_app.routes.all]
      rule = "HostRegexp:{subdomain:[a-z]+}.myapp.dev"
```

You can then run it with `sudo traefik -c config/traefik.toml`. You need the `sudo` to run on the privileged
ports `80` and `443`.

Let's step through this, as it was a bit confusing to get it right.

### Admin interface

```toml
[web]
address = ":8080"
```

Add this and you can browse to [http://localhost:8080](http://localhost:8080) to see Træfik's web interface,
which was actually handy in debugging this whole thing.

### Log files

```toml
traefikLogsFile = "log/traefik.log"
accessLogsFile = "log/access.log"
```

I had a typo (`frontend.my_app` instead of `frontends.my_app`) and the access log file would show me the
`404`.

### Entrypoints

```toml
defaultEntryPoints = ["http", "https"]
[entryPoints]
  [entryPoints.http]
  address = ":80"
    [entryPoints.http.redirect]
    entryPoint = "https"
  [entryPoints.https]
  address = ":443"
    [entryPoints.https.tls]
      [[entryPoints.https.tls.certificates]]
      certFile = "config/development-cert.pem"
      keyFile = "config/development-key.pem"
```

Define 2 entries, one that's unsecured and redirects to the other secured one, and the secured one, secured by
local cert and key files. We already had these dev certs (both in `.pem` formats) checked into our repo, so
was simple to config. No need to `sudo cp` the files to somewhere in `/etc/nginx/`. Read more about
entrypoints [here](https://docs.traefik.io/basics/#entrypoints).

### Configuration backends

```toml
[file]
```

This took me a bit to figure out. I needed to specify that this file was where I was going to be defining the
`backends` and `frontends`. Read more about it [here](https://docs.traefik.io/toml/#configuration-backends).

### Backends

```toml
[backends]
  [backends.puma]
    [backends.puma.servers.rails]
      url = "http://127.0.0.1:3000"
```

This section defines where traffic will be sent. I would start up Rails with a simple `bundle exec rails s`
which defaults to port `3000`. The `puma` and `rails` parts to the name are arbitrary. You can read more about
backends [here](https://docs.traefik.io/basics/#backends).

### Frontends

```toml
[frontends]
  [frontends.my_app]
  entrypoints = ["https"]
  backend = "puma"
  passHostHeader = true
    [frontends.my_app.routes.all]
      rule = "HostRegexp:{subdomain:[a-z]+}.inquickerlocal.com"
```

So this took me a bit to figure out. I had to manually define the `entrypoints` which I thought would have
been handled by `defaultEntryPoints`. Setting the `backend` makes sense, no problems there. `passHostHeader`
is something we've had to do for a while, and the equivalent in `Nginx` is `proxy_set_header Host $host;`.

Now the frontend matchers... those are powerful. I chose the `HostRegexp` since I wanted to match on the
subdomains. I lifted that straight from the docs, which you can find
[here](https://docs.traefik.io/basics/#frontends).

### Fin

I really like this setup, and while it is one more thing to run (`sudo traefik`) it's all closer to the app and
not some system-wide thing that's in `/etc`. While `Nginx` has served me well for years, when it comes to
local development I feel that Træfik is easier to set up and more powerful. It has fantastic Docker
integration too, so one day I may need to explore that. Until then, I'm happy with this.

If you have any comments or suggestions, ping me on [Twitter](https://twitter.com/jc00ke).

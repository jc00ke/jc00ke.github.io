---
title: Forward SMS to email via Twilio and Mailgun
layout: post
description: Don't use SendGrid
author: Jesse
tags:
- sms
- twilio
- mailgun
---

Back in 2017 [Phil Nash](https://twitter.com/philnash) wrote a very nice blog post for Twilio
called [Forward incoming SMS messages to email with Node.js, SendGrid and Twilio 
Functions](https://www.twilio.com/blog/2017/07/forward-incoming-sms-messages-to-email-with-node-js-sendgrid-and-twilio-functions.html). 
I used this exact setup this year for [Ratio](https://ratiopbc.com) because I wanted a dedicated phone number 
for the business. Voice calls are forwarded directly to my mobile using `TwiML Bins` via the following simple 
  bin:

{% highlight xml %}
<?xml version="1.0" encoding="UTF-8"?>
<Response>
  <Dial>+1971221xxxx</Dial>
</Response>
{% endhighlight %}

Back to SMS forwarding... we don't get many SMS messages and instead of warning us via email, SendGrid just 
closed the account. So for some months we weren't getting SMS messages forwarded to our Google Group inbox.
Even though I added a credit card, they could not reactivate it, so here I am with a port 
to [Mailgun](https://www.mailgun.com/).

So, same basic steps as Phil's blog post except `Functions/Functions` are now `Functions/Services` which you
can find 
[here](https://console.twilio.com/us1/develop/functions/services?frameUrl=/console/functions/overview/services).

Create a new function at path `/forward`.

Under `Dependencies` add `mailgun.js` version 4.1.1 and `form-data` version 4.0.0.

Under `Environment Variables` add `MAILGUN_DOMAIN`, `MAILGUN_API_KEY`, `FROM_EMAIL_ADDRESS`, and 
`TO_EMAIL_ADDRESS`.

I based this on the [Mailgun 
example](https://documentation.mailgun.com/en/latest/quickstart-sending.html#send-via-api):

{% highlight javascript %}
exports.handler = function(context, event, callback) {
  const API_KEY = context.MAILGUN_API_KEY;
  const DOMAIN = context.MAILGUN_DOMAIN;

  const formData = require('form-data');
  const Mailgun = require('mailgun.js');

  const mailgun = new Mailgun(formData);
  const client = mailgun.client({username: 'api', key: API_KEY});

  const messageData = {
    from: context.FROM_EMAIL_ADDRESS,
    to: context.TO_EMAIL_ADDRESS,
    subject: `New SMS message from: ${event.From}`,
    text: event.Body
  };

  client.messages.create(DOMAIN, messageData)
  .then((res) => {
      let twiml = new Twilio.twiml.MessagingResponse();
      callback(null, twiml);
  })
  .catch((err) => {
    console.error(err);
    callback(err);
  });
};
{% endhighlight %}

Make sure you hooked it up to the correct phone number, then test it out by sending an SMS message to your 
Twilio number. If you need to debug, look in the [Messaging 
logs](https://console.twilio.com/us1/monitor/logs/sms?frameUrl=%2Fconsole%2Fsms%2Flogs%3Fx-target-region%3Dus1) 
in Twilio and the Mailgun `Sending/Logs`.

If you run into issues or have feedback, please don't hesitate to send me an email if you know it, or mention 
[me on Twitter](https://twitter.com/jc00ke). Thanks!

---
layout: "vagrant-cloud"
page_title: "Request Limits"
sidebar_current: "vagrant-cloud-request-limits"
---

# Request Limits

## What is Rate Limiting?

Rate limiting is a process to protect our quality of service we provide to you. Rate limiting will limit the number of requests a client may send to services over a set time interval. We track requests by IP address origin of the request.

## How many requests can I make?

You can make a set amount of requests per minute from a single IP address. This rate can vary per resource but the current value is returned in the HTTP headers of your request.  For the most up to date rate limiting for your requests please view the information in the headers of your response.

## Why are you rate limiting my requests?

We have detected a request rate in excess of our current threshold. To provide a high quality of services to all users, your request may have been rate limited.

## How do I know if I have been rate limited?

If you have received a 429 HTTP status code in the response to your request, your request has likely been rate limited. There is some additional information in the headers that will help you determine if this is the case. Each request response will include the headers:  X-RateLimit-Limit, X-RateLimit-Remaining, and X-RateLimit-Reset.

- **X-RateLimit-Limit**: The current maximum number of requests allowed from your client.
- **X-RateLimit-Remaining**: How many requests you have remaining in the time window.
- **X-RateLimit-Reset**: The unix timestamp for when the window resets.

## My use case requires more requests.  What do I do?

Please contact
<a href="mailto:support+vagrantcloud@hashicorp.com">
support+vagrantcloud@hashicorp.com
</a>.

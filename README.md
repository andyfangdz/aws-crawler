# Crawlexa

A crawler w/ aws

## Design

A distributed system is the product of tradeoffs made to
better fit it for the specific targeting scenario.

This crawler was designed with a fundamental tradeoff:
*repeated crawling of a page is less costly than missing a page*,
i.e., we want a complete crawl of the target site.

For this reason, data structures like bloom filters can't be used,
since Bloom Filters make it possible to mis-catogrize a URL
as alredy crawled. Instead, the de-duplication is handled via
DynamoDB, which has a scaling model suitable for logging crawling
information.

One caveat is that there is no real queuing mechanism to invoke
AWS Lambda, as there is only synchronous and asynchronous invocations.
Instead, a "queue" is simulated by using Simple Notification Service,
a system similar to "PubSub" by Google, with automatic retry when throuttled.
However, there is only *at least once* delivery guarantee in this model.

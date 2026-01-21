# Continuous Experimentation: Request Caching

## Motivation

The current implementation of the `model-service` processes every incoming prediction request by loading the machine learning model and performing inference. While this approach works for a small scale deployment, the problem is that it may lead to unnecessary computational load and increased response latency. This becomes even more of a problem when the system needs to deal with more concurrent users.

A solution to this problem is to introduce a caching mechanism for SMS messages and their classification in order to avoid having to perform repeated inferance for common messages. The goal of this experiment is to evaluate the impact of a simple in-memory cache on latency and resource consumption.

## Changes Made

The actual caching is done at the `model-service` level in the `serve_model.py` file. The data structure used to implement the cache is a Python dictionary. The cache size and entry time-to-live is configurable with the `CACHE_MAX_SIZE` (default 1000) and `CACHE_TTL_SECONDS` (default 3600) respectively. The cache uses a FIFO eviction policy in the case that requests come in faster than they expire.

To help perform the caching, some new functions are introduced:
- `get_cache_key`: Performs SHA-256 hashing on the SMS message contents to derive the key used in the cache.
- `get_from_cache`: Retrieves a prediction from the cache if it exists and is not expired.
- `add_to_cache`: Adds a message hash and prediction pair to the cache.
- `get_cache_stats`: Returns information about the cache, including: cache size, max size, expire time, number of hits, number of misses, total requests, and hit rate percentage. New endpoints `/cache` and `/sms/cache` (proxy) are added to `model-service` and `app` respectively to display this information.

The `/predict` endpoint in `model-service` is modified to use the above functions to perform caching when it is enabled. In order for caching to be enabled, the `/predict` endpoint needs to be accessed with the `X-Cache-Enabled` flag header set to `true`. The user is unable to do this manually since they cannot directly communicate with the `model-service` by default. Instead, this is handled by the modified logic in `FrontendController.java` in `app` which sets this header for all requests when the `CACHE_ENABLED` environment variable is set to `true`. This environment variable is only set in the canary version of the `app` deployment, thus allowing the caching feature to be toggled on or off for users depending on whether or not they are part of the experiment.

## Hypothesis

We hypothesise that implementing caching for messages and their predictions will reduce the average prediction latency by at least 20% while also decreasing the overall CPU usage of the application.

## Relevant Metrics
- Prediction latency (ms): The average time taken for receiving a request to sending a response.
- CPU Usage (%): The average CPU load on the `model-service` pods.

## Decision Process

A simple set of one-sided hypothesis tests will be preformed on the data gathered from our two metrics. We will assess these hypotheses to a 95% degree of confidence (2 standard deviations above the mean). As $$n > 30$$ for all tests we can assume our data to have a normal/Gaussian distribution as per the CLT.

The Null and Alternate Hypotheses for the latency claims are:

$$H_0: \mu_{cached} > 0.8 * \mu_{original}$$
$$H_A: \mu_{cached} \leq 0.8* \mu_{original}$$

The Null and Alternate Hypotheses for the CPU claims are:

$$H_0: \mu_{cached} >  \mu_{original}$$
$$H_A: \mu_{cached} \leq \mu_{original}$$
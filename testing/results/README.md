# How Were These Results Generatd?

The results were generated using the `testing/loadtest.py` script. We ran three trials, each trial sent 10,000 sms prediction requests, sampled at random from `testing/SMSSpamCollection`, using three workers.

During the first trial (`v1-only.png`), requests were only sent to v1 (`url1` in `loadtest.py` was modified to `team14.local/sms`):
```bash
python3 loadtest.py -c 10000 -w 3 --skip-canary
```

During the second trial (`v2-only.png`), requests were only sent to v2:
```bash
python3 loadtest.py -c 10000 -w 3 --skip-istio
```

During the third trial (`v1-and-v2`), requests were sent to both v1 and v2 using a 50/50 traffic distribution ratio:
```bash
python3 loadtest.py -c 10000 -w 3
```
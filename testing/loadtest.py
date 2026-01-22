import requests
import random
from argparse import ArgumentParser
import threading
from pathlib import Path

parser = ArgumentParser()
parser.add_argument("-c", "--count", help="How much should we spam?", default=1000, type=int)
parser.add_argument("-w", "--workers", default=5, type=int, help="How many workers per url")
parser.add_argument("--skip-canary", action="store_true", help="include to not send requests to canary")
parser.add_argument("--skip-istio", action="store_true", help="include to not send requests to istio")
parser.add_argument("-u", "--unique", default=1000, help="configure the unique amount of messages to choose from")
args = parser.parse_args()

url1 = "http://istio.team14.local/sms/"
url2 = "http://canary.team14.local/sms/"
count = args.count

file = open(Path(__file__).resolve().parent / "SMSSpamCollection")

messages = file.read().splitlines()
messages = random.sample(messages, min(args.unique, len(messages)))
file.close()
guess = ["ham", "spam"]

stop_event = threading.Event()

def send(url):
  for i in range(count):
    if stop_event.is_set():
      return
    msg = {
      "sms": random.choice(messages),
      "guess": random.choice(["ham", "spam"]),
    }
    try:
      requests.post(url, json=msg, timeout=2)
    except:
      pass

# Start threads for each worker
threads = []
for i in range(args.workers):
  if not args.skip_istio:
    t = threading.Thread(target=send, args=(url1,))
    threads.append(t)
  if not args.skip_canary:    
    t = threading.Thread(target=send, args=(url2,))
    threads.append(t)
  
print("Spamming services")
try:
  # Start each thread
  for t in threads:
    t.start()

  # Wait for all threads to finish
  for t in threads:
    t.join()
except KeyboardInterrupt:
  print("\nStopping...")
  stop_event.set()
  for t in threads:
    t.join()
print("Finished spamming!")

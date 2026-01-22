import requests
import random
from argparse import ArgumentParser
import threading

parser = ArgumentParser()
parser.add_argument("-c", "--count", help="How much should we spam?", default=1000, type=int)
parser.add_argument("-w", "--workers", default=5, type=int, help="How many workers per url")
args = parser.parse_args()

url1 = "http://istio.team14.local/sms/"
url2 = "http://canary.team14.local/sms/"
count = args.count

messages = [
  "Example SMS ...",
  "Hot Babes",
  "Hi I'm a nigerian prince...",
  "Can you buy me milk when you go to the store?",
  "wyd",
  "random text",
  "Would you like to make free money?!",
  "DODA be cool",
  "this might be spam. youll never know",
  "430427fsdsajb234",
  "Be like water",
  "MORE AND MORE AND MORE AND MORE AND MORE",
  "the cake is a lie",
  "BUY NOW! Get your supreme ultra deluxe vacuum cleaner now!"
]
guess = ["ham", "spam"]

def send(url):
    for i in range(count):
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
  t = threading.Thread(target=send, args=(url1,))
  threads.append(t)
  t = threading.Thread(target=send, args=(url2,))
  threads.append(t)
  
print("Spamming services")
# Start each thread
for t in threads:
    t.start()

# Wait for all threads to finish
for t in threads:
    t.join()
print("Finished spamming!")

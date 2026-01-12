#!/usr/bin/env bash
set -euo pipefail

IP=$(kubectl get svc -n istio-system istio-ingressgateway | awk 'NR==2 {print $4}')

if [[ "$IP" == "<pending>" || -z "$IP" ]]; then
  echo "First start up the tunnel using 'minikube tunnel'"
  exit 1
fi

kubectl get gateway -A -o json \
  | jq -r '.items[].spec.servers[].hosts[]' \
  | sort -u \
  | while read -r host; do
      if grep -qE "^[[:space:]]*$IP[[:space:]]+$host\$" /etc/hosts; then
        echo "Skipping: $IP $host"
        continue
      fi
      
      if grep -qE "^[[:space:]]*[0-9.]+[[:space:]]+$host\$" /etc/hosts; then
        echo "Updating: $IP $host"
        sudo awk -v ip="$IP" -v h="$host" '
          $2 == h { print ip, h; next }
          { print }
        ' /etc/hosts > /tmp/hosts
        sudo mv /tmp/hosts /etc/hosts
        continue
      fi
      
      echo "Adding: $IP $host"
      sudo awk -v ip="$IP" -v h="$host" '
        { print }
        END { print ip, h }
      ' /etc/hosts > /tmp/hosts
      sudo mv /tmp/hosts /etc/hosts
    done


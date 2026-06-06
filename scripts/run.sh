#!/usr/bin/env bash

if ! command -v gum >/dev/null 2>&1; then
  echo "This script requires gum to be installed"
  exit 1
fi

repoPath=$(git rev-parse --show-toplevel)

required=(
  "core-service"
  "auth-service"
)

opts=(
  "communication-service"
  "delivery-service"
  "visitor-service"
  "reservation-service"
  "event-bus"
)

chosen=$(gum choose --no-limit "${opts[@]}")

services=("${required[@]}")

while IFS= read -r service; do
  [[ -n "$service" ]] && services+=("$service")
done <<<"$chosen"

if gum confirm "Popular banco de dados?"; then
  kitty @ launch \
    --type=tab \
    --title "db:init" \
    --cwd "$repoPath" \
    bash -c "yarn db:init; exec bash"
fi

for service in "${services[@]}"; do
  echo "Running $service"

  kitty @ launch \
    --type=tab \
    --title "$service" \
    --cwd "$repoPath" \
    bash -c "yarn workspace $service start:watch; exec bash"
done

kitty @ launch \
  --type=tab \
  --title "front" \
  --cwd "$repoPath" \
  bash -c "yarn workspace front dev; exec bash"

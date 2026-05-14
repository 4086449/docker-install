#!/bin/bash

# export PORTAINER_API_KEY="ptr_your_token_here"
# export PORTAINER_URL="https://your-portainer:9000"
# ./updateContainers.sh

# Update all running Docker containers managed by Portainer.
# Pulls latest images, then uses the Portainer API to redeploy stacks
# and recreate standalone containers. Cleans up unused images afterwards.

set -euo pipefail

# --- Configuration ---
# Set these variables or export them before running the script.
PORTAINER_URL="${PORTAINER_URL:-https://localhost:9000}"
PORTAINER_API_KEY="${PORTAINER_API_KEY:-}"
PORTAINER_ENDPOINT_ID="${PORTAINER_ENDPOINT_ID:-1}"

if [ -z "$PORTAINER_API_KEY" ]; then
  echo "ERROR: PORTAINER_API_KEY is not set."
  echo "Generate one in Portainer: User Settings -> Access Tokens"
  echo "Export it:  export PORTAINER_API_KEY='your-token-here'"
  exit 1
fi

PORTAINER_API="${PORTAINER_URL}/api"
AUTH_HEADER="X-API-Key: ${PORTAINER_API_KEY}"

# --- Helper functions ---
portainer_get() {
  curl -sk -H "$AUTH_HEADER" "${PORTAINER_API}${1}"
}

portainer_post() {
  curl -sk -X POST -H "$AUTH_HEADER" -H "Content-Type: application/json" "${PORTAINER_API}${1}" ${2:+-d "$2"}
}

portainer_put() {
  curl -sk -X PUT -H "$AUTH_HEADER" -H "Content-Type: application/json" "${PORTAINER_API}${1}" -d "$2"
}

# --- Main ---
REDEPLOYED_STACKS=()

# Get a list of running container IDs
running_containers=$(docker ps -q)

if [ -z "$running_containers" ]; then
  echo "No running containers found."
  exit 0
fi

echo "=== Pulling latest images for all running containers ==="

declare -A updated_containers

for container_id in $running_containers; do
  container_name=$(docker inspect -f '{{.Name}}' "$container_id" | sed 's/^\///')
  image_name=$(docker inspect -f '{{.Config.Image}}' "$container_id")

  echo "Checking: $container_name ($image_name)"

  pull_output=$(docker pull "$image_name" 2>&1) || true

  if grep -q "Status: Downloaded newer image" <<< "$pull_output"; then
    echo "  -> Updated image available"
    updated_containers["$container_id"]="$container_name"
  else
    echo "  -> Up to date"
  fi
done

if [ ${#updated_containers[@]} -eq 0 ]; then
  echo ""
  echo "All containers are already running the latest images."
  echo ""
  echo "=== Cleaning up unused images ==="
  docker image prune -f
  exit 0
fi

echo ""
echo "=== Redeploying updated containers via Portainer API ==="

# Fetch all stacks from Portainer
stacks_json=$(portainer_get "/stacks")

for container_id in "${!updated_containers[@]}"; do
  container_name="${updated_containers[$container_id]}"

  # Check if the container belongs to a compose stack
  compose_project=$(docker inspect -f '{{index .Config.Labels "com.docker.compose.project"}}' "$container_id" 2>/dev/null || echo "")

  if [ -n "$compose_project" ]; then
    # Skip if we already redeployed this stack
    if printf '%s\n' "${REDEPLOYED_STACKS[@]}" 2>/dev/null | grep -qx "$compose_project"; then
      echo "  Stack '$compose_project' already redeployed, skipping $container_name"
      continue
    fi

    # Find the stack ID in Portainer
    stack_id=$(echo "$stacks_json" | grep -o "{[^}]*\"Name\":\"${compose_project}\"[^}]*}" | grep -o '"Id":[0-9]*' | head -1 | cut -d: -f2)

    if [ -z "$stack_id" ]; then
      # Try a more robust jq-based lookup if available
      if command -v jq &>/dev/null; then
        stack_id=$(echo "$stacks_json" | jq -r ".[] | select(.Name == \"$compose_project\") | .Id")
      fi
    fi

    if [ -n "$stack_id" ]; then
      echo "  Redeploying stack '$compose_project' (ID: $stack_id) via Portainer API..."

      # Get current stack file content
      stack_file=$(portainer_get "/stacks/${stack_id}/file")
      if command -v jq &>/dev/null; then
        stack_content=$(echo "$stack_file" | jq -r '.StackFileContent')
      else
        stack_content=$(echo "$stack_file" | grep -o '"StackFileContent":"[^"]*"' | cut -d'"' -f4)
      fi

      # Redeploy the stack (pull image + force recreate)
      redeploy_payload=$(cat <<EOF
{
  "env": [],
  "prune": false,
  "pullImage": true,
  "stackFileContent": $(echo "$stack_content" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))' 2>/dev/null || echo "\"$stack_content\"")
}
EOF
)
      response=$(portainer_put "/stacks/${stack_id}?endpointId=${PORTAINER_ENDPOINT_ID}" "$redeploy_payload")

      # Check for errors
      if echo "$response" | grep -q '"Id"'; then
        echo "  -> Stack '$compose_project' redeployed successfully"
      else
        echo "  -> ERROR redeploying stack '$compose_project':"
        if command -v jq &>/dev/null; then
          echo "$response" | jq -r '.message // .details // .' 2>/dev/null || echo "$response"
        else
          echo "     $response"
        fi
      fi

      REDEPLOYED_STACKS+=("$compose_project")
    else
      echo "  WARNING: Could not find stack '$compose_project' in Portainer. Skipping $container_name."
    fi
  else
    # Standalone container — recreate via Portainer API
    echo "  Recreating standalone container: $container_name"

    # Stop the container
    portainer_post "/endpoints/${PORTAINER_ENDPOINT_ID}/docker/containers/${container_id}/stop" >/dev/null 2>&1
    echo "  -> Stopped"

    # Remove the container
    portainer_post "/endpoints/${PORTAINER_ENDPOINT_ID}/docker/containers/${container_id}?force=true" >/dev/null 2>&1 || \
      curl -sk -X DELETE -H "$AUTH_HEADER" "${PORTAINER_API}/endpoints/${PORTAINER_ENDPOINT_ID}/docker/containers/${container_id}?force=true" >/dev/null 2>&1
    echo "  -> Removed"

    echo "  -> NOTE: Redeploy '$container_name' from Portainer UI (standalone containers"
    echo "           cannot be fully recreated via API without their original run config)."
  fi
done

echo ""
echo "=== Cleaning up unused images ==="
docker image prune -af
echo ""
echo "=== Summary ==="
echo "Containers with updated images: ${#updated_containers[@]}"
echo "Stacks redeployed: ${#REDEPLOYED_STACKS[@]}"
for stack in "${REDEPLOYED_STACKS[@]}"; do
  echo "  - $stack"
done

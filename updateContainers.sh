#!/bin/bash

# Function to check if an element exists in an array
contains_element() {
  local e
  for e in "${@:2}"; do
    [[ "$e" == "$1" ]] && return 0
  done
  return 1
}

# Get a list of running container IDs
running_containers=$(docker ps -q)

# Check if there are running containers
if [ -z "$running_containers" ]; then
  echo "No running containers found."
  exit 0
fi

# Loop through the running containers
for container_id in $running_containers; do
  # Get the container name for the container
  container_name=$(docker inspect -f '{{.Name}}' "$container_id" | sed 's/^\///')

  echo "Checking container: $container_name"

  # Get the image name for the container
  image_name=$(docker inspect -f '{{.Config.Image}}' "$container_id")

  # Pull the latest version of the image
  pull_output=$(docker pull "$image_name" 2>&1)

  # Check if the pull output contains "Status: Downloaded newer image"
  if grep -q "Status: Downloaded newer image" <<< "$pull_output"; then
    echo "Image updated for container:                $container_name"

    # Restart the container
#    restarted=$(docker restart $container_name)
#    if [[ $restarted == $container_name ]]; then
#      echo "Container restarted successfully: $restarted"
#      exit 0
#    fi
#  else
#    echo "Image is up to date for container: $container_name"
  fi
done

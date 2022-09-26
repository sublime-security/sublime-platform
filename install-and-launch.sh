#!/usr/bin/env bash

echo "Cloning Sublime Platform repo"
if ! git clone https://github.com/sublime-security/sublime-platform.git;
then
  echo "Failed to clone Sublime Platform repo"
  exit 1
fi

echo "Launching Sublime Platform"
cd sublime-platform || { echo "Failed to cd into sublime-platform"; exit 1; }

./launch-sublime-platform.sh

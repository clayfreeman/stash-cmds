#!/bin/bash

# Ensure that the script is running in bash
if [ -z ${BASH_VERSION} ] || [ ${BASH_VERSION%%[^0-9]*} -lt 4 ]; then
  echo "You must use bash (>= 4.0) to execute this script."
  exit 1
fi

# Ensure that we're running as root
if [ ${EUID} -ne 0 ]; then
  echo "This script must be ran as root."
  exit 1
fi

# Check for required dependencies
for cmd in {bash,cp,cut,df,du,rm,tail,tr,uicache,sync}; do
  if [ -z $(type -P "${cmd}") ]; then
    echo "Could not find the required '${cmd}' command."
    exit 1
  fi
done

# Check for 0 arguments
if [ $# -eq 0 ]; then
  echo "Usage: '${0}' path1 [path2]..."
  exit 1
fi

# Inform the user that this might take a while
echo "This might take a while ..."

# Define the _cleanup function to handle refreshing the UI cache and disk sync
_cleanup() {
  echo "Updating UI Cache ..."
  uicache
  echo "Synchronizing changes to disk ..."
  sync
}

# Define the _stash function to handle stashing directories
_stash() {
  # Remove duplicate slash characters from the path
  STASHPATH=$(echo "${1}" | tr -s /)
  # Remove the trailing slash (if it exists)
  STASHPATH="${STASHPATH%/}"
  # Ensure that the given argument is not already a symlink
  if [ -h "${STASHPATH}" ]; then
    echo "Directory '${STASHPATH}' is already stashed; skipping."
  # If the given argument is a directory, go ahead and stash
  elif [ -d "${STASHPATH}" ]; then
    echo "Stashing '${STASHPATH}' (don't interrupt this process) ..."
    /usr/libexec/cydia/move.sh "${STASHPATH}"
    # Perform a sanity check to determine if the directory was stashed
    if [ -L "${STASHPATH}" ] && [ -d "${STASHPATH}" ]; then
      echo "Successfully stashed '${STASHPATH}'."
      return 0
    # If the directory was not stashed, inform the user of impending doom
    else
      echo "A problem occurred while stashing '${STASHPATH}'."
    fi
  # Refuse to stash if the provided argument is not a directory
  else
    echo "Cannot stash '${STASHPATH}'; not a directory."
  fi
  # Return a failure value by default
  return 1
}

# Define the _unstash function to handle moving directories to their original
# location
_unstash() {
  # Remove duplicate slash characters from the path
  STASHPATH=$(echo "${1}" | tr -s /)
  # Remove the trailing slash (if it exists)
  STASHPATH="${STASHPATH%/}"
  if [ -n "${STASHPATH}" ]; then
    # Iterate over each entry in the stash directory
    for i in /var/stash/*; do
      SOURCE="${i}/${STASHPATH}"
      # Determine if the given argument is stashed at this location
      if [ -d "${SOURCE}" ]; then
        # Determine the original path of the stashed directory
        ORIGINAL=$(< "${i}.lnk")
        # Ensure that the original path still has a symlink to the stash
        # location
        if [ -h "${ORIGINAL}" ]; then
          # Calculate the parent directory name of the original path
          DESTINATION="${ORIGINAL%/*}"
          if [ -z "${DESTINATION}" ]; then
            DESTINATION="/"
          fi
          # Calculate the size of the stashed directory
          SIZE=`du -B1 -d 0 "${SOURCE}" | cut -f 1`
          # Calculate the free space remaining at the destination
          FREE=`df -B1 "${SOURCE}" | tail -n 1 | tr ' ' '\t' | cut -f 4`
          # Ensure that there is room to copy the stashed directory to the
          # destination
          if [ "${SIZE}" -lt "${FREE}" ]; then
            echo "Found stash '${STASHPATH}'; unstashing to '${ORIGINAL}' ..."
            # Remove the symlink to the stash
            rm "${ORIGINAL}" && \
            # Copy the stashed directory to its original location
            cp -r "${SOURCE}" "${DESTINATION}" && \
            # Remove the stashed directory and its
            rm -rf "${i}" && rm -f "${i}.lnk"
            return 0
          else
            echo "Not enough free space to unstash '${STASHPATH}'."
            echo "Try to remove some jailbreak apps and tweaks."
          fi
        # The original path doesn't symlink to the stash location
        else
          echo "The original location of this stash doesn't link to the stash."
        fi
      fi
    done
  else
    echo "Cannot unstash '${STASHPATH}'; not an absolute path."
  fi
  # Return a failure value by default
  return 1
}

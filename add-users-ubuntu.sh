#!/bin/bash
# Variables
GROUPNAME=group04
SHARED=/shared

# Create the group if it doesn't exist
if ! getent group $GROUPNAME > /dev/null; then
  sudo groupadd $GROUPNAME
  if [ $? -ne 0 ]; then
    echo "Failed to create group $GROUPNAME"
    exit 1
  fi
fi
# Create users and add them to the group
# for USERNAME in "${USERNAMES[@]}"; do
for USERNAME in "$@"; do
  # Create the user if it doesn't exist
  if ! id "$USERNAME" &>/dev/null; then
    sudo useradd -m $USERNAME
    if [ $? -ne 0 ]; then
      echo "Failed to create user $USERNAME"
      continue
    fi
  fi

  # Add the user to the group
   sudo usermod -a -G $GROUPNAME $USERNAME
  if [ $? -ne 0 ]; then
    echo "Failed to add user $USERNAME to group $GROUPNAME"
    continue
  fi
    echo "User $USERNAME created and added to group $GROUPNAME successfully"
done
# Set group ownership, permissions and Apply default ACLs

sudo chown -R :$GROUPNAME $SHARED
if [ $? -ne 0 ]; then
  echo "Failed to set group ownership for $SHARED"
  exit 1
fi

sudo chmod -R 2775 $SHARED
if [ $? -ne 0 ]; then
  echo "Failed to set permissions for $SHARED"
  exit 1
fi

sudo chmod g+s $SHARED
if [ $? -ne 0 ]; then
  echo "Failed to set setgid bit for $SHARED"
  exit 1
fi

# Apply default ACLs
sudo setfacl -d -m g:$GROUPNAME:rwx $SHARED
if [ $? -ne 0 ]; then
  echo "Failed to apply default ACLs for $SHARED"
  exit 1
fi

sudo setfacl -R -m g:$GROUPNAME:rwx $SHARED
if [ $? -ne 0 ]; then
  echo "Failed to apply ACLs recursively for $SHARED"
  exit 1
fi

echo "Set group ownership and permissions, and applied default ACLs to group $GROUPNAME successfully"
#!/bin/bash
# Variables
GROUPNAME=group06
SHARED=/shared

# Check if the number of arguments is even
if [ $(( $# % 2 )) -ne 0 ]; then
  echo "Usage: $0 USERNAME1 UID1 USERNAME2 UID2 ..."
  exit 1
fi
# Create the group if it doesn't exist
if ! getent group $GROUPNAME > /dev/null; then
  sudo groupadd $GROUPNAME
  if [ $? -ne 0 ]; then
    echo "Failed to create group $GROUPNAME"
    exit 1
  fi
fi

while [ "$#" -gt 0 ]; do
  USERNAME=$1
  DESIRED_UID=$2

  # Check if the useIRED_r or UID exists
  if id "$USERNAME" &>/dev/null; then
    USER_ID=$(id -u "$USERNAME")
    echo "User $USERNAME already exists with id $USER_ID, each username must be unique."
  elif getent passwd "$DESIRED_UID" &>/dev/null; then
    echo "UID $DESIRED_UID is already in use"
  else
    # Create the user with the specified UID if neither exists
    sudo useradd -m -u $DESIRED_UID $USERNAME
    if [ $? -ne 0 ]; then
      echo "Failed to create user $USERNAME with UID $DESIRED_UID"
    else
      echo "User $USERNAME created with UID $DESIRED_UID"
    fi
  fi
    # Add user to group
   sudo usermod -a -G $GROUPNAME $USERNAME
  if [ $? -ne 0 ]; then
    echo "Failed to add user $USERNAME to group $GROUPNAME"
    continue
  fi
  # Shift to the next pair of arguments
  shift 2
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

#!/bin/bash/
echo "---installing azurecli---"
FILE=/usr/bin/az
if [ -f "$FILE" ]; then
    echo "az already installed"
else
  # curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
  sudo apt-get install -y ca-certificates curl apt-transport-https lsb-release gnupg
  curl -sL https://packages.microsoft.com/keys/microsoft.asc |
      gpg --dearmor |
      sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
  AZ_REPO=$(lsb_release -cs)
  echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" |
      sudo tee /etc/apt/sources.list.d/azure-cli.list
  sudo apt-get update
  sudo apt-get install -y azure-cli
fi
echo "---azurecli done---"

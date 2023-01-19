#!/usr/bin/env bash

# Set some colors.
RED=$(tput setaf 1);
GREEN=$(tput setaf 2);
YELLOW=$(tput setaf 3);
BLUE=$(tput setaf 4);
BOLD=$(tput bold);
RESET=$(tput sgr0);

# Set some variables.
PLATFORM=$(/usr/bin/uname -m)
REPO=bigbite/jetty-pkg-testing # Currently a test repo.
INSTALL_PATH=/usr/local/bin/ # Alternate: $HOME/.local/bin/

# Make sure Mac OS.
if [[ $OSTYPE != 'darwin'* ]]
then
  echo "${BOLD}${YELLOW}Mac OS only supported at this time.${RESET}"
  exit 1
fi

# Make sure arm64 or x86_64 as that is what is generated.
if [[ $PLATFORM != "arm64" ]] && [[ $PLATFORM != "x86_64" ]]
then
  echo "${BOLD}${YELLOW}Only arm64 and x86_64 architecture supported at this time.${RESET}"
  exit 1
fi

# Check for flags.
while getopts v:p: flag
do
    case "${flag}" in
        v) VERSION=${OPTARG};;
        p) INSTALL_PATH=${OPTARG};;
    esac
done

# Check if version entered, if not find latest version.
if [ -z ${VERSION+x} ]
then
  VERSION=$(curl --silent --fail -w '%{http_code}' "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
fi

# Set filenanme to match output of vercel/pkg.
if [[ $PLATFORM == "x86_64" ]]
then
  BINARY="jetty-$VERSION-x64"
elif [[ $PLATFORM == "arm64" ]]
then
  BINARY="jetty-$VERSION-arm64"
fi

# Set the download URL.
DOWNLOAD_URL="https://github.com/$REPO/releases/download/$VERSION/$BINARY"

echo "\n${BOLD}${BLUE}Downloading jetty version: $VERSION ...${RESET}"
echo "${BLUE}==> $DOWNLOAD_URL${RESET}\n"

# Download.
curl -OL $DOWNLOAD_URL -f

# Check if return code is not 0 incase of cURL failure.
RETURN_CODE=$?
if [ $RETURN_CODE -ne 0 ];
then
  echo "\n${BOLD}${RED}ERROR: Failed to download jetty version: $VERSION${RESET}"
  echo "${RED}Please make sure the version exists.${RESET}"
  exit 1
fi

# Make sure the binary is executable.
chmod u+x $BINARY

# Start the install.
echo "\n${BLUE}${BOLD}Installing to $INSTALL_PATH ...${RESET}"

# Check if install path exists, create it if not.
if [ ! -d $INSTALL_PATH ]
then
  mkdir -p $INSTALL_PATH || sudo !!
fi

# If failed to create install path, display error message and exit.
RETURN_CODE=$?
if [ $RETURN_CODE -ne 0 ]
then
  echo "\n${BOLD}${RED}ERROR: Failed to create $INSTALL_PATH${RESET}"
  exit 1
fi

# Move the binary to the install path.
mv -f ${BINARY} ${INSTALL_PATH}jettyy || sudo !!

# If failed to install, display error message and exit.
RETURN_CODE=$?
if [ $RETURN_CODE -ne 0 ]
then
  echo "\n${BOLD}${RED}ERROR: Failed to install to $INSTALL_PATH${RESET}"
  exit 1
fi

echo "\n${GREEN}${BOLD}Successfully installed to $INSTALL_PATH${RESET}"

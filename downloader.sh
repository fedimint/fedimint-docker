# You can run this script with:
# curl -sSL https://raw.githubusercontent.com/fedimint/fedimint-docker/master/downloader.sh | bash

# 1. Check and install docker
DOCKER_COMPOSE="docker compose"
check_and_install_docker() {
  echo "Checking docker and other required dependencies..."
  # Check if Docker is installed
  if ! [ -x "$(command -v docker)" ]; then
    # Check if we are running as root
    if [ "$EUID" -ne 0 ]; then
      echo 'Error: Docker is not installed and we cannot install it for you without root privileges.' >&2
      exit 1
    fi

    # Install Docker using Docker's convenience script
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
  fi

  # Check if Docker Compose plugin is available
  if ! docker compose version >/dev/null 2>&1; then
    echo 'Error: Docker Compose plugin is not available. Please install it manually.' >&2
    exit 1
  fi

  echo "Docker and Docker Compose are ready."
}
check_and_install_docker

# 2. Check if fedimint-docker service dir exists
INSTALL_DIR="fedimint-service"
if [ -d "$INSTALL_DIR" ]; then
  echo "Directory $INSTALL_DIR exists. Please remove it before running this script again."
  exit 1
fi

# 3. Selectors for Install Type:
FEDIMINT_SERVICE=""
# 3a. Guardian or Gateway
select_guardian_or_gateway() {
  echo
  echo "Install a Fedimint Guardian or a Lightning Gateway?"
  echo
  echo "1. Fedimint Guardian"
  echo "2. Lightning Gateway"
  echo
  read -p "Enter your choice (1 or 2): " install_type
  while true; do
    case $install_type in
    1)
      FEDIMINT_SERVICE="guardian"
      break
      ;;
    2)
      FEDIMINT_SERVICE="gateway"
      break
      ;;
    *) echo "Invalid choice. Please enter 1 or 2." ;;
    esac
  done
}

# 3b. Mainnet or Mutinynet
select_mainnet_or_mutinynet() {
  echo
  echo "Run on Mainnet or Mutinynet?"
  echo
  echo "1. Mainnet"
  echo "2. Mutinynet"
  echo
  read -p "Enter your choice (1 or 2): " mainnet_or_mutinynet
  while true; do
    case $mainnet_or_mutinynet in
    1)
      FEDIMINT_SERVICE=$FEDIMINT_SERVICE+"_mainnet"
      break
      ;;
    2)
      FEDIMINT_SERVICE=$FEDIMINT_SERVICE+"_mutinynet"
      break
      ;;
    *) echo "Invalid choice. Please enter 1 or 2." ;;
    esac
  done
}

# 3c-guardian. Bitcoind or Esplora
select_bitcoind_or_esplora() {
  echo
  echo "Run with Bitcoind or Esplora?"
  echo
  echo "1. Bitcoind"
  echo "2. Esplora"
  echo
  read -p "Enter your choice (1 or 2): " bitcoind_or_esplora
  while true; do
    case $bitcoind_or_esplora in
    1)
      FEDIMINT_SERVICE=$FEDIMINT_SERVICE+"_bitcoind"
      break
      ;;
    2)
      FEDIMINT_SERVICE=$FEDIMINT_SERVICE+"_esplora"
      break
      ;;
    *) echo "Invalid choice. Please enter 1 or 2." ;;
    esac
  done
}

# 3c-gateway. New or Existing LND
select_local_or_remote_lnd() {
  echo
  echo "Connect to a remote LND node or start a new LND node on this machine?"
  echo
  echo "1. Remote"
  echo "2. Local"
  echo
  read -p "Enter your choice (1 or 2): " local_or_remote_lnd
  while true; do
    case $local_or_remote_lnd in
    1)
      FEDIMINT_SERVICE=$FEDIMINT_SERVICE+"_remote"
      break
      ;;
    2)
      FEDIMINT_SERVICE=$FEDIMINT_SERVICE+"_local"
      break
      ;;
    *) echo "Invalid choice. Please enter 1 or 2." ;;
    esac
  done
}

# 3d-guardian. New or Existing Bitcoind
select_local_or_remote_bitcoind() {
  echo
  echo "Run with Local (start a new Bitcoind node) or Remote (connect to an existing Bitcoind node)?"
  echo
  echo "1. Local"
  echo "2. Remote"
  echo
  read -p "Enter your choice (1 or 2): " local_or_remote_bitcoind
  while true; do
    case $local_or_remote_bitcoind in
    1)
      FEDIMINT_SERVICE=$FEDIMINT_SERVICE+"_local"
      break
      ;;
    2)
      FEDIMINT_SERVICE=$FEDIMINT_SERVICE+"_remote"
      break
      ;;
    *) echo "Invalid choice. Please enter 1 or 2." ;;
    esac
  done
}

select_guardian_or_gateway
select_mainnet_or_mutinynet

if [[ "$FEDIMINT_SERVICE" == "guardian"* ]]; then
  select_bitcoind_or_esplora
  if [[ "$FEDIMINT_SERVICE" == *"_bitcoind" ]]; then
    select_local_or_remote_bitcoind
  fi
else
  select_local_or_remote_lnd
fi

# 4. Build the service dir

# 4. Download the docker-compose and .env files

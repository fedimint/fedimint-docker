# You can run this script with:
# bash <(curl -sSf https://raw.githubusercontent.com/fedimint/fedimint-docker/master/downloader.sh)

# 0. Intro
intro() {
  clear
  # Get terminal width
  term_width=$(tput cols)

  # Function to center text
  center_text() {
    local text="$1"
    local padding=$(((term_width - ${#text}) / 2))
    printf "%${padding}s%s\n" "" "$text"
  }

  center_text "=============================================="
  center_text "  Fedimint Docker Service Installer  "
  center_text "=============================================="
  echo

  center_text "This script will:"
  center_text "1. Check and install docker"
  center_text "2. Install a Fedimint service on your machine"
  center_text "3. Help you set up and configure the service's DNS"
  echo

  center_text "You'll need to have a domain name and be able to set the"
  center_text "CNAME records to point to this machine's IP address."
  echo

  center_text "=============================================="
  center_text "               Ready to begin?                "
  center_text "=============================================="
  echo

  read -p "$(center_text "Press Enter to continue or Ctrl+C to cancel...")" </dev/tty
  echo
}
intro

# 1. Check and install docker
DOCKER_COMPOSE="docker compose"
check_and_install_docker() {
  echo "Step 1: Checking docker and other required dependencies..."
  # Check if Docker is installed
  if ! [ -x "$(command -v docker)" ]; then
    # Check if we are running as root
    if [ "$EUID" -ne 0 ]; then
      echo 'Error: Docker is not installed and we cannot install it for you without root privileges.' >&2
      exit 1
    fi

    # Install Docker using Docker's convenience script
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    echo "Docker installed successfully."
  fi

  # Check if Docker Compose plugin is available
  if ! docker compose version >/dev/null 2>&1; then
    echo 'Error: Docker Compose plugin is not available. Please install it manually.' >&2
    exit 1
  fi

  echo "Docker and Docker Compose are ready."
}

# 2. Selectors for Install Type:
FEDIMINT_SERVICE=""
# 2a. Guardian or Gateway
select_guardian_or_gateway() {
  echo "Step 2: Select the type of service to install"
  echo
  echo "Install a Fedimint Guardian or a Lightning Gateway?"
  echo
  echo "1. Fedimint Guardian"
  echo "2. Lightning Gateway"
  echo
  while true; do
    read -p "Enter your choice (1 or 2): " install_type </dev/tty
    case $install_type in
    1)
      FEDIMINT_SERVICE="guardian"
      return
      ;;
    2)
      FEDIMINT_SERVICE="gateway"
      return
      ;;
    *) echo "Invalid choice. Please enter 1 or 2." ;;
    esac
  done
}

# 2b. Mainnet or Mutinynet
select_mainnet_or_mutinynet() {
  echo
  echo "Run on Mainnet or Mutinynet?"
  echo
  echo "1. Mainnet"
  echo "2. Mutinynet"
  echo
  while true; do
    read -p "Enter your choice (1 or 2): " mainnet_or_mutinynet </dev/tty
    case $mainnet_or_mutinynet in
    1)
      FEDIMINT_SERVICE=$FEDIMINT_SERVICE"_mainnet"
      return
      ;;
    2)
      FEDIMINT_SERVICE=$FEDIMINT_SERVICE"_mutinynet"
      return
      ;;
    *) echo "Invalid choice. Please enter 1 or 2." ;;
    esac
  done
}

# 3c-guardian. Bitcoind or Esplora
select_bitcoind_or_esplora() {
  echo
  echo "Step 3: Configure the service"
  echo
  echo "Run with Bitcoind or Esplora?"
  echo
  echo "1. Bitcoind"
  echo "2. Esplora"
  echo
  while true; do
    read -p "Enter your choice (1 or 2): " bitcoind_or_esplora </dev/tty
    case $bitcoind_or_esplora in
    1)
      FEDIMINT_SERVICE=$FEDIMINT_SERVICE"_bitcoind"
      break
      ;;
    2)
      FEDIMINT_SERVICE=$FEDIMINT_SERVICE"_esplora"
      break
      ;;
    *) echo "Invalid choice. Please enter 1 or 2." ;;
    esac
  done
}

# 3c-gateway. New or Existing LND
select_local_or_remote_lnd() {
  echo
  echo "Step 3: Configure the service"
  echo
  echo "Connect to a remote LND node or start a new LND node on this machine?"
  echo
  echo "1. Remote"
  echo "2. Local"
  echo
  while true; do
    read -p "Enter your choice (1 or 2): " local_or_remote_lnd </dev/tty
    case $local_or_remote_lnd in
    1)
      FEDIMINT_SERVICE=$FEDIMINT_SERVICE"_remote"
      break
      ;;
    2)
      FEDIMINT_SERVICE=$FEDIMINT_SERVICE"_local"
      break
      ;;
    *) echo "Invalid choice. Please enter 1 or 2." ;;
    esac
  done
}

# 3d-guardian. New or Existing Bitcoind
select_local_or_remote_bitcoind() {
  echo
  echo "Run with Local (start a new pruned Bitcoind node) or Remote (connect to an existing Bitcoind node)?"
  echo
  echo "1. Local"
  echo "2. Remote"
  echo
  while true; do
    read -p "Enter your choice (1 or 2): " local_or_remote_bitcoind </dev/tty
    case $local_or_remote_bitcoind in
    1)
      FEDIMINT_SERVICE=$FEDIMINT_SERVICE"_local"
      break
      ;;
    2)
      FEDIMINT_SERVICE=$FEDIMINT_SERVICE"_remote"
      break
      ;;
    *) echo "Invalid choice. Please enter 1 or 2." ;;
    esac
  done
}

check_remote_lnd_files() {
  echo "For remote LND, you need to provide the tls.cert and admin.macaroon files."
  echo "Please copy these files to the $INSTALL_DIR directory."
  echo "Once you've moved the files, press Enter to continue."

  while true; do
    read -p "" </dev/tty

    if [ -f "$INSTALL_DIR/tls.cert" ] && [ -f "$INSTALL_DIR/admin.macaroon" ]; then
      echo "Files found successfully. Continuing with the installation."
      break
    else
      echo "tls.cert and/or admin.macaroon not found in $INSTALL_DIR."
      echo "Please make sure both files are in the correct location and press Enter to check again."
    fi
  done
}

# 4. Build the service dir and download the docker-compose and .env files
build_service_dir() {
  echo
  echo "Step 4: Downloading the docker-compose and .env files"
  echo
  echo "Creating directory $INSTALL_DIR..."
  mkdir -p "$INSTALL_DIR"
  BASE_URL="https://raw.githubusercontent.com/fedimint/fedimint-docker/master/configurations/$FEDIMINT_SERVICE"

  echo "Downloading from $BASE_URL"
  echo "Downloading docker-compose.yaml..."
  curl -sSL "$BASE_URL/docker-compose.yaml" -o "$INSTALL_DIR/docker-compose.yaml"

  echo "Downloading .env file..."
  curl -sSL "$BASE_URL/.env" -o "$INSTALL_DIR/.env"

  echo "Files downloaded successfully."

  if [[ "$FEDIMINT_SERVICE" == *"_lnd_remote" ]]; then
    check_remote_lnd_files
  fi
}

# INSTALLER
installer() {
  check_and_install_docker
  select_guardian_or_gateway
  select_mainnet_or_mutinynet
  if [[ "$FEDIMINT_SERVICE" == "guardian"* ]]; then
    select_bitcoind_or_esplora
    if [[ "$FEDIMINT_SERVICE" == *"_bitcoind" ]]; then
      select_local_or_remote_bitcoind
    fi
  else # gateway
    select_local_or_remote_lnd
  fi
  build_service_dir
}

# 5. Set env vars
set_env_vars() {
  echo
  echo "Step 5: Setting environment variables"
  echo
  # Add assume valid in .env if guardian_*_bitcoind_local
  if [[ "$FEDIMINT_SERVICE" == *"_bitcoind_local" ]]; then
    # fetch the latest block hash
    echo "Fetching chain tip block hash for local bitcoind..."
    latest_block_hash=$(curl -sSL https://blockstream.info/api/blocks/tip/hash)
    echo "Latest block hash: $latest_block_hash"
    echo "Setting BITCOIN_ASSUME_VALID=$latest_block_hash"
    echo "BITCOIN_ASSUME_VALID=$latest_block_hash" >>"$INSTALL_DIR/.env"
    echo
  fi
  echo "Setting user input environment variables..."

  # Create a temporary file
  temp_env_file=$(mktemp)

  start_processing=false
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ $line == "### START ENV CONFIGURATION" ]]; then
      start_processing=true
    fi
    if ! $start_processing; then
      echo "$line" >>"$temp_env_file"
      continue
    fi
    if [[ $line == "### END ENV CONFIGURATION" ]]; then
      start_processing=false
      echo "$line" >>"$temp_env_file"
      continue
    fi

    # Print comments
    if [[ $line == \#* ]]; then
      echo "$line"
      echo "$line" >>"$temp_env_file"
      continue
    fi

    # Skip empty lines
    if [[ -z "$line" ]]; then
      echo "" >>"$temp_env_file"
      continue
    fi

    # If it's a variable
    if [[ $line == *=* ]]; then
      # Split the line into variable name and value
      var_name="${line%%=*}"
      var_value="${line#*=}"

      # Remove quotes from the value if present
      var_value="${var_value%\"}"
      var_value="${var_value#\"}"

      # If the variable is not set or empty, prompt for a value
      while [[ -z $var_value ]]; do
        read -p "Enter value for $var_name (cannot be empty): " new_value </dev/tty
        if [[ -n $new_value ]]; then
          var_value=$new_value
        else
          echo "Error: Value cannot be empty. Please try again."
        fi
      done

      # If the variable already had a value, ask if the user wants to change it
      if [[ $var_value != $new_value ]]; then
        read -p "Enter new value for $var_name (or press Enter to keep '$var_value'): " change_value </dev/tty
        if [[ -n $change_value ]]; then
          var_value=$change_value
        fi
      fi

      # Write the updated variable to the temporary file
      echo "$var_name=\"$var_value\"" >>"$temp_env_file"
      echo "Updated $var_name=$var_value"
      echo
    fi
  done <"$INSTALL_DIR/.env"

  # Replace the original .env file with the temporary file
  mv "$temp_env_file" "$INSTALL_DIR/.env"

  echo "Environment variables set."
}

resolve_host() {
  local host=$1
  if [ -x "$(command -v host)" ]; then
    host $host | awk '/has address/ { print $4 ; exit }'
  elif [ -x "$(command -v nslookup)" ]; then
    nslookup $host | awk '/^Address: / { print $2 ; exit }'
  elif [ -x "$(command -v dig)" ]; then
    dig $host | awk '/^;; ANSWER SECTION:$/ { getline ; print $5 ; exit }'
  elif [ -x "$(command -v getent)" ]; then
    getent hosts $host | awk '{ print $1 ; exit }'
  else
    echo "Error: no command found to resolve host $host" >&2
    exit 1
  fi
}

# 6. Verify DNS
verify_dns() {
  EXTERNAL_IP=$(curl -4 -sSL ifconfig.me)
  echo
  echo "Step 6. Setting up TLS certificates and DNS records:"
  echo "Your ip is $EXTERNAL_IP. You __must__ open the port 443 on your firewall to setup the TLS certificates."
  echo "If you are unable to open this port, then the TLS setup and everything else will catastrophically or silently fail."
  echo "So in this case you can not use this script and you must setup the TLS certificates manually or use a script without TLS"
  read -p "Press enter to acknowledge this " -r -n 1 </dev/tty
  echo
  echo "Create an A record via your DNS provider pointing to this machine's ip: $EXTERNAL_IP"
  echo "Once you've set it up, you can continue with the installation"
  read -p "Enter the host_name you set in the environment variables: " host_name
  echo "Verifying DNS..."
  echo
  echo "DNS propagation may take a while and and caching may cause issues,"
  echo "you can verify the DNS mapping in another terminal with:"
  echo "$host_name -> $EXTERNAL_IP"
  echo "Using dig: dig +short $host_name"
  echo "Using nslookup: nslookup $host_name"
  echo
  read -p "Press enter after you have verified them" -r -n 1 </dev/tty
  echo
  while true; do
    error=""
    echo "Checking DNS records..."
    resolved_host=$(resolve_host "$host_name")
    if [[ -z $resolved_host ]]; then
      echo "Error: $host_name does not resolve to anything!"
      error=true
    elif [[ $resolved_host != "$EXTERNAL_IP" ]]; then
      echo "Error: $host_name does not resolve to $EXTERNAL_IP, it resolves to $resolved_host"
      error=true
    fi

    if [[ -z $error ]]; then
      echo "All DNS records look good"
      break
    else
      echo
      echo "Some DNS records are not correct"
      read -p "Check again? [Y/n] " -n 1 -r -a check_again </dev/tty
      if [[ ${check_again[*]} =~ ^[Yy]?$ ]]; then
        continue
      else
        echo
        echo "If you are sure the DNS records are correct, you can continue without checking"
        echo "But if there is some issue with them, the Let's Encrypt certificates will not be able to be created"
        echo "And you may receive a throttle error from Let's Encrypt that may take hours to go away"
        echo "Therefore we recommend you double check everything"
        echo "If you suspect it's just a caching issue, then wait a few minutes and try again. Do not continue."
        echo
        read -p "Continue without checking? [y/N] " -n 1 -r -a continue_without_checking </dev/tty
        echo
        if [[ ${continue_without_checking[*]} =~ ^[Yy]$ ]]; then
          echo "You have been warned, continuing..."
          break
        fi
      fi
    fi
  done
}

# 7. Run the service
run_service() {
  echo "Running the service..."
  cd "$INSTALL_DIR" && source .env && docker compose up -d
}

# 8. If bitcoind is local, wait for it to sync
warn_bitcoind_sync() {
  echo
  echo "WARNING: Your new local bitcoind node is now syncing"
  echo "This may take a while, you can check the progress with:"
  echo "docker exec -it bitcoind bitcoin-cli getblockchaininfo"
  echo
  echo "Once the sync is complete, you can access the service at:"
  echo "https://$host_name"
  echo "And you'll be ready to go!"
  echo
  echo "Thanks for using Fedimint! Please report any issues to https://github.com/fedimint/fedimint/issues"
  echo
}

# MAIN SCRIPT

INSTALL_DIR="fedimint-service"
if [ -d "$INSTALL_DIR" ]; then
  echo "ERROR: Directory $INSTALL_DIR exists."
  echo "You can run the service with: cd $INSTALL_DIR && docker compose up -d"
  echo "If you want to re-run the installer to create a different service,"
  echo "please remove the directory first or run the installer from a fresh directory / machine."
  exit 1
fi

installer
set_env_vars
verify_dns
run_service
if [[ "$FEDIMINT_SERVICE" == *"_local" ]]; then
  warn_bitcoind_sync
fi

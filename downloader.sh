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
  read -p "Enter your choice (1 or 2): " install_type </dev/tty
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

# 2b. Mainnet or Mutinynet
select_mainnet_or_mutinynet() {
  echo
  echo "Run on Mainnet or Mutinynet?"
  echo
  echo "1. Mainnet"
  echo "2. Mutinynet"
  echo
  read -p "Enter your choice (1 or 2): " mainnet_or_mutinynet </dev/tty
  while true; do
    case $mainnet_or_mutinynet in
    1)
      FEDIMINT_SERVICE=$FEDIMINT_SERVICE"_mainnet"
      break
      ;;
    2)
      FEDIMINT_SERVICE=$FEDIMINT_SERVICE"_mutinynet"
      break
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
  read -p "Enter your choice (1 or 2): " bitcoind_or_esplora </dev/tty
  while true; do
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
  read -p "Enter your choice (1 or 2): " local_or_remote_lnd </dev/tty
  while true; do
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
  read -p "Enter your choice (1 or 2): " local_or_remote_bitcoind </dev/tty
  while true; do
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
  else
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
    echo "Fetching chain tip block hash from blockstream.info..."
    latest_block_hash=$(curl -sSL https://blockstream.info/api/blocks/tip/hash)
    echo "Latest block hash: $latest_block_hash"

    read -p "Press Enter to use this block hash for assume valid or input another blockhash: " user_block_hash </dev/tty
    if [ -z "$user_block_hash" ]; then
      block_hash_to_use=$latest_block_hash
    else
      block_hash_to_use=$user_block_hash
    fi

    echo "Setting FM_BITCOIN_ASSUME_VALID=$block_hash_to_use"
    echo "FM_BITCOIN_ASSUME_VALID=$block_hash_to_use" >>"$INSTALL_DIR/.env"
    echo
  fi
  echo "Setting user input environment variables..."

  start_processing=false
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ $line == "### START ENV CONFIGURATION" ]]; then
      start_processing=true
      continue
    fi
    if [[ $line == "### END ENV CONFIGURATION" ]]; then
      break
    fi
    if ! $start_processing; then
      continue
    fi

    # Print comments
    if [[ $line == \#* ]]; then
      echo "$line"
      continue
    fi

    # Skip empty lines
    if [[ -z "$line" ]]; then
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

      # Display the variable name and current value
      echo "Current value of $var_name: $var_value"

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

      # Update the value in the .env file (macOS compatible)
      sed -i '' "s|^$var_name=.*|$var_name=\"$var_value\"|" "$INSTALL_DIR/.env"
      echo "Updated $var_name=$var_value"
      echo
    fi
  done <"$INSTALL_DIR/.env"

  echo "Environment variables set."
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
  echo "Create a DNS record pointing to this machine's ip: $EXTERNAL_IP"
  echo "Once you've set it up, enter the host_name here: (e.g. fedimint.com)"
  read -p "Enter the host_name: " host_name
  echo "Verifying DNS..."
  echo
  echo "DNS propagation may take a while and and caching may cause issues,"
  echo "you can verify the DNS mapping in another terminal with:"
  echo "${host_name[*]} -> $EXTERNAL_IP"
  echo "Using dig: dig +short $host_name"
  echo "Using nslookup: nslookup $host_name"
  echo
  read -p "Press enter after you have verified them" -r -n 1 </dev/tty
  echo
  while true; do
    error=""
    echo "Checking DNS records..."
    resolved_host=$(resolve_host $hose_name)
    if [[ -z $resolved_host ]]; then
      echo "Error: $hose_name does not resolve to anything!"
      error=true
    elif [[ $resolved_host != "$EXTERNAL_IP" ]]; then
      echo "Error: $hose_name does not resolve to $EXTERNAL_IP, it resolves to $resolved_host"
      error=true
    fi

    if [[ -z $error ]]; then
      echo "All DNS records look good"
      break
    else
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
  cd "$INSTALL_DIR" && docker compose up -d
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

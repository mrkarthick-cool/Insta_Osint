#!/usr/bin/env bash
# server.sh — non-root-friendly starter for PHP built-in server
# Usage: ./server.sh [DOCROOT] [PORT]
# Example: ./server.sh public 8080

set -euo pipefail
IFS=$'\n\t'

DOCROOT="${1:-.}"
PORT="${2:-8080}"
HOST="127.0.0.1"

print_banner() {
cat <<'BANNER'

  

░█─── █▀▀█ █▀▀ █▀▀█ █── 　 ░█▀▀▀█ █▀▀ ▀█─█▀ █▀▀ █▀▀█ 
░█─── █──█ █── █▄▄█ █── 　 ─▀▀▀▄▄ █▀▀ ─█▄█─ █▀▀ █▄▄▀ 
░█▄▄█ ▀▀▀▀ ▀▀▀ ▀──▀ ▀▀▀ 　 ░█▄▄▄█ ▀▀▀ ──▀── ▀▀▀ ▀─▀▀
                         
                      LocalServer
               localserver by t.me/Drak24Evil

BANNER
}

# nicer banner if figlet is available
print_fancy_banner() {
  if command -v figlet >/dev/null 2>&1; then
    figlet -w 120 LocalServer || print_banner
    echo "               localserver by t.me/Drak24Evil"
  else
    print_banner
  fi
}

# detect termux
is_termux() {
  # Termux sets $PREFIX and often has 'com.termux' in os-release or uname -o reports Android
  if [ -n "${PREFIX:-}" ] && command -v pkg >/dev/null 2>&1; then
    return 0
  fi
  if [ -f /system/bin/getprop ] 2>/dev/null && uname -o 2>/dev/null | grep -qi android; then
    return 0
  fi
  return 1
}

# Attempt non-root install depending on environment.
# We DO NOT use sudo anywhere.
attempt_install_php_nonroot() {
  echo "php not found — attempting non-root install (only works on environments that allow non-root package install)..."
  if is_termux; then
    echo "Detected Termux-like environment. Trying: pkg install -y php"
    if pkg install -y php; then
      return 0
    else
      echo "pkg install failed."
      return 1
    fi
  fi

  # Try common package managers without sudo. On most distros this will fail with permission error,
  # but we'll try so users that run as root or in special setups can succeed.
  if command -v apt-get >/dev/null 2>&1; then
    echo "Trying: apt-get update && apt-get install -y php"
    if apt-get update -y >/dev/null 2>&1 && apt-get install -y php >/dev/null 2>&1; then
      return 0
    fi
  fi

  if command -v dnf >/dev/null 2>&1; then
    echo "Trying: dnf -y install php"
    if dnf -y install php >/dev/null 2>&1; then
      return 0
    fi
  fi

  if command -v yum >/dev/null 2>&1; then
    echo "Trying: yum -y install php"
    if yum -y install php >/dev/null 2>&1; then
      return 0
    fi
  fi

  if command -v pacman >/dev/null 2>&1; then
    echo "Trying: pacman -Syu --noconfirm php"
    if pacman -Syu --noconfirm php >/dev/null 2>&1; then
      return 0
    fi
  fi

  if command -v apk >/dev/null 2>&1; then
    echo "Trying: apk add php"
    if apk add php >/dev/null 2>&1; then
      return 0
    fi
  fi

  if command -v zypper >/dev/null 2>&1; then
    echo "Trying: zypper --non-interactive install php"
    if zypper --non-interactive install php >/dev/null 2>&1; then
      return 0
    fi
  fi

  # nothing succeeded
  return 1
}

# Print clear manual instructions for systems where installation requires root
print_manual_install_instructions() {
  cat <<INSTR

Automatic non-root installation failed or is not supported on this system.
Common ways to install php (run as root or with sudo):

Debian / Ubuntu:
  sudo apt-get update && sudo apt-get install -y php

Kali Linux (Debian-based):
  sudo apt update && sudo apt install -y php

Fedora:
  sudo dnf install -y php

RHEL / CentOS (yum):
  sudo yum install -y php

Arch Linux:
  sudo pacman -Syu php

Alpine:
  sudo apk add php

OpenSUSE:
  sudo zypper install php

Termux (no sudo required):
  pkg install -y php

If you don't have sudo or root access and cannot install system-wide, consider:
 - using Termux (Android) which supports 'pkg install php' without sudo
 - downloading a portable php binary for your architecture and extracting it in your home directory
 - running a docker container that has php (requires docker access)

INSTR
}

# Start of main
print_fancy_banner

# If php exists, skip installation
if command -v php >/dev/null 2>&1; then
  echo "php is already installed: $(php -v | head -n1)"
else
  if attempt_install_php_nonroot; then
    echo "Installation attempt succeeded."
    if ! command -v php >/dev/null 2>&1; then
      echo "Warning: php still not found in PATH after installation attempt."
      print_manual_install_instructions
      exit 1
    fi
  else
    echo "Could not install php without elevated privileges."
    print_manual_install_instructions
    exit 1
  fi
fi

# show docroot and create if needed
if [ ! -d "$DOCROOT" ]; then
  echo "Docroot '$DOCROOT' not found. Creating..."
  mkdir -p -- "$DOCROOT"
fi

# Check port availability on localhost only
check_port() {
  # prefer ss, fallback to lsof, fallback to netstat
  if command -v ss >/dev/null 2>&1; then
    if ss -tln "( sport = :$PORT )" | grep -q LISTEN; then
      return 1
    fi
  elif command -v lsof >/dev/null 2>&1; then
    if lsof -iTCP -sTCP:LISTEN -P -n | grep -q ":$PORT "; then
      return 1
    fi
  elif command -v netstat >/dev/null 2>&1; then
    if netstat -tln | grep -q ":$PORT "; then
      return 1
    fi
  fi
  return 0
}

if ! check_port; then
  echo "Port $PORT appears to be in use on localhost. Choose another port or stop the process using it."
  echo "Example: ./server.sh \"$DOCROOT\" 8081"
  exit 1
fi

echo
echo "Starting PHP built-in server:"
echo "  document root: $DOCROOT"
echo "  address      : http://$HOST:$PORT"
echo
echo "Press Ctrl+C to stop the server."
echo

# change to docroot and run in foreground (so Ctrl+C stops it)
cd -- "$DOCROOT"
# If user wants to bind to 0.0.0.0 change HOST variable when running script or edit
php -S "${HOST}:${PORT}"

# end
                                                                                
┌──(linuxpo

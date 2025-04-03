#!/bin/sh
set -e # Exit immediately if a command exits with a non-zero status.

# --- Configuration ---
SSL_DIR="/etc/nginx/ssl"
KEY_FILE="$SSL_DIR/nginx.key"
CERT_FILE="$SSL_DIR/nginx.crt"
PEM_FILE="$SSL_DIR/nginx_root_ca.pem" # For ESP32 client
HTPASSWD_FILE="$SSL_DIR/.htpasswd"

# Use environment variables for credentials, with defaults
BASIC_USER="${BASIC_AUTH_USER:-testuser}"
BASIC_PASS="${BASIC_AUTH_PASS:-testpass}"

# --- Get Host IP for Certificate CN ---
# Try to get the IP address from the container's perspective (eth0 usually)
# Fallback to 'localhost' if detection fails
HOST_IP=$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1 || echo "localhost")
echo "Using IP Address for CN: $HOST_IP"

# --- Generate Self-Signed Certificate if not exists ---
if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
  echo "Generating self-signed certificate..."
  openssl req -x509 -nodes -newkey rsa:2048 \
      -keyout "$KEY_FILE" \
      -out "$CERT_FILE" \
      -days 3650 \
      -subj "/C=XX/ST=TestState/L=TestCity/O=TestOrg/OU=TestOU/CN=$HOST_IP" # Use detected IP in CN

  echo "Certificate generated: $CERT_FILE"
  echo "Private key generated: $KEY_FILE"

  # Copy certificate for client use
  cp "$CERT_FILE" "$PEM_FILE"
  echo "Root CA for ESP32 client copied: $PEM_FILE"

else
  echo "Certificate and key already exist. Skipping generation."
  # Ensure PEM file exists if certs are already there
  if [ ! -f "$PEM_FILE" ]; then
    cp "$CERT_FILE" "$PEM_FILE"
    echo "Root CA for ESP32 client copied: $PEM_FILE"
  fi
fi

# --- Generate .htpasswd file if not exists ---
if [ ! -f "$HTPASSWD_FILE" ]; then
  echo "Generating .htpasswd file for user '$BASIC_USER'..."
  # -c creates the file, -b uses password from command line, -p uses plain text (htpasswd will hash it)
  htpasswd -cb "$HTPASSWD_FILE" "$BASIC_USER" "$BASIC_PASS"
  echo ".htpasswd file generated: $HTPASSWD_FILE"
else
  echo ".htpasswd file already exists. Skipping generation."
fi

# Set appropriate permissions (optional, but good practice)
chmod 600 "$KEY_FILE" || true # Allow failure if file doesn't exist yet
chmod 644 "$CERT_FILE" || true
chmod 644 "$PEM_FILE" || true
chmod 644 "$HTPASSWD_FILE" || true

echo "Setup complete. Starting Nginx..."

# Execute the command passed to the entrypoint (nginx -g 'daemon off;')
exec "$@"
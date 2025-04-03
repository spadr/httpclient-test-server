# Raspberry Pi ESP32 Test Server

This repository provides an HTTP/HTTPS test server designed to run on a Raspberry Pi. It serves as a testing target for ESP32 HTTP client libraries like `HttpClient_ESP32_Lib`.

It uses Nginx running inside a Docker container and provides various endpoints to test common HTTP client functionalities.

## Features

*   Provides both HTTP (port 80) and HTTPS (port 443) endpoints.
*   Uses self-signed certificates for HTTPS (generated on first run).
*   Includes endpoints for testing:
    *   Basic GET/POST requests
    *   Redirects (301, 302)
    *   Cookie setting and checking
    *   Basic Authentication
    *   Common HTTP error codes (404, 500, etc.)
    *   Serving large files
    *   Getting the server's certificate

## Prerequisites

*   Raspberry Pi (or any Linux machine) with Docker and Docker Compose installed.
*   Access to the terminal on the Raspberry Pi.

## Setup & Running

1.  **Clone the repository:**
    ```bash
    git clone <your-repository-url>
    cd raspi-esp32-test-server
    ```

2.  **Build and start the server:**
    ```bash
    docker-compose up --build -d
    ```
    *   The first time you run this, it will:
        *   Build a custom Nginx image with necessary tools (`openssl`, `apache2-utils`).
        *   Generate a self-signed certificate and key (`nginx/ssl/nginx.crt`, `nginx/ssl/nginx.key`).
        *   Generate a `.htpasswd` file for Basic Authentication (`nginx/ssl/.htpasswd`) with default credentials (`testuser`/`testpass`).
        *   Copy the generated certificate to `nginx/ssl/nginx_root_ca.pem` for use in your ESP32 client.
        *   Start the Nginx container.

3.  **Find your Raspberry Pi's IP address:**
    You'll need this IP to access the server from your ESP32. Use commands like:
    ```bash
    hostname -I | awk '{print $1}'
    # or
    ip addr show eth0 | grep "inet " # Replace eth0 with wlan0 if using WiFi
    ```

4.  **Use the server:** Access the endpoints listed below using your Raspberry Pi's IP address. For HTTPS, you'll need to trust the self-signed certificate or configure your ESP32 client to use `nginx/ssl/nginx_root_ca.pem` as the root CA.

5.  **Stopping the server:**
    ```bash
    docker-compose down
    ```

## Testing Endpoints

**(Replace `<raspi_ip>` with your Raspberry Pi's IP address)**

**HTTP (Port 80):** `http://<raspi_ip>/`
**HTTPS (Port 443):** `https://<raspi_ip>/`

*   `/`: Basic "Hello" response.
*   `/test/get`: Responds 200 OK to GET requests, 405 otherwise.
*   `/test/post`: Responds 200 OK to POST requests with the request body, 405 otherwise.
*   `/test/redirect/permanent`: Returns a 301 redirect to `/test/redirect/target`.
*   `/test/redirect/temporary`: Returns a 302 redirect to `/test/redirect/target`.
*   `/test/redirect/target`: Target page for redirects.
*   `/test/cookie/set`: Sets two test cookies (`sessionid`, `userdata`).
*   `/test/cookie/check`: Checks if the `sessionid` cookie is received.
*   `/test/auth/basic`: Requires Basic Authentication (user: `testuser`, pass: `testpass`).
*   `/test/error/404`: Returns 404 Not Found.
*   `/test/error/500`: Returns 500 Internal Server Error.
*   `/test/error/403`: Returns 403 Forbidden.
*   `/test/large-response`: Serves the content of `test-data/large_file.bin` (if it exists). Create this file for testing large downloads (e.g., `dd if=/dev/zero of=test-data/large_file.bin bs=1M count=5`).
*   `/cert`: Returns the server's public certificate (`nginx.crt`) as plain text. Useful for client configuration.

## Customization

*   **Basic Auth Credentials:** Modify `nginx/ssl/generate_credentials.sh` to change the default username and password. Remember to run `docker-compose down && docker-compose up --build -d` after changes.
*   **Certificate CN:** The script tries to detect the Pi's IP for the certificate's Common Name (CN). If this fails or you want a specific hostname, modify `generate_credentials.sh`.
*   **Test Data:** Place files in the `test-data/` directory to serve them via endpoints like `/test/large-response`.
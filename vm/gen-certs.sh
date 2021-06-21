#!/bin/bash

if (( $# != 3 )); then
    echo "Usage: $0 <openssl-config> <certdir> <cadir>"
    echo
    echo "Positional arguments"
    echo "  <openssl-config>  OpenSSL configuration file"
    echo "  <certdir>         Destination directory for the generated files"
    echo "  <cadir>           Working directory for the generation process"
    exit 1
fi

set -euxo pipefail
# Generate all X.509 certificates for the tests
# The whole generation is done in a $CADIR to better represent how osbuild-ca
# it.
OPENSSL_CONFIG="$1"
CERTDIR="$2"
CADIR="$3"

# The $CADIR might exist from a previous test (current Schutzbot's imperfection)
rm -rf "$CADIR" || true
mkdir -p "$CADIR" "$CERTDIR"

# Convert the arguments to real paths so we can safely change working directory
OPENSSL_CONFIG="$(realpath "${OPENSSL_CONFIG}")"
CERTDIR="$(realpath "${CERTDIR}")"
CADIR="$(realpath "${CADIR}")"

pushd "$CADIR"
    mkdir certs private
    touch index.txt

    # Generate a CA.
    openssl req -config "$OPENSSL_CONFIG" \
        -keyout private/ca.key.pem \
        -new -nodes -x509 -extensions osbuild_ca_ext \
        -out ca.cert.pem -subj "/CN=osbuild.org"

    # Copy the private key to the location expected by the tests
    cp ca.cert.pem "$CERTDIR"/ca-crt.pem

    # Generate a composer certificate.
    openssl req -config "$OPENSSL_CONFIG" \
        -keyout "$CERTDIR"/composer-key.pem \
        -new -nodes \
        -out /tmp/composer-csr.pem \
        -subj "/CN=org.osbuild.composer/emailAddress=osbuild@example.com" \
        -addext "subjectAltName=IP:10.0.2.2, IP:172.31.0.1"

    openssl ca -batch -config "$OPENSSL_CONFIG" \
        -extensions osbuild_server_ext \
        -in /tmp/composer-csr.pem \
        -out "$CERTDIR"/composer-crt.pem

    # Generate a worker certificate.
    openssl req -config "$OPENSSL_CONFIG" \
        -keyout "$CERTDIR"/worker-key.pem \
        -new -nodes \
        -out /tmp/worker-csr.pem \
        -subj "/CN=org.osbuild.worker/emailAddress=osbuild@example.com" \
        -addext "subjectAltName=IP:10.0.2.2, IP:172.31.0.1"

    openssl ca -batch -config "$OPENSSL_CONFIG" \
        -extensions osbuild_client_ext \
        -in /tmp/worker-csr.pem \
        -out "$CERTDIR"/worker-crt.pem

    # Generate a client certificate.
    openssl req -config "$OPENSSL_CONFIG" \
        -keyout "$CERTDIR"/client-key.pem \
        -new -nodes \
        -out /tmp/client-csr.pem \
        -subj "/CN=client.osbuild.org/emailAddress=osbuild@example.com" \
        -addext "subjectAltName=IP:10.0.2.2, IP:172.31.0.1"

    openssl ca -batch -config "$OPENSSL_CONFIG" \
        -extensions osbuild_client_ext \
        -in /tmp/client-csr.pem \
        -out "$CERTDIR"/client-crt.pem

    # Client keys are used by tests to access the composer APIs. Allow all users access.
    chmod 644 "$CERTDIR"/client-key.pem

popd

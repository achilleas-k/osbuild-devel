#!/usr/bin/env bash

set -euxo pipefail

#
# Prepare a request to be sent to the composer API.
#

REQUEST_FILE="./request.json"
ARCH=$(uname -m)
SNAPSHOT_NAME=$(uuidgen)

case $(set +x; . /etc/os-release; echo "$ID-$VERSION_ID") in
  "rhel-8.4")
    DISTRO="rhel-84"
  ;;
  "rhel-8.2" | "rhel-8.3")
    DISTRO="rhel-8"
  ;;
  "fedora-32")
    DISTRO="fedora-32"
  ;;
  "fedora-33")
    DISTRO="fedora-33"
  ;;
esac

cat > "$REQUEST_FILE" << EOF
{
  "distribution": "$DISTRO",
  "image_requests": [
    {
      "architecture": "$ARCH",
      "image_type": "ami",
      "repositories": $(jq ".\"$ARCH\"" ../osbuild-composer/repositories/"$DISTRO".json),
      "upload_requests": [
        {
          "type": "aws",
          "options": {
            "region": "E",
            "s3": {
              "access_key_id": "X",
              "secret_access_key": "00",
              "bucket": "B"
            },
            "ec2": {
              "access_key_id": "E",
              "secret_access_key": "1",
              "snapshot_name": "N",
              "share_with_accounts": ["A"]
            }
          }
        }
      ]
    }
  ]
}
EOF



exit 0

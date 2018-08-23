set -euo pipefail

apt update -y && apt install -yq curl git

curl -fsSL https://raw.githubusercontent.com/fishworks/gofish/master/scripts/install.sh | bash
gofish init
gofish install hugo

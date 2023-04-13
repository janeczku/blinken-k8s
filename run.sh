#!/bin/bash

DEFAULT_MATRIX_OPTS="--led-no-hardware-pulse --led-cols=64 --led-rows=64 --led-gpio-mapping=adafruit-hat --led-brightness=80"
MATRIX_OPTS=${MATRIX_OPTS:-$DEFAULT_MATRIX_OPTS}

if [ "$DEBUG" = true ]; then
    set -x
fi

# Exit gracefully when container is terminated and send a poweroff message to the Dot Matrix
on_exit(){
    echo "Shutting down"
    timeout -s INT --preserve-status 5 examples-api-use/scrolling-text-example $MATRIX_OPTS -f fonts/6x13.bdf -C 163,36,36 -y 24 -s 0 Poweroff!!!
    exit 0
}

# Mount a static file to "/proc/cpuinfo" to emulate a 32-bit Linux system running on a Raspberry Pi 4.
# Not doing so will fail the hardware check of the RGB Led Matrix library when runnning on a 64-bit Linux.
mount --bind ./rpi4-32bit-cpuinfo.txt /proc/cpuinfo

# Fetch OS Info
source /etc/os-release
OS_SLUG=${NAME:-SLE Micro}
if [ -n "${IMAGE_TAG}" ]
then
    RELEASE=${IMAGE_TAG}
else
    RELEASE=$(uname -r)
fi
OS_INFO="$OS_SLUG $RELEASE"
echo "Host OS: $OS_INFO"

# Fetch K8s Info
TOKEN=$(cat /run/secrets/kubernetes.io/serviceaccount/token)
K8S_VERSION=$(curl -sS -H "Authorization: Bearer $TOKEN" --cacert /run/secrets/kubernetes.io/serviceaccount/ca.crt https://kubernetes.default/version | jq -r .gitVersion)
if [ -z "$K8S_VERSION" ]
then
      K8S_VERSION="Unknown"
fi
K8S_INFO="K8s $K8S_VERSION"
echo $K8S_INFO

# Run Animation
echo "Playing Logo Animation on Dot Matrix Display"
utils/led-image-viewer $MATRIX_OPTS -C -l 1 assets/elemental-logo-animation.stream

# Capture SIGTERM signal from Container Runtime
trap 'on_exit' SIGTERM
# Loop forever ever
echo "Displaying OS & K8s Information in a Loop"
while sleep 0.1
do
    examples-api-use/scrolling-text-example $MATRIX_OPTS -f fonts/7x13.bdf -C 3,152,252 -y 24 -l 1 $OS_INFO
    sleep 0.1
    examples-api-use/scrolling-text-example $MATRIX_OPTS -f fonts/7x13.bdf -C 3,152,252 -y 24 -l 1 $K8S_INFO
    sleep 0.1
    if [ -n "${CLUSTER_NAME}" ]
    then
        examples-api-use/scrolling-text-example $MATRIX_OPTS -f fonts/7x13.bdf -C 3,152,252 -y 24 -l 1 Cluster: $CLUSTER_NAME
        sleep 0.1
    fi
    # Scroll Logo for 5 seconds
    timeout -s INT --preserve-status 5 examples-api-use/demo -D1 $MATRIX_OPTS assets/elemental-64x64.ppm
done

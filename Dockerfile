FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt update -y && apt install -y \
 build-essential \
 git \
 jq \
 curl \
 python3 \
 python3-pip \
 python3-dev \
 python3-distutils \
 libgraphicsmagick++-dev \
 libwebp-dev

WORKDIR /usr/src/app

# RGB LED Matrix Python bindings and utils
RUN cd /usr/src/app && git clone https://github.com/hzeller/rpi-rgb-led-matrix/
RUN cd rpi-rgb-led-matrix \
 && make build-python PYTHON=$(command -v python3) \
 && make install-python PYTHON=$(command -v python3) \
 && make -C examples-api-use \
 && make -C utils led-image-viewer

WORKDIR /usr/src/app/rpi-rgb-led-matrix

COPY run.sh /usr/src/app/rpi-rgb-led-matrix
RUN mkdir -p /usr/src/app/rpi-rgb-led-matrix/assets
COPY assets /usr/src/app/rpi-rgb-led-matrix/assets

CMD ["/usr/src/app/rpi-rgb-led-matrix/run.sh"]

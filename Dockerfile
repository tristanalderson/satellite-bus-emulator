FROM debian:12-slim

ARG DEBIAN_FRONTEND=noninteractive
ARG USER_ID=1000
ARG GROUP_ID=1000

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential chrpath cpio debianutils diffstat file gawk git \
    iputils-ping locales python3 python3-git python3-jinja2 lz4 \
    python3-pexpect python3-pip python3-subunit socat texinfo unzip wget xz-utils zstd sudo \
    cmake python3-venv tmux curl ripgrep clangd ssh \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --break-system-packages --upgrade fprime-bootstrap

RUN sed -i '/en_US.UTF-8/s/^# //' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

RUN groupadd -g ${GROUP_ID} yocto && \
    useradd -u ${USER_ID} -g ${GROUP_ID} -ms /bin/bash yocto && \
    echo "yocto ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# dev env
RUN echo "export PATH=/home/yocto/nvim/bin:\$PATH" >> /home/yocto/.bashrc

USER yocto
WORKDIR /home/yocto/yocto-build
CMD ["/bin/bash"]

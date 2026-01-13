# syntax=docker/dockerfile:1.3-labs
ARG ALPINE_VERSION=3.23
FROM alpine:${ALPINE_VERSION} as builder

ARG USERNAME=alpine
ARG GROUPNAME=alpine

# Add the dependencies
RUN echo "https://dl-cdn.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories && \
    apk update --quiet && \
    apk add --no-progress --no-cache zsh tzdata git libstdc++ doas iproute2 gnupg socat openssh openrc docker docker-compose buildkit rsync && \
    rm -rf `find /var/cache/apk/ -type f`

# Configuration
RUN --mount=type=bind,target=/conf sed -ie '/^root:/ s#:/bin/.*$#:/bin/zsh#' /etc/passwd && \
    mkdir -p /lib/rc/init.d && \
    touch /etc/subuid && touch /etc/subgid && \
    ln -s /lib/rc/init.d /run/openrc && \
    touch /lib/rc/init.d/softlevel && \
    install -m 644 -o root -g root /conf/rc.conf /etc/rc.conf && \
    install -m 644 -o root -g root /conf/wsl.conf /etc/wsl.conf && \
    rc-update add docker default && \
    rc-update add buildkitd default && \
    sed -ie '/^DOCKER_OPTS=/ s#.*#DOCKER_OPTS="--host=tcp://0.0.0.0:2375 --host=unix://"#' /etc/conf.d/docker


# Add Oh-my-zsh
RUN --mount=type=bind,target=/conf git clone --quiet --depth 1 https://github.com/ohmyzsh/ohmyzsh.git /usr/share/oh-my-zsh && \
    sed -i -e 's#^export ZSH=.*#export ZSH=/usr/share/oh-my-zsh#g' /usr/share/oh-my-zsh/templates/zshrc.zsh-template && \
    git clone --quiet --depth=1 https://github.com/romkatv/powerlevel10k.git /usr/share/oh-my-zsh/custom/themes/powerlevel10k && \
    git clone --quiet --depth=1  https://github.com/zsh-users/zsh-autosuggestions "/usr/share/oh-my-zsh/custom/plugins/zsh-autosuggestions" && \
    sed -ie '/^plugins=/ s#.*#plugins=(git zsh-autosuggestions)#' /usr/share/oh-my-zsh/templates/zshrc.zsh-template && \
    sed -ie '/^ZSH_THEME=/ s#.*#ZSH_THEME="powerlevel10k/powerlevel10k"#' /usr/share/oh-my-zsh/templates/zshrc.zsh-template && \
    echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> /usr/share/oh-my-zsh/templates/zshrc.zsh-template && \
    mkdir -p /etc/skel && \
    install -m 700 -o root -g root /usr/share/oh-my-zsh/templates/zshrc.zsh-template /etc/skel/.zshrc  && \
    install -m 600 -o root -g root /conf/p10k.zsh /etc/skel/.p10k.zsh && \
    install --directory -o root -g root -m 0700 /etc/skel/.ssh && \
    install -m 700 -o root -g root /usr/share/oh-my-zsh/templates/zshrc.zsh-template /root/.zshrc && \
    install --directory -o root -g root -m 0700 /root/.ssh && \
    install -m 600 -o root -g root /etc/skel/.p10k.zsh /root/.p10k.zsh && \
    (gpg -k && gpgconf --kill keyboxd || /bin/true) >/dev/null 2>&1


# Add non-root user
RUN adduser -s /bin/zsh -g ${USERNAME} -D ${GROUPNAME} && \
    addgroup ${USERNAME} wheel && \
    addgroup ${USERNAME} docker && \
    echo "permit nopass keepenv :wheel" >> /etc/doas.d/doas.conf && \
    install --directory -o ${USERNAME} -g ${GROUPNAME} -m 0700 /home/${USERNAME}/.ssh && \
    install --directory -o ${USERNAME} -g ${GROUPNAME} -m 0700 /home/${USERNAME}/.docker && \
    echo '{"experimental": "enabled"}' > /home/${USERNAME}/.docker/config.json && \
    echo "Host *" > /home/${USERNAME}/.ssh/config && echo " StrictHostKeyChecking no" >> /home/${USERNAME}/.ssh/config && \
    chown -R ${USERNAME}:${GROUPNAME} /home/${USERNAME}/.ssh /home/${USERNAME}/.docker && \
    su -l ${USERNAME} -c "gpg -k && gpgconf --kill keyboxd || /bin/true" >/dev/null 2>&1 && \
    sed -ie "/^default =/ s#.*#default = \"${USERNAME}\"\n#" /etc/wsl.conf

# Flatten the image
FROM scratch
ARG USERNAME=alpine

COPY --from=builder / /

# The following command adds one layer to the image
# WORKDIR /home/${USERNAME}
USER ${USERNAME}

# Run shell by default. Allows using the docker image
CMD /bin/zsh

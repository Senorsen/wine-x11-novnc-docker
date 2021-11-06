FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive
ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

RUN sed -i -E 's/(archive|security).ubuntu.com/mirrors.ustc.edu.cn/' /etc/apt/sources.list
RUN dpkg --add-architecture i386
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates python2 python-is-python2 xvfb x11vnc xdotool wget tar xz-utils unzip supervisor net-tools fluxbox gnupg2
RUN wget -O - https://dl.winehq.org/wine-builds/winehq.key | apt-key add -  && \
    echo 'deb https://dl.winehq.org/wine-builds/ubuntu/ focal main' > /etc/apt/sources.list.d/winehq.list
ENV WINE_APT_VERSION 6.0.2~focal-1
RUN apt-get update && apt-get install -y --install-recommends winehq-stable=${WINE_APT_VERSION}

# Wine, mono and gecko versions should correspond.
ENV WINE_MONO_VERSION 5.1.1
RUN mkdir -p /usr/share/wine/mono && wget -O - https://dl.winehq.org/wine/wine-mono/${WINE_MONO_VERSION}/wine-mono-${WINE_MONO_VERSION}-x86.tar.xz | tar -xJv -C /usr/share/wine/mono
ENV WINE_GECKO_VERSION 2.47.2
RUN mkdir /opt/wine-stable/share/wine/gecko && wget -O /opt/wine-stable/share/wine/gecko/wine-gecko-${WINE_GECKO_VERSION}-x86.msi https://dl.winehq.org/wine/wine-gecko/${WINE_GECKO_VERSION}/wine-gecko-${WINE_GECKO_VERSION}-x86.msi
RUN wget -O /opt/wine-stable/share/wine/gecko/wine-gecko-${WINE_GECKO_VERSION}-x86_64.msi https://dl.winehq.org/wine/wine-gecko/${WINE_GECKO_VERSION}/wine-gecko-${WINE_GECKO_VERSION}-x86_64.msi

ENV WINETRICKS_VERSION 20210825
ADD https://github.com/Winetricks/winetricks/raw/${WINETRICKS_VERSION}/src/winetricks /usr/local/bin/winetricks
RUN chmod 755 /usr/local/bin/winetricks

ENV WINEARCH win32
ENV DISPLAY :0

WORKDIR /opt/
ENV NOVNC_VERSION 1.3.0
ENV WEBSOCKIFY_VERSION 0.10.0
RUN wget -O - https://github.com/novnc/noVNC/archive/v${NOVNC_VERSION}.tar.gz | tar -xzv -C /opt/ && mv /opt/noVNC-${NOVNC_VERSION} /opt/novnc && ln -s /opt/novnc/vnc.html /opt/novnc/index.html && \
    wget -O - https://github.com/novnc/websockify/archive/v${WEBSOCKIFY_VERSION}.tar.gz | tar -xzv -C /opt/ && mv /opt/websockify-${WEBSOCKIFY_VERSION} /opt/novnc/utils/websockify

EXPOSE 8080
ENV RESOLUTION 1280x720x24

ENV USER wine
ENV HOME /home/${USER}
ENV UID 1000
ENV GID 0
ENV HOME /home/${USER}
RUN useradd -g ${GID} -u ${UID} -r -d ${HOME} -s /bin/bash ${USER} && \
    echo "${USER}:${USER}" | chpasswd && \
    mkdir -p ${HOME} && \
    chown -R ${USER}: ${HOME}
WORKDIR ${HOME}
ENV WINEPREFIX ${HOME}/prefix32

ENV VNC_PASSWORD ""
# In case of wine's verbose logs.
ENV WINE_STDOUT /dev/null

# Fix stdout and stderr permissions
RUN chmod 666 /dev/stdout && \
    chmod 666 /dev/stderr
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord"]

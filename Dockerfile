FROM ubuntu:18.04

LABEL title="Valheim - Dockerized dedicated server" \
	maintainer="Christian Bargmann <chris@cbrgm.net>" \
	url="https://cbrgm.net" \
	twitter="@chrisbargmann"

LABEL UPDATE_ON_RESTART="If set to 1, check for available updates on startup and install when found." \
	SERVER_NAME="The server name to be displayed in the multiplayer browser menu. Example: ValheimServer" \
	SERVER_PORT="The server port to bind on. Example: 2456" \
	SERVER_WORLD="The server's world name. Example: Valhalla" \
	SERVER_PASSWORD="The server's password. Example: secret"

ENV UPDATE_ON_RESTART=1 \
	SERVER_NAME="ValheimServer" \
	SERVER_PORT="2456" \
	SERVER_WORLD="Valhalla" \
	SERVER_PASSWORD="secret"

COPY docker-entrypoint.sh /usr/local/bin/

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG DEBIAN_FRONTEND=noninteractive
RUN  echo steam steam/question select "I AGREE" | debconf-set-selections \
	&& echo steam steam/license note '' | debconf-set-selections \
	&& dpkg --add-architecture i386 \
 	&& apt-get -yq update \
	&& apt-get upgrade -yq \
	&& apt-get install -yq locales ca-certificates lib32gcc1 steamcmd \
	&& echo 'LANG="en_US.UTF-8"' > /etc/default/locale \
	&& echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
	&& locale-gen \
	&& apt-get clean \
	&& ln -s /usr/games/steamcmd /usr/bin/steamcmd \
	&& steamcmd +quit \
	&& useradd --create-home valheim --shell /bin/bash --comment valheim \
	&& mkdir -p /home/valheim/server /home/valheim/.config/unity3d/IronGate /data \
	&& ln -s /data /home/valheim/.config/unity3d/IronGate/Valheim \
	&& chown valheim:valheim /usr/local/bin/docker-entrypoint.sh \
	&& chown -R valheim:valheim /home/valheim \
	&& chown valheim:valheim /data

USER valheim
EXPOSE 2456/udp 2457/udp 2458/udp

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

WORKDIR /home/valheim
CMD SteamAppId=892970 LD_LIBRARY_PATH="/home/valheim/server/linux64/" \
	/home/valheim/server/valheim_server.x86_64 \
	-name ${SERVER_NAME} \
 	-world ${SERVER_WORLD} \
	-password ${SERVER_PASSWORD} \
	-public 1 \
	-port ${SERVER_PORT}

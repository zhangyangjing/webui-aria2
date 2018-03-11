FROM debian:8

# less priviledge user, the id should map the user the downloaded files belongs to
RUN groupadd -r dummy && useradd -r -g dummy dummy -u 1000

# webui + aria2
RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list \
    && sed -i 's|security.debian.org|mirrors.ustc.edu.cn/debian-security|g' /etc/apt/sources.list \
    && apt-get update \
	&& apt-get install -y aria2 busybox curl unzip \
	&& rm -rf /var/lib/apt/lists/*

ADD . /webui-aria2

# gosu install latest
RUN GITHUB_REPO="https://github.com/tianon/gosu" \
  && LATEST=`curl -s  $GITHUB_REPO"/releases/latest" | grep -Eo "[0-9].[0-9]*"` \
  && curl -L $GITHUB_REPO"/releases/download/"$LATEST"/gosu-amd64" > /usr/local/bin/gosu \
  && chmod +x /usr/local/bin/gosu

# goreman supervisor install latest
RUN GITHUB_REPO="https://github.com/mattn/goreman" \
  && LATEST=`curl -s  $GITHUB_REPO"/releases/latest" | grep -Eo "v[0-9]*.[0-9]*.[0-9]*"` \
  && curl -L $GITHUB_REPO"/releases/download/"$LATEST"/goreman_linux_amd64.zip" > goreman.zip \
  && unzip goreman.zip && mv /goreman /usr/local/bin/goreman && rm -R goreman*

# goreman setup
RUN echo "web: gosu dummy /bin/busybox httpd -f -p 8080 -h /webui-aria2\nbackend: gosu dummy /usr/bin/aria2c --conf-path=/webui-aria2/aria2.conf" > Procfile

# aria2 downloads directory
VOLUME /data

# aria2 RPC port, map as-is or reconfigure webui
EXPOSE 6800/tcp

# webui static content web server, map wherever is convenient
EXPOSE 8080/tcp

CMD ["start"]
ENTRYPOINT ["/usr/local/bin/goreman"]

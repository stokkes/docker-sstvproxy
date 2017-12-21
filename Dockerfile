FROM lsiobase/alpine:3.7

LABEL maintainer="stokkes@gmail.com"

RUN \
	apk update && \
	apk add --no-cache \
		python3 \
		python3-tkinter \
		ffmpeg \
		jq \
		git \
		curl && \
	pip3 install flask requests 

# add local files
COPY root/ /

# ports and volumes
VOLUME /config
EXPOSE 8098 8099

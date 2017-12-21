# Yet Another Proxy (YAP) for SmoothStreams.tv Docker Image

## Usage

```
docker create \
        --name sstvproxy \
        --hostname sstvproxy \
        -p 8098:8098 -p 8099:8099 \
        -e PUID=<UID> -e PGID=<GID> \
        -e TZ=<timezone> \
        -e YAP_USERNAME=<username> -e YAP_PASSWORD=<password> \
	    -e YAP_SERVICE=<short_code_for_smoothstreams_service> \
        -v </path/to/appdata>:/config \
        stokkes/sstvproxy
```

This container is based on alpine linux with s6 overlay from [LinuxServer](http://linuxserver.io). For shell access whilst the container is running do docker exec -it sstvproxy /bin/bash.

Currently only the master branch is available from YAP.

## Parameters

`The parameters are split into two halves, separated by a colon, the left hand side representing the host and the right the container side. 
For example with a port -p external:internal - what this shows is the port mapping from internal to external of the container.
So -p 8080:80 would expose port 80 from inside the container to be accessible from the host's IP on port 8080
http://192.168.x.x:8080 would show you what's running INSIDE the container on port 80.`

So INSIDE the container, 8098 is mapped to the local port and 8099 is mapped to the external port. You can map those to your host on any port you want. The right side of the colon must always be 8098/8099 or this container won't work.

* `-p 8098` - YAP exposed local port
* `-p 8099` - YAP exposed external port
* `-v /config` - YAP App data (settings files and cache)
* `-e PGID` for GroupID - see below for explanation
* `-e PUID` for UserID - see below for explanation
* `-e TZ` for timezone EG. Europe/London, America/NewYork
* `-e YAP_GIT_BRANCH` for specifying which branch to use (`master` or `dev`), defaults to `master` if not set
* `-e YAP_SERVICE` for code for SS service EG. `viewms`, etc.
* `-e YAP_USERNAME` for SS username
* `-e YAP_PASSWORD` for SS password
* `-e YAP_SERVER` for SS server EG. `dnae2`, `dmaw2`, etc.
* `-e YAP_QUALITY` for quality (`1` for HD, `2` for HQ, `3` for SD)
* `-e YAP_STREAM` for stream type (`rtmp` or `hls`) 
* `-e YAP_EXTERNALIP` for specifying external IP to use
* `-e YAP_KODIPORT` for Kodi port

### User / Group Identifiers

Sometimes when using data volumes (`-v` flags) permissions issues can arise between the host OS and the container. We avoid this issue by allowing you to specify the user `PUID` and group `PGID`. Ensure the data volume directory on the host is owned by the same user you specify and it will "just work" ™.

In this instance `PUID=1001` and `PGID=1001`. To find yours use `id user` as below:

```
  $ id <dockeruser>
    uid=1001(dockeruser) gid=1001(dockergroup) groups=1001(dockergroup)
```

## Setting up the application

### config Folder

The `/config` folder in the container contains the two settings files (`proxysettings.json` and `advancedsettings.json`) as well as the `cache` folder. 

You'll notice the app is not in this folder. During the container initialization process, symlinks are created withini the app folder (located in `/app/sstvproxy` in the container).  This is done to allow new versions of YAP without erasing your custom configurations.

### Docker environment variables for YAP

You'll notice there are many environment variables for YAP that you can pass when creating the container. **Environment variables will take precedence over manual changes to `proxysettings.json` and will persist across container restarts**. This means that if you set the `YAP_USERNAME` and `YAP_PASSWORD` for instance when you create the container, these will always be placed in the `proxysettings.json` file, even if you edit the file manually with a text editor. 

If you prefer not having this occur, do not pass any environment variables and instead just edit the proxysettings.json file manually and drop it in your local folder mapped to `/config` inside the container. 

_This behaviour may change at a later time._

### Plex

Refer to vorghahn's [Plex setup image](https://imgur.com/a/OZkN0) as a starting point.

It's recommended you set a `--hostname` for each of your containers to make inter-container communication easier (that way you don't have to use IP addresses). 

1. Login to [Plex Web](https://app.plex.tv/desktop)
2. Click on the settings icon in the top left
3. Click on the `Live TV & DVR` section on the left
4. Click the button to `SETUP PLEX DVR` (or `Add Device` if you had another device already setup)
5. In the popup that appears, click on `Don't see your device? Enter its network address manually`
6. In the Device Address field, enter `http://sstvproxy:8098/sstv` (or whatever container name you've given to your docker container) and click `Connect`
7. The `Continue` button should turn orange, allowing you to continue. Click `Continue`
8. In the nex screen, ensure `Cable` is selected on the left and choose your country. Then click `Continue`
9. You'll now setup the Electronic Program Guide (EPG), click on `Have an XMLTV program guide on your server? Click here to use that instead`.
10. In the XMLTV PROGRAM GUIDE field, enter `http://sstvproxy:8098/sstv/epg.xml` (or whatever container name you've given to your docker container) and click `Continue`
11. **NB:** It's possible you receive an error: `Invalid or missing file`. If that's the case, click `Previous` and try again. It should work after a few attempts
12. On the next DVR Setup screen, click `Continue` (or if there are any channels you don't want, de-select them from the list first).
13. Your setup is complete. Plex will pull in the EPG data which could take a few minutes.

## Example configurations

### Plex (with docker-compose)

Docker-compose is a quick way to get containers up and running in a project together. They are all linked on the same docker network and it's easy to group containers together (i.e.:, Plex, this image, sonarr, radarr, etc.)

This is the easiest way to get going. Below is an example `docker-compose.yml` version 2 file. 

```
version: '2'
services:
  plex:
    container_name: plex
    hostname: plex
    image: plexinc/pms-docker
    restart: unless-stopped
    ports:
      - 32400:32400/tcp
    environment:
      - TZ=America/Toronto
      - PLEX_UID=1000
      - PLEX_GID=1000
    volumes:
      - ./appdata/plex:/config
      - ./appdata/plex/transcode:/transcode
      - /path/to/media:/media
      - /tmp:/tmp

sstvproxy:
  container_name: sstvproxy
  hostname: sstvproxy
  image: stokkes/sstvproxy
  restart: unless-stopped
  ports:
    - 8098:8098/tcp
    - 8099:8099/tcp
  environment:
    - TZ=America/Toronto
    - PUID=1000
    - PGID=1000
    - YAP_SERVICE=viewms
    - YAP_USERNAME=USERNAME
    - YAP_PASSWORD=PASSWORD
    - YAP_STREAM=rtmp
    - YAP_QUALITY=1
    - YAP_SERVER=dnae4
  volumes:
    - ./appdata/sstvproxy:/config
```

### Plex (without docker-compose)

If you just want to create a container manually, here's an example command that uses all the variables (change to suit):

```
docker create \
        --name sstvproxy \
        --hostname sstvproxy \
        -p 8098:8098 -p 8099:8099 \
        -e PUID=1000 -e PGID=1000 \
        -e TZ=America/Toronto \
        -e YAP_USERNAME=MYUSERNAME -e YAP_PASSWORD=MYPASSWORD \
	-e YAP_SERVICE=viewms -e YAP_STREAM=rtmp \
        -e YAP_QUALITY=1 -e YAP_SERVER=dnae4 \
        -v /home/user/.config/sstvproxy:/config \
        stokkes/sstvproxy
```

## Versions

**2017-12-21**: Pull latest version from git on create, allow specifying git branch to pull
**2017-12-18**: Initial release

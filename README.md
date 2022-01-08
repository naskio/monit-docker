# monit-docker

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/naskio/monit-docker">
    <img src="https://mmonit.com/monit/img/logo@2x.png" alt="Logo" width="80" height="80">
  </a>

<h3 align="center">monit-docker</h3>
  <p align="center">
    monit setup for docker daemon and containers
    <br />
    <a href="https://github.com/naskio/monit-docker"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/naskio/monit-docker/issues">Report Bug</a>
    ·
    <a href="https://github.com/naskio/monit-docker/issues">Request Feature</a>
  </p>
</div>

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

monitor your docker daemon and containers that are running inside a single host (VPS) using `monit` (will be running in
the host machine)

# Table of Contents

- [Installation](#installation)
    * [Check monit installation](#check-monit-installation)
- [Configuration](#configuration)
    * [Receiving alerts by email](#receiving-alerts-by-email)
    * [collector](#collector)
    * [Monit UI](#monit-ui)
        + [Check UI setup](#check-ui-setup)
    * [Include Monit service configuration](#include-monit-service-configuration)
- [Monit Docker](#monit-docker)
- [Monit docker containers](#monit-docker-containers)
- [M/Monit alternative](#m-monit-alternative)
    * [custom collector](#custom-collector)
    * [Visualizing Monit data](#visualizing-monit-data)
- [Contributing](#contributing)
- [License](#license)
    * [Contact](#contact)
    * [Acknowledgments](#acknowledgments)

<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with
markdown-toc</a></i></small>

# Installation

- Install monit:

```
# Install monit in the host machine
apt update && apt install monit
# chage permissions
cd /etc/monit/
chmod 700 /etc/monit/monitrc
# restart
systemctl restart monit
```

- Enable monit: `systemctl enable monit`

## Check monit installation

```
monit -V
curl -I http://localhost:2812/
```

get services status:

```
monit status
```

# Configuration

Edit `/etc/monit/monitrc` using `vi` or `nano`:

```
nano /etc/monit/monitrc
```

- Add the following lines:

```
set daemon 120 # check every 120 seconds
    with start delay 240 # delay first check

set log /var/log/monit.log

set idfile /var/lib/monit/id

set statefile /var/lib/monit/state

set eventqueue
  basedir /var/lib/monit/events # set the base directory where events will be stored
  slots 100                     # optionally limit the queue size
```

## Receiving alerts by email

add the following lines:

```
set mailserver <SMTP_HOST> port <SMTP_PORT>
             username "<SMTP_USERNAME>" password "<SMTP_PASSWORD>"
             using tls
             with timeout 60 seconds
```

Example:

```
set mailserver smtp-relay.sendinblue.com port 587
             username "<SMTP_USERNAME>" password "<SMTP_PASSWORD>"
             using tls
             with timeout 60 seconds
set mail-format { from: <FROM_EMAIL> }
set alert <RECEIVER_EMAIL> not on { instance, action } # Do not alert when Monit starts, stops or performs a user initiated action.
```

## collector

The collector is responsible for collecting the data from the monitored services and sending it to the server.

add the following lines:

```
set mmonit <WEB_HOOK_URL>
         with timeout 30 seconds              # Default timeout is 5 seconds
         and register without credentials     # Don't send monit credentials (needed only if used with M/Monit)
```

the WEB_HOOK_URL should be a valid URL that will receive `POST` data from monit (example M/Monit collector).

WEB_HOOK_URL example:

```
https://<HOST>/webhook/monitcollector/collector
# or with activated Basic Auth
https://<BASIC_AUTH_USERNAME>:<BASIC_AUTH_PASSWORD>@<HOST>/webhook/monitcollector/collector
```

## Monit UI

add the following lines to enable Monit http UI:

```
set httpd port 2812 and
  use address localhost  # only accept connection from localhost (drop if you use M/Monit or if you want to expose the UI to the public)
  allow <MONIT_USER>:<MONIT_PASSWORD>      # require user 'admin' with password 'monit'
```

The UI can be accessed at `http://localhost:2812/` or exposed to the public using a reverse proxy (Nginx, Caddy,
traefik, Apache, etc).

> You can use [qoomon/docker-host](https://github.com/qoomon/docker-host) to expose the UI to the public while using [jwilder/nginx-proxy](https://hub.docker.com/r/jwilder/nginx-proxy).

### Check UI setup

run the following command to check the UI setup:

```
curl -I http://localhost:2812/
```

## Include Monit service configuration

add the following lines:

```
include /etc/monit/conf.d/*
include /etc/monit/conf-enabled/*
```

--------------------------------------------------------------------------------

# Monit Docker

To monitor the docker daemon and containers, you need to copy `conf.d` and `scripts` folders from the `monit-docker`
to `/etc/monit/conf.d` and `/etc/monit/scripts` folders. It also includes monitoring for the host resources (Memory,
CPU, Disk, etc) with alerts.

Edit the configurations `/etc/monit/conf.d` and the scripts `/etc/monit/scripts` for more customization.

```
/etc/monit/conf.d/docker.conf # docker monitoring
/etc/monit/conf.d/fs.conf # filesystem monitoring (DISK)
/etc/monit/conf.d/host.conf # host monitoring (CPU, Memory)
and the scripts:
/etc/monit/scripts/check_docker.sh # check docker status
```

--------------------------------------------------------------------------------

# Monit docker containers

add a new script to `/etc/monit/scripts` folder named `check_docker-container_<CONTAINER_NAME>.sh`:

```
#! /bin/bash
docker top "<CONTAINER_NAME>"
exit $?
```

add a config file to `/etc/monit/conf.d` folder named `docker-container_<CONTAINER_NAME>.conf`:

```
CHECK PROGRAM <CONTAINER_NAME> WITH PATH /etc/monit/scripts/check_docker-container_<CONTAINER_NAME>.sh
              START PROGRAM = "/usr/bin/docker start <CONTAINER_NAME>"
              STOP PROGRAM = "/usr/bin/docker stop <CONTAINER_NAME>"
              IF status != 0 FOR 3 CYCLES THEN RESTART
              IF 2 RESTARTS WITHIN 5 CYCLES THEN UNMONITOR
```

or using docker-compose:

```
CHECK PROGRAM <CONTAINER_NAME> WITH PATH /etc/monit/scripts/check_docker-container_<CONTAINER_NAME>.sh
              START PROGRAM = "cd <DOCKER_COMPOSE_PARENT_DIR>  && /usr/local/bin/docker-compose up -d"
              STOP PROGRAM = "cd <DOCKER_COMPOSE_PARENT_DIR>  && /usr/local/bin/docker-compose down"
              IF status != 0 FOR 3 CYCLES THEN RESTART
              IF 2 RESTARTS WITHIN 5 CYCLES THEN UNMONITOR
```

> make suer that your container has the name <CONTAINER_NAME>



--------------------------------------------------------------------------------

# M/Monit alternative

## custom collector

Usually we use the solution M/Monit in order to monitor multiple hosts.

If we want to have a free solution, we can use a custom `collector` that will receive monit data and store it in a
database (InfluxDB, timescaleDB, MongoDB or any db).

The collector is a webhook that will listen for monit events (POST requests), parse the data and store it.

## Visualizing Monit data

Once stored, the data can be displayed in a web UI or using Grafana, Kibana, Prometheus, etc.

We can use this technique to monitor a single host or a cluster of hosts (single or multiple monit).

--------------------------------------------------------------------------------

# Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any
contributions you make are greatly appreciated.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also
simply open an issue with the tag "enhancement". Don't forget to give the project a star! Thanks again!

- Fork the Project Create your Feature Branch (git checkout -b feature/AmazingFeature)
- Commit your Changes (git commit -m 'Add some AmazingFeature')
- Push to the Branch (git push origin feature/AmazingFeature)
- Open a Pull Request

# License

Distributed under the MIT License. See `LICENSE` for more information.

## Contact

Nask - [@naskdev](https://twitter.com/naskdev) - hi@nask.io

Project Link: [https://github.com/naskio/monit-docker](https://github.com/naskio/monit-docker)

## Acknowledgments

* [monit](https://mmonit.com/monit/)
* [Using monit to monitor Docker Containers](https://jon.sprig.gs/blog/post/1738)

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->

[contributors-shield]: https://img.shields.io/github/contributors/naskio/monit-docker.svg?style=for-the-badge

[contributors-url]: https://github.com/naskio/monit-docker/graphs/contributors

[forks-shield]: https://img.shields.io/github/forks/naskio/monit-docker.svg?style=for-the-badge

[forks-url]: https://github.com/naskio/monit-docker/network/members

[stars-shield]: https://img.shields.io/github/stars/naskio/monit-docker.svg?style=for-the-badge

[stars-url]: https://github.com/naskio/monit-docker/stargazers

[issues-shield]: https://img.shields.io/github/issues/naskio/monit-docker.svg?style=for-the-badge

[issues-url]: https://github.com/naskio/monit-docker/issues

[license-shield]: https://img.shields.io/github/license/naskio/monit-docker.svg?style=for-the-badge

[license-url]: https://github.com/naskio/monit-docker/blob/master/LICENSE.txt

[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555

[linkedin-url]: https://linkedin.com/in/nask

[product-screenshot]: https://mmonit.com/monit/img/logo@2x.png

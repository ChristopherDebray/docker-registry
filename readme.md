# Docker-registry

This project goal is to have an easy to deploy local regsitry.

I will mostly use this for coolify instances to provide a complete backup system by saving each deployed images to the local registry.

But you could totaly use it to avoid re pulls of any images


## Installation

First, you must have the following packages installed to your vps :
- docker
- certbot
- sudo apt install apache2-utils -y (to generate your password for your registry auth)

```bash
mkdir -p auth
htpasswd -Bbn myuser mypassword > ./auth/htpasswd
```

Then, you will have to create a subdomain pointing to your VPS<sup>[1](#registry-sub-domain)</sup>, for example `registry.mycompany.com`.

You will have to change in the project all occurences of `registry.mycompany.com` to your sub domain for the project to work.

Then, we will generate an ssl certificate.
```bash
## The file should be generated under /etc/letsencrypt/registry.mycompany.com
sudo certbot certonly --standalone -d registry.mycompany.com
```

Once this is all done, you are good to go

You can then run `docker compose -up`


To install reg (registry garbage collector) // LATER
```bash
curl -Lo reg https://github.com/genuinetools/reg/releases/download/v0.16.1/reg-linux-amd64
chmod +x reg
sudo mv reg /usr/local/bin/
```

## Auto delete / Cron


`crontab -e`

Add this line :
```bash
# To check, i think it will delete all unused tags. this could be dangerous if we don't push for a moment.
# Instead of 3 days try to use reg to have more control
0 3 * * 0 docker exec registry registry garbage-collect /etc/docker/registry/config.yml --delete-untagged
```

## How it works ?

Here i will explain it when using it on a github action pipeline when pushing on main.

Pipeline -> build the image -> call the local registry on vps -> save the image on the registry

## Infos :

<a id="#registry-sub-domain"></a> **Registry sub domain** :

To use the registry outside of your vps, for example in a pipeline, you must expose it.

Therefore it would be better to use a subdomain along with an ssl certificate for secure transactions.
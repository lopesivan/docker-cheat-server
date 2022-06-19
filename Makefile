include .version

# Dado um número de versão MAJOR.MINOR.PATCH, incremente a:

# 1. versão Maior(MAJOR): quando fizer mudanças incompatíveis na API,
# 2. versão Menor(MINOR): quando adicionar funcionalidades mantendo
#    compatibilidade, e
# 3. versão de Correção(PATCH): quando corrigir falhas mantendo compatibilidade.
#    Rótulos adicionais para pré-lançamento(pre-release) e metadados de
#    construção(build) estão disponíveis como extensão ao formato
#    MAJOR.MINOR.PATCH.

NAME                 = cheat-server
CONTAINER_REDIS_NAME = cheat_redis_db
USER                 = $(shell id -u -n)
GROUP                = $(shell id -g -n)
UID                  = $(shell id -u)
GID                  = $(shell id -g)
env-file             = env.production

VERSION              = $(MAJOR).$(MINOR).$(PATCH)
SERVICE              = ${NAME}
OWNER                = ${GITHUB_USER}
MACHINENAME          = $(OWNER)/$(NAME)

DOCKER_COMPOSE       = docker-compose --env-file ${env-file}
DOCKER               = docker
CONTAINER_NAME       = $(NAME)
EMAIL                = $(shell git config user.email)

LATEST               = $(VERSION)
GITHUB_DATE          = $(shell date "+%Y%m%d")
SITE                 = $(shell git config user.site)
COMMIT_SHA           = $(shell git rev-parse --verify HEAD)
EXT_RELEASE_CLEAN    = $(MINOR)
LS_TAG_NUMBER        = $(PATCH)

IMAGE                = ${MACHINENAME}
META_TAG             = amd64-${VERSION}
VERSION_TAG          = ${LATEST}
##############################################################################

VOLUMES = -v `pwd`/upstream:/app/cheat.sh/upstream

# VOLUMES = -v `pwd`/upstream:/app/cheat.sh/upstream \
#           -v `pwd`/root/etc/services.d:/etc/services.d \
#           -v `pwd`/root/etc/cont-init.d:/etc/cont-init.d

BUILD_LABEL       = \
	--label "org.opencontainers.image.created=${GITHUB_DATE}" \
	--label "org.opencontainers.image.authors=${SITE}" \
	--label "org.opencontainers.image.url=https://github.com/${GITHUB_USER}/docker-baseimage-cheat/packages" \
	--label "org.opencontainers.image.documentation=https://docs.${SITE}/images/docker-baseimage-cheat" \
	--label "org.opencontainers.image.source=https://github.com/${GITHUB_USER}/docker-baseimage-cheat" \
	--label "org.opencontainers.image.version=${EXT_RELEASE_CLEAN}-ls${LS_TAG_NUMBER}" \
	--label "org.opencontainers.image.revision=${COMMIT_SHA}" \
	--label "org.opencontainers.image.vendor=${SITE}" \
	--label "org.opencontainers.image.licenses=GPL-3.0-only" \
	--label "org.opencontainers.image.ref.name=${COMMIT_SHA}" \
	--label "org.opencontainers.image.title=Baseimage-cheat" \
	--label "org.opencontainers.image.description=baseimage-cheat image by $(shell git config user.name)"

#BUILD_OPTS = $(BUILD_LABEL) --no-cache --pull -t ${IMAGE}:${META_TAG} --build-arg VERSION="${VERSION_TAG}" --build-arg BUILD_DATE=${GITHUB_DATE}
BUILD_OPTS = $(BUILD_LABEL) -t ${IMAGE}:${META_TAG} --build-arg VERSION="${VERSION_TAG}" --build-arg BUILD_DATE=${GITHUB_DATE}

all: help

.PHONY: help
help:
	@printf "%s\n" "Useful targets:"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m  make %-15s\033[0m %s\n", $$1, $$2}'

init:
	sudo chown ${USER}:${USER} -R root upstream

config:
	# Configure envireoment file ${env-file}
	@echo ''                                > ${env-file}
	@echo PYTHONIOENCODING=UTF-8           >> ${env-file}
	@echo META_TAG=$(META_TAG)             >> ${env-file}
	@echo IMAGE=$(IMAGE)                   >> ${env-file}
	@echo CONTAINER_NAME=$(CONTAINER_NAME) >> ${env-file}
	@echo HOSTNAME=${NAME}                 >> ${env-file}
	@echo MACHINENAME=${MACHINENAME}       >> ${env-file}
	@echo SERVICE=${SERVICE}               >> ${env-file}
	@echo UID=${UID}                       >> ${env-file}
	@echo GID=${GID}                       >> ${env-file}
	@PUID=1000                             >> ${env-file}
	@PGID=1000                             >> ${env-file}
	$(DOCKER_COMPOSE) config

.PHONY: update
update: ## Update https://github.com/lopesivan/upstream
	( cd upstream; git fetch; git pull )

.PHONY: up
up: update ## Turn on the container as a background server
	$(DOCKER_COMPOSE) up -d ${SERVICE}

run:
	# create user ${USER}
	$(DOCKER_COMPOSE) run --rm \
        --name ${NAME} \
        -e PUID=${UID} \
        -e PGID=${GID} \
        ${VOLUMES} \
        ${SERVICE}

exec:
	$(DOCKER) exec -it $(CONTAINER_NAME) /bin/bash

.PHONY: ps
ps: ## Shows processes that are running or suspended
	$(DOCKER) ps -a

.PHONY: status
status: ## Show Name, cpu and memory usage per machine
	$(DOCKER) stats --all --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

pause:
	$(DOCKER) $@ $(CONTAINER_NAME)
unpause:
	$(DOCKER) $@ $(CONTAINER_NAME)

images:
	$(DOCKER) images --format "{{.Repository}}:{{.Tag}}"| sort
ls:
	$(DOCKER) images --format "{{.ID}}: {{.Repository}}"
size:
	$(DOCKER) images --format "{{.Size}}\t: {{.Repository}}"
tags:
	$(DOCKER) images --format "{{.Tag}}\t: {{.Repository}}"| sort -t ':' -k2 -n

net:
	$(DOCKER) network ls

rm-network:
	$(DOCKER) network ls| awk '$$2 !~ "(bridge|host|none)" {print "docker network rm " $$1}' | sed '1d'

rmi:
	docker rmi ${MACHINENAME}:${META_TAG}
rm-all:
	$(DOCKER) ps -aq -f status=exited| xargs $(DOCKER) rm

stop-all:
	$(DOCKER) ps -aq -f status=running| xargs $(DOCKER) stop

log:
	$(DOCKER) logs -f $(CONTAINER_NAME)

ip:
	$(DOCKER) ps -q \
	| xargs $(DOCKER) inspect --format '{{ .Name }}:{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'\
	| \sed 's/^.*://'

memory:
	$(DOCKER) inspect `$(DOCKER) ps -aq` | grep -i mem

fix:
	$(DOCKER) images -q --filter "dangling=true"| xargs $(DOCKER) rmi -f

stop:
	$(DOCKER) stop $(CONTAINER_REDIS_NAME)
	$(DOCKER) stop $(CONTAINER_NAME)

rm:
	$(DOCKER) rm $(CONTAINER_REDIS_NAME)
	$(DOCKER) rm $(CONTAINER_NAME)

build:
	$(DOCKER) build --network host $(BUILD_OPTS) .
clean-tags:
	find . -type f -name tags  -delete
create-dirs:
	mkdir opt
rm-dirs:
	sudo rm -rf opt

restart:
	$(DOCKER) restart  $(CONTAINER_NAME)

reset: rm-dirs create-dirs

.PHONY: clean
clean: stop rm ## remove shut down the container and remove

# end of file

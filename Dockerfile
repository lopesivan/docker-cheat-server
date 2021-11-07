FROM registry.local:5000/lsiobase/alpine.python:latest

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="ivanlopes.eng.br version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="lopesivan"

ENV PYTHONIOENCODING=UTF-8

# add local files
WORKDIR /app
COPY root/ /

RUN \
    echo "**** install build packages ****" && \
    apk add --update --no-cache --virtual=build-dependencies \
    py3-six py3-pygments py3-yaml py3-gevent \
    libstdc++ py3-requests py3-icu py3-redis

RUN \
    echo "**** building missing python packages ****" && \
    apk add --no-cache --virtual build-deps py3-pip gcc g++ python3-dev libffi-dev \
    && pip3 install --no-cache-dir --upgrade pygments \
    && cd /app/cheat.sh \
    && pip3 install --no-cache-dir -r requirements.txt \
    && apk del build-deps

RUN \
    echo "**** installing server dependencies ****" && \
    apk add --update --no-cache py3-jinja2 py3-flask bash gawk \
    && pip3 install -U Werkzeug==0.16.0


# ports and volumes
EXPOSE 8002
VOLUME /config

# vim: fdm=marker:sw=4:sts=4:et

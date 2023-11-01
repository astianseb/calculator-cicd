FROM python:3.8-slim-buster

# Install the tools (sudo)
USER root
RUN apt-get update && apt-get upgrade -y && apt install sudo tasksel -y
RUN apt-get install -y sqlite3

RUN addgroup --system dbuser
RUN adduser --system dbuser --ingroup dbuser
RUN adduser dbuser sudo

RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER dbuser

WORKDIR /db

RUN touch ./sgdb
RUN chmod 666 ./sgdb

CMD [ "sqlite3", "sgdb" ]
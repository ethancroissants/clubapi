FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    wget 

RUN curl -fsSL https://astra.arkforge.net/install.sh | bash

WORKDIR /app

COPY . .

EXPOSE 3000 3000

CMD ["astra", "run", "server.lua"]

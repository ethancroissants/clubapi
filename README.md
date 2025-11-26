# Clubs API
[![CI](https://hackatime-badge.hackclub.com/U07UV4R2G4T/clubapi)](https://hackatime.hackclub.com)

API For interacting with clubs data. Written in Lua using the [Astra](https://astra.arkforge.net/) web framework

API Documentation: https://clubapi.hackclub.com

## Setup

Requirements: [Astra](https://astra.arkforge.net/), Git 

```bash
git clone https://github.com/hackclub/clubapi
cp example.env .env # then fill out the .env
astra run server.lua

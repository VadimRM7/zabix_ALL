#!/bin/bash
export FRONT_OFF=noninteractive
apt-get update -y
apt-get upgrade -y
apt-get autoremove -y
apt-get autoclean -y

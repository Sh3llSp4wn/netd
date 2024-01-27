# NetD

## Summary

NetD is a CLI process manager for SSH port forwards. It is designed for extensibility and can be extended to support other passive network operations


## pfwd

Base command: `pfwd`

pfwd supports two subcommands

### local

SSH local port forward, accepts `--remote` ip port pair as an argument

### remote

SSH remote port forward, accepts `--local` ip port pair as an argument



## Requirements

SSH hosts must be set up to use paswordless access with the current users username


## Install

`bundler install`
`gem build`
`gem install netd-0.0.1.gem`

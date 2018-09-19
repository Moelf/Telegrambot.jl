# Telegrambot.jl
A julia wrapper for [telegram](https://telegram.im) api (mostly replying commands consists text).

| **Build Status**                                                                                |
|:-----------------------------------------------------------------------------------------------:|
|[![Build Status](https://travis-ci.org/Moelf/telegrambot.jl.svg?branch=master)](https://travis-ci.org/Moelf/telegrambot.jl)|

**Installation**: note yet in Julia registry so you will need to clone this repo and follow [this guide](https://docs.julialang.org/en/v1.0.0/stdlib/Pkg/#Using-someone-else's-project-1)


## Basic Usage


```julia
import Telegrambot
botApi = "<your_api_>"

function welcomeMsg()
    return "Welcome to my awesome bot"
end

function echo(incoming::AbstractString)
    return incoming
end

txtCmds = Dict()
txtCmds["repeat_msg"] = echo #this will respond to '/repeat_msg <any thing>'
txtCmds["start"] = welcomeMsg # this will respond to '/start'

Telegrambot.startBot(botApi; textHandle = txtCmds)
```

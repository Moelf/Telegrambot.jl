# telegrambot.jl
A julia wrapper for [telegram](https://telegram.im) api (mostly replying commands consists text).

| **Build Status**                                                                                |
|:-----------------------------------------------------------------------------------------------:|
|[![Build Status](https://travis-ci.org/Moelf/telegrambot.jl.svg?branch=master)](https://travis-ci.org/Moelf/telegrambot.jl)|

**Installation**: note yet in Julia registry so you will need to clone this repo and follow [this guide](https://docs.julialang.org/en/v1.0.0/stdlib/Pkg/#Using-someone-else's-project-1)


## Basic Usage
For guide on telegram bot creation and api, check [this](https://core.telegram.org/bots#3-how-do-i-create-a-bot) out.

```julia
import telegrambot
botApi = "<your_api>"

function welcomeMsg()
    return "Welcome to my awesome bot"
end

function echo(incoming::AbstractString)
    return incoming
end

txtCmds = Dict()
txtCmds["repeat_msg"] = echo #this will respond to '/repeat_msg <any thing>'
txtCmds["start"] = welcomeMsg # this will respond to '/start'

telegrambot.startBot(botApi; textHandle = txtCmds)
```
## To-Do
- Add inline command function
- Add function to quote reply to a message
- Add function to reply with a file/image
- Add function to serve as a IRC-Tg bot

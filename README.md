# Telegrambot.jl
A Julia Telegram Bot Api wapper
[check out telegram bot api](https://telegram.im) api (mostly built around commands with text).


| **Build Status**                                                                                |
|:-----------------------------------------------------------------------------------------------:|
|[![Build Status](https://travis-ci.org/Moelf/Telegrambot.jl.svg?branch=master)](https://travis-ci.org/Moelf/Telegrambot.jl)|

## Installation

The package is registered in `METADATA.jl` and can be installed with `Pkg.add`, or in `REPL` by pressing `] add Telegrambot`.
```julia
julia> Pkg.add("Telegrambot")
```

## Basic Usage
For guide on telegram bot creation and api, check [this](https://core.telegram.org/bots#3-how-do-i-create-a-bot) out.

**NOTICE**: Due to the way `botfather` present you key, don't forget to add "bot", I shall add a warning and try to be smart.

```julia
using Telegrambot
botApi = "bot<your_api_key>"

welcomeMsg(incoming::AbstractString) = "Welcome to my awesome bot"

echo(incoming::AbstractString) = incoming

txtCmds = Dict()
txtCmds["repeat_msg"] = echo #this will respond to '/repeat_msg <any thing>'
txtCmds["start"] = welcomeMsg # this will respond to '/start'

inlineOpts = Dict() #Title, result pair
inlineOpts["Make Uppercase"] = uppercase #this will generate an pop-up named Make Uppercase and upon tapping return uppercase(<user_input>)

#uppercase is a function that takes a string and return the uppercase version of that string

startBot(botApi; textHandle = txtCmds, inlineQueryHandle=inlineOpts)
```
## To-Do
- [x] Add Inline query respond 
- [ ] Add function to quote reply to a message
- [ ] Add function to reply with a file/image
- [ ] Add function to serve as a IRC-Tg bot

import Telegrambot, Telegrambot.InlineQueryResultArticle
import UUIDs
import Scryfall
botApi = "bot552445015:AAFm1fTBaFO9jK42fuMdQe_OMtMj7pbNr9o"

function welcomeMsg(name::AbstractString)
    msg = """
    Welcome to using Scryfall bot, powered by https://github.com/Moelf/Telegrambot.jl
    Basic usage:
    - /searchtext <fuzzy_card_name>
    - /searchimg <fuzzy_card_name>
    """
    return msg
end

function getImgVer(fuzzyName::AbstractString)
    nameList = split(fuzzyName, " ")
    if occursin("ver=", nameList[end])
        vercode = string(fuzzyName[end-2:end])
        name = join(nameList[1:end-1])
        print("name: $name, vercode: $vercode")
    else
        name = fuzzyName
        vercode=" "
    end
    #= print(name, verCode) =#
    return Scryfall.getImgurl(name; setCode=vercode)
end

function echo(incoming::AbstractString)
    return incoming
end

txtCmds = Dict()
txtCmds["searchtext"] = Scryfall.getOracle
txtCmds["searchimg"] = getImgVer
txtCmds["start"] = welcomeMsg
txtCmds["repeat_msg"] = echo #this will respond to '/repeat_msg <any thing>'
inlineOpts = Dict() #Title, result pair
inlineOpts["Make Uppercase"] = uppercase #this will generate an pop-up named Make Uppercase and upon tapping return uppercase(<user_input>)
Telegrambot.startBot(botApi; textHandle = txtCmds, inlineQueryHandle=inlineOpts)

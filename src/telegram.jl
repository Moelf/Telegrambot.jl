module telegram

import HTTP, Test, JSON
export startBot, getUpdates, sendText

function startBot(botApi="";textHandle=Dict())
    if isempty(textHandle)
        error("You need to pass repond function as parameter to startBot")
    end
    offset = 0
    msgDict = Dict()
    while true
        msgQuery = getUpdates(botApi,offset)
        #= JSON.print(msgQuery, 2) =#
        offsetList = Number[]
        pendingList = Dict[]
        if length(msgQuery)==0
            continue #this repeast every timeout seconds, now 30
        end
        for i in 1:length(msgQuery) # update timeout
            push!(offsetList, msgQuery[i]["update_id"])
        end
        offset = maximum(offsetList)+1

        try 
            for i in 1:length(offsetList)
                push!(pendingList, Dict())
                pendingList[i][:text] = msgQuery[i]["message"]["text"]
                pendingList[i][:chat_id] = msgQuery[i]["message"]["chat"]["id"]
            end
        catch
            @warn backtrace()
            continue
        end

        for rawCmd in pendingList
            println(rawCmd) #deubg
            cmdName = ""
            cmdPara = ""
            try
                cmdName = string(match(r"/([^@\s]+)", rawCmd[:text])[1]) #match till first @ or space
                cmdPara = string(match(r"\s(.*)$", rawCmd[:text])[1]) #match from first space to end
            catch
                #= @warn backtrace() =#
                continue
            end
            println("namc: $cmdName, para: $cmdPara") #debug
            if haskey(textHandle, cmdName)
                reply = textHandle[cmdName](cmdPara)
                reply = HTTP.URIs.escapeuri(reply) #encode for GET purpose
                reply_id = string(rawCmd[:chat_id])
                reply_id = HTTP.URIs.escapeuri(reply_id) #encode for GET purpose

                sendText(botApi, reply_id, reply)
            else
                @warn backtrace()
            end
        end
    end
end

function sendText(botApi, chat_id,text)
    tQuery="""chat_id=$chat_id&text=$text"""
    updates = HTTP.request("GET","https://api.telegram.org/$botApi/sendMessage";query="$tQuery")
    sleep(0.1)
end

function getUpdates(botApi="",offset=0)
    tQuery="""timeout=30&offset=$offset"""
    updates = JSON.parse(String(HTTP.request("GET","https://api.telegram.org/$botApi/getUpdates";query="$tQuery").body))
    #= JSON.print(updates, 2) =#
    result = updates["result"]
    return result
end

end # module

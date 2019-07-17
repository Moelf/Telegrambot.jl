module Telegrambot

import HTTP, Test, JSON, UUIDs
export InlineQueryResultArticle
export startBot, getUpdates, sendText

struct InlineQueryResultArticle
    id::String
    title::String
    message::String
end

function startBot(botApi=""; textHandle=Dict(), inlineQueryHandle=Dict())
    !isempty(textHandle) || error("You need to pass repond function as parameter to startBot")
    # in case people put in what botfather spits
    botApi = botApi[1:3]=="bot" ? botApi : "bot" * botApi
    # to be used to clear msg que
    offset = 0

    msgDict = Dict()
    while true
        msgQuery = getUpdates(botApi,offset)
        if length(msgQuery)==0
            #this repeast every timeout seconds, now 30
            continue 
        end
        offset = maximum([ i["update_id"] for i in msgQuery ]) + 1 #update to clear the msg query next loop

        # HTTP respond will have this field if a user @'ed bot in a chat
        # find match cmd to pass to correspond function to handle
        for rawCmd in msgQuery
            # if this is a message
            if haskey(rawCmd, "message")
                msg = rawCmd["message"]
                cmdName=" "
                cmdPara = " "
                try
                    cmdName = string(match(r"/([^@\s]+)", msg["text"])[1]) #match till first @ or space
                catch
                    #= @warn "Not a command start with /" =#
                    continue
                end

                try
                    cmdPara = string(match(r"\s(.*)$", msg["text"])[1]) #match from first space to end
                catch
                    cmdPara = " "
                    #= @warn "Command may got passed empty parameter" =#
                end
                if haskey(textHandle, cmdName)
                    reply = textHandle[cmdName](cmdPara)  #encode for GET purpose
                    reply_id = string(msg["chat"]["id"])  #encode for GET purpose
                    # all space msg is not allower either
                    !isempty(strip(reply)) || (@warn " message must be non-empty, also can't be all spaces";
                                               reply = "Using the command incorrectly or command is bad")
                    sendText(botApi, reply_id, reply)
                else
                    reply_id = string(msg["chat"]["id"])  #encode for GET purpose
                    no_cmd_prompt= "The command $cmdName is not found" 
                    sendText(botApi, reply_id, no_cmd_prompt)
                    #= @warn backtrace() =#
                end
            end

            # HTTP respond will have this field if a user started an inline request
            if haskey(rawCmd, "inline_query") 
                qry = rawCmd["inline_query"]
                if qry["query"]≠"" #multiple inline query fills up as user type so initially there is an empty string
                    articleList = InlineQueryResultArticle[] #make an array of Articles waiting to be converted
                    for (key, inlineOpt) in inlineQueryHandle
                        articleEntry = InlineQueryResultArticle(string(UUIDs.uuid4()), key, inlineOpt(qry["query"]))
                        push!(articleList, articleEntry)
                    end
                    results = articleList |> ArticleListtoJSON  #encode according to https://core.telegram.org/bots/api#inlinequeryresult
                    query_id = qry["id"]  #encode for GET escape
                    answerInlineQuery(botApi, query_id, results)
                end
            end
        end
    end
end

# GET request sendig to telegram for text repond
function sendText(botApi, id, text)
    # can't pass empty text, results 400
    text = text |> HTTP.URIs.escapeuri #encode for GET purpose
    id = id |> HTTP.URIs.escapeuri #encode for GET purpose
    tQuery="""chat_id=$id&text=$text"""
    try
        updates = HTTP.request("GET","https://api.telegram.org/$botApi/sendMessage";query="$tQuery")
    catch e
        errmsg = JSON.parse(String(e.response.body))
        @warn "$(errmsg["description"]): $id"
    end
    sleep(0.01)
end

# GET request sendig to telegram for inline respond
function answerInlineQuery(botApi, query_id, results::String)
    results = results |> HTTP.URIs.escapeuri #encode for GET purpose
    query_id = query_id |> HTTP.URIs.escapeuri #encode for GET purpose
    tQuery="""inline_query_id=$query_id&results=$results"""
    updates = HTTP.request("GET","https://api.telegram.org/$botApi/answerInlineQuery";query="$tQuery")
    sleep(0.01)
end

#encode a list of InlineQueryResultArticle according to telegram api JSON format
function ArticleListtoJSON(articles::Array{InlineQueryResultArticle}) 
    return JSON.json([ Dict(
                            "type"=>"article","id"=>article.id,
                            "title"=>article.title,
                            "input_message_content"=>
                            Dict{String,String}("message_text"=>article.message)
                           )
                      for article in articles])
end

function getUpdates(botApi="", offset=0)
    # this is already a long-poll handled on telegram's side
    # telling telegram how long we want to timeout once
    tQuery="""timeout=30&offset=$offset"""
    updates = JSON.parse(String(HTTP.request("GET","https://api.telegram.org/$botApi/getUpdates";query="$tQuery").body))
    result = updates["result"]
    return result
end

end # module

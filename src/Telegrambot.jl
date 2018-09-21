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
    if isempty(textHandle)
        error("You need to pass repond function as parameter to startBot")
    end
    offset = 0
    msgDict = Dict()
    while true
        msgQuery = getUpdates(botApi,offset)
        if length(msgQuery)==0
            continue #this repeast every timeout seconds, now 30
        end
        offset = maximum([ i["update_id"] for i in msgQuery ]) + 1 #update to clear the msg query next loop

        for rawCmd in msgQuery
            if haskey(rawCmd, "message")
                msg = rawCmd["message"]
                cmdName=" "
                cmdPara = " "
                try
                    cmdName = string(match(r"/([^@\s]+)", msg["text"])[1]) #match till first @ or space
                catch
                    @warn "Not a command start with /"
                    continue
                end

                try
                    cmdPara = string(match(r"\s(.*)$", msg["text"])[1]) #match from first space to end
                catch
                    cmdPara = " "
                    @warn "Command may got passed empty parameter"
                end
                if haskey(textHandle, cmdName)
                    reply = textHandle[cmdName](cmdPara) |> HTTP.URIs.escapeuri #encode for GET purpose
                    reply_id = string(msg["chat"]["id"]) |> HTTP.URIs.escapeuri #encode for GET purpose

                    sendText(botApi, reply_id, reply)
                else
                    @warn backtrace()
                end
            end
            if haskey(rawCmd, "inline_query") #will have this field if a user started an inline request
                qry = rawCmd["inline_query"]
                if qry["query"]≠"" #multiple inline query fills up as user type so initially there is an empty string
                    articleList = InlineQueryResultArticle[] #make an array of Articles waiting to be converted
                    for (key, inlineOpt) in inlineQueryHandle
                        articleEntry = InlineQueryResultArticle(string(UUIDs.uuid4()), key, inlineOpt(qry["query"]))
                        push!(articleList, articleEntry)
                    end
                    results = articleList |> ArticleListtoJSON |> HTTP.URIs.escapeuri #encode according to https://core.telegram.org/bots/api#inlinequeryresult
                    query_id = qry["id"] |> HTTP.URIs.escapeuri #encode for GET escape
                    answerInlineQuery(botApi, query_id, results)
                end
            end
        end
    end
end

function sendText(botApi, chat_id, text)
    tQuery="""chat_id=$chat_id&text=$text"""
    updates = HTTP.request("GET","https://api.telegram.org/$botApi/sendMessage";query="$tQuery")
    sleep(0.1)
end

function answerInlineQuery(botApi, query_id, results::String)
    tQuery="""inline_query_id=$query_id&results=$results"""
    updates = HTTP.request("GET","https://api.telegram.org/$botApi/answerInlineQuery";query="$tQuery")
    sleep(0.1)
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
    tQuery="""timeout=30&offset=$offset"""
    updates = JSON.parse(String(HTTP.request("GET","https://api.telegram.org/$botApi/getUpdates";query="$tQuery").body))
    result = updates["result"]
    return result
end

end # module

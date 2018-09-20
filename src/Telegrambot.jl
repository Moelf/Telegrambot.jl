module Telegrambot

import HTTP, Test, JSON
export startBot, getUpdates, sendText

struct InlineQueryResultArticle
	id::String
	title::String
	message::String
end

function startBot(botApi=""; textHandle=Dict(), inlineQueryHandle=(s->InlineQueryResultArticle[]))
    if isempty(textHandle)
        error("You need to pass repond function as parameter to startBot")
    end
    offset = 0
    msgDict = Dict()
    while true
        msgQuery = getUpdates(botApi,offset)
        #= JSON.print(msgQuery, 2) =#
        if length(msgQuery)==0
            continue #this repeast every timeout seconds, now 30
        end
		offset = maximum([ i["update_id"] for i in msgQuery ]) + 1

        for rawCmd in msgQuery
            #println(rawCmd) #debug
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
            	#= println("namc: $cmdName, para: $cmdPara") #debug =#
            	if haskey(textHandle, cmdName)
            	    reply = textHandle[cmdName](cmdPara) |> HTTP.URIs.escapeuri #encode for GET purpose
					reply_id = string(msg["chat"]["id"]) |> HTTP.URIs.escapeuri #encode for GET purpose

            	    sendText(botApi, reply_id, reply)
            	else
            	    @warn backtrace()
            	end
			end
			if haskey(rawCmd, "inline_query")
				qry = rawCmd["inline_query"]
				#println(qry["query"])

				if qry["query"]≠""
					results = inlineQueryHandle(qry["query"]) |> toJSON |> HTTP.URIs.escapeuri #encode for GET purpose
					query_id = qry["id"] |> HTTP.URIs.escapeuri #encode for GET purpose

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

function toJSON(articles::Array{InlineQueryResultArticle})
	s = JSON.json([ Dict("type"=>"article","id"=>article.id, "title"=>article.title,
							"input_message_content"=>
							Dict{String,String}("message_text"=>article.message ) )
					  for article in articles])
	#print(s)
	return s
end

function getUpdates(botApi="", offset=0)
    tQuery="""timeout=30&offset=$offset"""
    updates = JSON.parse(String(HTTP.request("GET","https://api.telegram.org/$botApi/getUpdates";query="$tQuery").body))
    #= JSON.print(updates, 2) =#
    result = updates["result"]
    return result
end

end # module

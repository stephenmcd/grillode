
coffee     = require "coffee-script"
fs         = require "fs"
htmlparser = require "htmlparser"
path       = require "path"


exports.coffeeCompile = (file) ->
    ###
    Returns the given coffee-script filename as a compile Javascript string.
    ###
    try
        coffee.compile String (fs.readFileSync path.join __dirname, file)
    catch error
        "alert(\"#{error}\")"

exports.stripTags = (html, allowed={}) -> 
    ###
    Strips the given HTML string of all tags, other than those 
    specified in the ``allowed`` param, which should be in the 
    format: {tag1: [allowedAttribute1, allowedAttribute2], tag2: []}
    ###
    
    escapeHtml = (html) ->
        ###
        Replace brackets and quotes with their HTML entities.
        ###
        ((html.replace /"/g, "&#34;")
              .replace /</g, "&#60;")
              .replace />/g, "&#62;"

    # Bail out early if no HTML.
    if (html.indexOf "<") is -1 or (html.indexOf ">") is -1
        return escapeHtml html

    handler = new htmlparser.DefaultHandler();
    parser = new htmlparser.Parser(handler);
    parser.parseComplete(html);

    buildAll = (parts) -> 
        ###
        Takes a list of dom nodes and returns each node as a string 
        if it's text or an allowed tag. Called recursively on the 
        node's child nodes.
        ###

        buildOne = (part) ->
            children = if part.children? then buildAll part.children else ""
            switch part.type
                when "text"
                    return escapeHtml part.data
                when "tag"
                    tag = part.name
                    if allowed[tag]?
                        attrib = (name) ->
                            if part.attribs[name]?
                                value = escapeHtml part.attribs[name]
                                return " #(name)=\"#(value)\""
                            return ""
                        attribs = (attrib n for n in allowed[tag]).join("")
                        return "<#{tag}#{attribs}>#{children}</#{tag}>"
            return children

        (buildOne part for part in parts).join("")

    buildAll handler.dom


exports.time = -> 
    ###
    Return a timestamp in the format: HH:MM:SS
    ###
    date = new Date()
    parts = [date.getHours(), date.getMinutes(), date.getSeconds()]
    pad = (s) -> if (String s).length is 1 then "0#{s}" else s
    (pad part for part in parts).join(":")

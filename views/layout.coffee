
html ->

    head ->
        title "#{@title} | Grillode"
        link rel: "stylesheet", href: "/style.css"

    body ->
        h1 "Grillode - #{@title}"
        ul class: "nav", ->
            li "/", -> a href: "/",           -> "Home"
            li "/", -> a href: "https://github.com/stephenmcd/grillode#readme",           
                                              -> "About"
            li "/", -> a href: "/rooms/add",  -> "Add a temporary room"
            li "/", -> a href: "/wait",       -> "Wait for someone"
            li "/", -> a href: "/match",      -> "Join someone waiting"
            li "/", -> a href: "/random",     -> "Random match up"
        @body

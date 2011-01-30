
html ->

    head ->
        title "#{@title} | Grillode"
        link rel: "stylesheet", href: "/style.css"

    body ->
        h1 "Grillode - #{@title}"
        ul class: "nav", ->
            li "/", -> a href: "/about",      -> "About"
            li "/", -> a href: "/",           -> "Rooms"
            li "/", -> a href: "/rooms/add",  -> "Add room"
            li "/", -> a href: "/wait",       -> "Wait"
            li "/", -> a href: "/waiting",    -> "View waiting queue"
            li "/", -> a href: "/match",      -> "Join someone waiting"
            li "/", -> a href: "/random",     -> "Random matchup"
        @body

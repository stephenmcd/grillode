
html ->

    head ->
        title "Home | Grillode"
        link rel: "stylesheet", href: "/style.css"

    body id: "index", ->
        h1 "Grillode"
        for room, users of @rooms
            ul ->
                li class: "first", ->
                    h2 ->
                        a href: "/rooms/#{room}/", -> room
                    " (#{users.length})"
                for user in users
                    li user.name
            if ++i % 2 is 0 
                br clear: "all"

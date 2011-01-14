
html ->
    head ->
        title "Home | Grillode"
        link rel: "stylesheet", href: "/style.css"
    body id: "index", ->
        h1 "Grillode"
        for room, users of @rooms
            ul ->
                li ->
                    h2 ->
                        a href: "/room/#{room}/", -> room
                    " (#{users.length})"
                for user in users
                    li user.name


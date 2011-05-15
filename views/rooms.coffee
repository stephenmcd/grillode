
for room, users of @rooms
    ul class: "rooms", ->
        li class: "first", ->
            h2 ->
                a href: "/rooms/#{room}/", -> room
            " (#{users.length})"
        for user in users
            li user.name
    if ++i % 2 is 0
        br clear: "all"

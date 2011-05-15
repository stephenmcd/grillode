
if @clients.length is 0
    div "No one is waiting!", id: "error"
ul ->
    for client in @clients
        li ->
            a href: "/rooms/#{client.room}/", -> "#{client.name}"
            minutes = @since client.start
            s = if minutes isnt 1 then "s" else ""
            " - waiting #{minutes} minute#{s}"

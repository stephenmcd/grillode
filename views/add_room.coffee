
form method: "post", ->
    input
        type: "text"
        class: "text"
        name: "room"
        value: @room
    input
        type: "submit"
        name: "button"
        id: "button"
        value: "Add room"

div @message, id: "error"

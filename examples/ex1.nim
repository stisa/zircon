import ../zircon

var x = 2
let author = "stisa"

html mypage :
  head:
    title(if x==2:"two" else:"nottwo")
    meta "author", author
  body:
    p("hello") 
    p("world")
    dv:
      p "from a"
      dv:
        p "dsl"
        a:
          "/"
          "home"
          class="link"

echo transpile(mypage())

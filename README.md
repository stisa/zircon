# Zircon
DSL in [nim](https://nim-lang.org) that uses nim macros to create an html document.  
Example
```nim  
import zircon 

let x = 2 
let author = "stisa"

html page: 
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
          
echo transpile(page())
```

Results in:
```html
<html>
 <head>
   <meta name="author" content="stisa">
   <title>two</title>
 </head>
 <body>
  <p>hello</p>
  <p>world</p>
  <div>
   <p>from a</p>
   <div>
    <p>dsl</p>
    <a id="" class"link" href="/">home</a>
   </div>
  </div>
 </body>
</html>
```

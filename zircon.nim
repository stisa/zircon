import strutils
import macros except body

# TODO: avoid all the quasi-same macros.
# TODO: expand spec (links,style,img,src etc)
# TODO: allow specifying id, class
# TODO: render the ast to proper html, with proper indentation
# TODO: group similar kinds together, eg div,body,section,header,footer,etc are all containers.
# TODO: less verbose macros for a? also macro for id,class for other nodes

type HtmlNodeKind* = enum
  nkHtml,
  nkHead,
  nkBody,
  nkDiv,
  nkTitle,
  nkMeta,
  nkP,
  nkA

type HtmlNode* = ref object
  id: string
  class: string
  case kind: HtmlNodeKind
  of nkHtml:
    head: HtmlNode
    body: HtmlNode
  of nkHead:
    title: HtmlNode
    meta: seq[HtmlNode]#todo: meta needs its own type, to distinguish from link
  of nkBody,nkDiv: # section, header, footer follow this pattern
    sons: seq[HtmlNode]
  of nkA:# todo: img,link,script all follow this pattern
    href : string
    aTxt : string 
  of nkP:
    text:string
  of nkTitle:
    val : string
  of nkMeta:
    name: string
    content:string
  else:
    discard

#proc `$`(n:HtmlNode):string = $(n[])

proc `$`*(n:HtmlNode):string =
  case n.kind:
  of nkHtml:
    return "Html:\n" & $n.head & "\n" & $n.body
  of nkHead:
    result = "Head:" & $n.title
    for m in n.meta:
      result &= "\n" & $m
  of nkMeta:
    return "Meta:" & $n.name & "->" & $n.content
  of nkBody:
    result ="Body:"
    for s in n.sons:
     result &= ("\n" & $s)
  of nkDiv:
    result ="Div:"
    for s in n.sons:
     result &= ("\n" & $s)
  of nkTitle:
    return "Title:" & $n.val
  of nkP:
    return "P:" & $n.text
  else:
    return "#gibberish"& $n.kind 

template dump(n:NimNode) =
  echo "-----v----"
  echo treerepr n
  echo n.tostrlit 
  echo "-----^----"

proc newHead*(title:HtmlNode,meta:varargs[HtmlNode]): HtmlNode = 
  result = HtmlNode(kind:nkHead, title:title, meta: @meta)

macro head*(inner:untyped):HtmlNode =
  result = newCall("newHead")
  if inner.len == 1:
    result.add(inner)
  elif inner.len > 1 :
    inner.copychildrento(result)
  else:
    echo "headerror"

proc newa*(href,val:string,id="",class=""):HtmlNode = 
  result =HtmlNode(kind:nkA,href:href,aTxt:val)
  result.id = id
  result.class = class

proc meta*(name,val:string):HtmlNode = HtmlNode(kind:nkMeta,name:name,content:val)

proc title*(x:string):HtmlNode = HtmlNode(kind:nkTitle, val: x)

proc p*(x:varargs[string, `$`]):Htmlnode =
  result = Htmlnode(kind:nkp, text: (@x).join(" "))

proc newDiv*(sons:varargs[HtmlNode]): HtmlNode = 
  result = HtmlNode(kind:nkDiv, sons: @sons) 
   
macro dv*(inner:untyped,id="",class:string=""):HtmlNode = 
  result = newCall("newDiv")
  if inner.len == 1:
    result.add(inner)
  elif inner.len > 1 :
    inner.copychildrento(result)
  else:
    echo "dverror"

proc newBody*(sons:varargs[HtmlNode]):HtmlNode = 
  result = HtmlNode(kind:nkBody, sons: @sons) 

macro body*(inner:untyped):HtmlNode = 
  result = newCall("newBody")
  if inner.len == 1:
    result.add(inner)
  elif inner.len > 1 :
    inner.copychildrento(result)
  else:
    echo "bodyerror"

proc newHtml*(h,b:HtmlNode): HtmlNode = 
  result = HtmlNode(kind:nkHtml,head:h,body:b)

macro html*(name:untyped, inner:untyped):typed=
  let h = inner[0] #TODO: do not assume a well formed html page, eg account for missing head etc
  let b = inner[1]
  var rs = newCall("newHtml",h,b)
  result = quote do:
    proc `name`():HtmlNode = `rs`

macro htmlast(name,t:untyped):typed = 
  var tt = t
  echo tt.kind
  result = newstmtlist()
  var varsect = newNimNode(nnkIdentDefs)
  varsect.add(name)
  varsect.add(newidentnode("HtmlNode"))
  varsect.add(tt)
  result.add(newnimnode(nnkVarSection).add(varsect))
  #dump result

proc render (n:HtmlNode):string{.discardable} =
  case n.kind :
  of nkhtml:
    result = "<html>\n"
  of nkhead: 
    result = "<head>\n"
  of nktitle:
    result = "<title>"& n.val & "</title>\n"
  of nkmeta:
    result = "<meta name=\""& n.name & "\" content=\""& n.content & "\">\n"
  of nkbody:
    result = "<body>\n"
  of nkp:
    result = "<p>"& n.text & "</p>\n"
  of nkdiv:
    result = "<div>\n"
  of nka:
    result = "<a id=\""& n.id&"\" class=\""&n.class&"\""&" href=\"" & n.href & "\">" & n.atxt & "</a>"
  else:
    result = "else" 
  #result &= "\n"

proc close(n:HtmlNode):string{.discardable} =
  case n.kind :
  of nkhtml:
    result = "</html>"
  of nkhead: 
    result = "</head>\n"
  of nkbody:
    result = "</body>\n"
  of nkdiv:
    result = "</div>\n"
  else:
    result = "else"& $n.kind 


proc transpile*(n:HtmlNode):string =
  result = ""
  var il :int = 0 #indentlevel
  case n.kind:
  of nkhtml:
    result &= render n
    inc il
    result &= indent( transpile(n.head),il)
    result &= indent(transpile(n.body),il)
    dec il
    result &= close n
  of nkhead:
    result &= render n
    inc il
    for i in n.meta:
      result &= indent(render(i),il)
    result &= indent(render(n.title),il)
    dec il
    result &= close n
  of nkBody:
    result &= render n
    inc il
    for i in n.sons:
      if i.kind == nkdiv:
        result &= indent(transpile(i),il)
      else: result &= indent(render(i),il)
    dec il
    result &= close n
  of nkdiv:
    result &= render n
    inc il
    for i in n.sons:
      if i.kind == nkdiv:
        result &= indent(transpile(i),il)
      else: result &= indent(render(i),il)
    dec il
    result &= close n
  else: discard

macro a*(inner:varargs[untyped]):HtmlNode =
  if inner[0].findchild(it.kind==nnkasgn)!=nil:
    var rest : tuple[class,id,href,atxt:NimNode]
    for i in inner[0]:
      if i.kind == nnkasgn :
        if i[0].ident == !"class":
          rest.class = i[1]
        elif i[0].ident == !"id":
          rest.id = i[1]
        else: echo "other asgn?"
      else:
        if rest.href == nil: 
          rest.href = i
        else:
          rest.atxt = i
    result = newCall("newa")
    var sml = newstmtlist()
    if rest.href != nil:
      var eel = newnimnode(nnkexpreqexpr)
      eel.add(newidentnode(!"href"),rest.href)
      sml.add eel
    if rest.atxt != nil:
      var eel = newnimnode(nnkexpreqexpr)
      eel.add(newidentnode(!"val"),rest.atxt)
      sml.add eel
    if rest.class != nil:
      var eel = newnimnode(nnkexpreqexpr)
      eel.add(newidentnode(!"class"),rest.class)
      sml.add eel
    if rest.id != nil:
      var eel = newnimnode(nnkexpreqexpr)
      eel.add(newidentnode(!"id"),rest.id)
      sml.add eel
    sml.copychildrento(result)
  else:
    result = newCall("newa")
    inner.copychildrento(result)

when isMainModule:
  var x = 2
  let author = "stisa"
   
  html page :
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

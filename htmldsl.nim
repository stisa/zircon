import strutils
import macros except body

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
    return "Html:" & $n.head & ", " & $n.body
  of nkHead:
    result = "Head:" & $n.title 
    for m in n.meta:
      result &= $m
  of nkMeta:
    return "Meta:" & $n.name & "->" & $n.content
  of nkBody:
    result ="Body:"
    for s in n.sons:
     result &= $s
  of nkDiv:
    result ="Div:"
    for s in n.sons:
     result &= $s
  of nkTitle:
    return "Title:" & $n.val
  of nkP:
    return "P:" & $n.text
  else:
    return "#gibberish" 

template dump(n:NimNode) =
  echo "-----v----"
  echo treerepr n
  echo n.tostrlit 
  echo "-----^----"

proc newHead*(title:HtmlNode,meta:varargs[HtmlNode]): HtmlNode = 
  result = HtmlNode(kind:nkHead, title:title, meta: @meta)

macro head*(inner:untyped):HtmlNode =
  if inner.kind == nnkCall :
    result = newCall("newHead",inner)  
  else:
    result = newCall("newHead")
    for i in inner:
      result.add(i)

proc a*(href,val:string):HtmlNode = HtmlNode(kind:nkA,href:href,aTxt:val)

proc meta*(name,val:string):HtmlNode = HtmlNode(kind:nkMeta,name:name,content:val)

proc title*(x:string):HtmlNode = HtmlNode(kind:nkTitle, val: x)

proc p*(x:varargs[string, `$`]):Htmlnode {.discardable} =
  result = Htmlnode(kind:nkp, text: (@x).join("i "))

proc newDiv*(sons:varargs[HtmlNode]): HtmlNode = 
  result = HtmlNode(kind:nkDiv, sons: @sons) 
   
macro dv*(inner:untyped):HtmlNode = 
  result = newCall("newDiv",inner)
  #[var hseq = newnimnode(nnkBracket)
  if inner.len == 1:
    hseq.add(inner[0])
  elif inner.len > 1 :
    for i in inner:
      hseq.add(i)
  else:
    echo "wtf"
  result.add(prefix(hseq,"@"))
]#
proc newBody*(sons:seq[HtmlNode]):HtmlNode =  
  result = HtmlNode(kind:nkBody, sons: sons) 

macro body*(inner:untyped):HtmlNode = 
  result = newCall("newBody")
  var hseq = newnimnode(nnkBracket)
  if inner.len == 1:
    hseq.add(inner[0])
  elif inner.len > 1 :
    for i in inner:
      hseq.add(i)
  else:
    echo "wtf"
  result.add(prefix(hseq,"@"))

proc newHtml*(h,b:HtmlNode): HtmlNode = 
  result = HtmlNode(kind:nkHtml,head:h,body:b)

macro html*(name:untyped, inner:untyped):typed=
  let h = inner[0] #TODO: do not assume a well formed html page, eg account for missing head etc
  let b = inner[1]
  var rs = newCall("newHtml",h,b)
  #echo "rs------"
  #echo treerepr rs
  #echo "------rs"
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
  dump result

when true:
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
          p "dsl","!!"
     
  echo page()

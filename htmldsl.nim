import strutils,macros

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
    return "Html:\n  " & $n.head & "\n  " & $n.body
  of nkHead:
    result = "Head:\n  " & $n.title 
    for m in n.meta:
      result &= "\n  "& $m
  of nkMeta:
    return "  Meta: " & $n.name & ": " & $n.content
  of nkBody:
    result ="Body:\n  "
    for s in n.sons:
     result &= $s & "\n  "
  of nkDiv:
    result ="  Div:\n  "
    for s in n.sons:
     result &= $s & "\n  "
  of nkTitle:
    return "  Title:" & $n.val
  of nkP:
    return "    P:" & $n.text
  else:
    return "#gibberish" 

macro html*(name:untyped, inner:untyped):typed=
  let h = inner[0] #TODO: do not assume a well formed html page, eg account for missing head etc
  let b = inner[1]
  result = quote do:
    proc `name`():HtmlNode =
      var res= HtmlNode(kind: nkHtml)
      res.head = `h`
      res.body = `b`
      return res

proc newHead*(title:HtmlNode,meta:varargs[HtmlNode]): HtmlNode = 
  result = HtmlNode(kind:nkHead, title:title, meta: @[])
  result.meta &= meta

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

proc newBody*(sons:varargs[HtmlNode]): HtmlNode = 
  result = HtmlNode(kind:nkBody, sons: @[]) 
  result.sons &= sons
   
macro body*(inner:untyped):HtmlNode = 
  if inner.kind == nnkCall :
    result = newCall("newBody",inner)  
  else:
    result = newCall(!"newBody")
    for i in inner:
      result.add(i)

proc newDiv*(sons:varargs[HtmlNode]): HtmlNode = 
  result = HtmlNode(kind:nkDiv, sons: @[]) 
  result.sons &= sons
   
macro dv*(inner:untyped):HtmlNode = 
  # div is a keyword, integer div
  if inner.kind == nnkCall :
    result = newCall("newDiv",inner)  
  else:
   # expandmacros inner
    result = newCall(!"newDiv")
    for i in inner:
      result.add(i)

proc p*(x:varargs[string, `$`]):HtmlNode = 
  var xx = ""
  for s in x: xx &= s
  result = HtmlNode(kind:nkP, text: xx)

#[macro repeat(times:static[int],inner:untyped):untyped =  
  result = newNimnode(nnkBracket)
  for i in 1..times:
    for n in inner:
      result.add(n)]#

proc repeat*(times:int=1,what:HtmlNode): seq[HtmlNode] =
  result = newSeq[HtmlNode](times)
  for el in result.mitems: el =what

when isMainModule:
  var x = 2
   
  html pg :
    head:
      title(if x==2:"hi" else:"ho")
      meta "author", "stisa"
    body:
      dv:
        repeat(2,p "Ha")

  echo pg()

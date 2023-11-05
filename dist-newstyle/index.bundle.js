(()=>{"use strict";var __webpack_modules__={268:(e,t,r)=>{r.d(t,{BE:()=>P,IM:()=>D,IX:()=>h,Z_:()=>y,a0:()=>T,a2:()=>M,bc:()=>O,cS:()=>x});var n=r(849);class _{encode(e){const t=f(this,e),r=new Uint8Array(t);return g(this,r,0,e),r}decode(e){const[t,r]=E(this,e,0);return t}}class a extends _{}class s extends _{}class i extends _{}class o extends _{}class l extends _{constructor(e){super(),this._element=e}}class c extends _{constructor(e){super(),this._description=e}}class p extends _{constructor(e){super(),this._alternatives=e}}class u extends _{constructor(e){super(),this._self=e}}class d extends _{constructor(e){super(),this._tuple=e}}function f(e,t){if(e instanceof a)return 1;if(e instanceof s)return 8;if(e instanceof o){const e=t;return 8+(new TextEncoder).encode(e).length}if(e instanceof i)return 8+t.length;if(e instanceof l){const r=8;return t.reduce(((t,r)=>t+f(e._element,r)),r)}if(e instanceof c){const r=t;return Object.keys(e._description).reduce(((t,n)=>t+f(e._description[n],r[n])),0)}if(e instanceof p){const r=t;return b(Object.keys(e._alternatives).length)+f(e._alternatives[r.tag],r)}if(e instanceof u)return f(e._self,t);if(e instanceof d){const r=t;return e._tuple.reduce(((e,t,n)=>e+f(t,r[n])),0)}return(0,n.R)(e)}function E(e,t,r){if(e instanceof a)return[t[r],r+1];if(e instanceof s)return[t[r+7]+(t[r+6]<<8)+(t[r+5]<<16)+(t[r+4]<<24)+(t[r+3]<<32)+(t[r+2]<<40)+(t[r+1]<<48)+(t[r]<<56),r+8];if(e instanceof o){const e=t[r+7]+(t[r+6]<<8)+(t[r+5]<<16)+(t[r+4]<<24)+(t[r+3]<<32)+(t[r+2]<<40)+(t[r+1]<<48)+(t[r]<<56),n=t.subarray(r+8,r+8+e);return[new TextDecoder("utf8").decode(n),r+8+e]}if(e instanceof i){const e=t[r+7]+(t[r+6]<<8)+(t[r+5]<<16)+(t[r+4]<<24)+(t[r+3]<<32)+(t[r+2]<<40)+(t[r+1]<<48)+(t[r]<<56);return[t.subarray(r+8,r+8+e),r+8+e]}if(e instanceof l){const n=t[r+7]+(t[r+6]<<8)+(t[r+5]<<16)+(t[r+4]<<24)+(t[r+3]<<32)+(t[r+2]<<40)+(t[r+1]<<48)+(t[r]<<56),_=[];let a=r+8;for(let r=0;r<n;r++){const[r,n]=E(e._element,t,a);_.push(r),a=n}return[_,a]}if(e instanceof c){let n=r;return[Object.fromEntries(Object.entries(e._description).map((([e,r])=>{const[_,a]=E(r,t,n);return n=a,[e,_]}))),n]}if(e instanceof p){const n=b(Object.keys(e._alternatives).length),[_,a]=function(e,t,r){if(1!=e)throw new Error("Unimplemented");return[t[r],r+1]}(n,t,r),[s,i]=E(e._alternatives[_],t,a);return s.tag=_,[s,i]}if(e instanceof u)return E(e._self,t,r);if(e instanceof d){let n=r;return[e._tuple.map((e=>{const[r,_]=E(e,t,n);return n=_,r})),n]}return(0,n.R)(e)}function g(e,t,r,_){if(e instanceof a)return t[r]=_,r+1;if(e instanceof s){const e=_;return t[r+7]=255&e,t[r+6]=e>>8&255,t[r+5]=e>>16&255,t[r+4]=e>>24&255,r+8}if(e instanceof o){const e=_,n=(new TextEncoder).encode(e),a=n.length;return t[r+7]=255&a,t[r+6]=a>>8&255,t[r+5]=a>>16&255,t[r+4]=a>>24&255,t.set(n,r+8),r+8+a}if(e instanceof i){const e=_,n=e.length;return t[r+7]=255&n,t[r+6]=n>>8&255,t[r+5]=n>>16&255,t[r+4]=n>>24&255,t.set(e,r+8),r+8+n}if(e instanceof l){const n=_,a=n.length;t[r+7]=255&a,t[r+6]=a>>8&255,t[r+5]=a>>16&255,t[r+4]=a>>24&255;let s=r+8;for(let r=0;r<a;r++)s=g(e._element,t,s,n[r]);return s}if(e instanceof c){const n=_;let a=r;for(const r in e._description)Object.prototype.hasOwnProperty.call(e._description,r)&&(a=g(e._description[r],t,a,n[r]));return a}if(e instanceof p){const n=_.tag,a=b(Object.keys(e._alternatives).length);return t[r]=n,g(e._alternatives[n],t,r+a,_)}if(e instanceof u)return g(e._self,t,r,_);if(e instanceof d){const n=_;let a=r;return e._tuple.forEach(((e,r)=>{a=g(e,t,a,n[r])})),a}return(0,n.R)(e)}function b(e){return Math.ceil(Math.log2(e)/8)}const x=new a,M=new s,y=new o;function h(e){return new l(e)}function D(e){return new c(e)}function T(e){return new p(e)}function O(...e){return new d(e)}function P(e){const t=new u(void 0),r=e(t);return t._self=r,r}new i},849:(e,t,r)=>{function n(e){throw new Error("absurd: unreachable code")}r.d(t,{R:()=>n})},741:(__unused_webpack_module,__webpack_exports__,__webpack_require__)=>{__webpack_require__.d(__webpack_exports__,{Ub:()=>HaskellMessageTag,Xq:()=>unknownToJValue,bK:()=>JavaScriptMessageTag,f:()=>mkStartMessage,iI:()=>haskellMessage,r:()=>javascriptMessage,sN:()=>evalExpr});var _binary__WEBPACK_IMPORTED_MODULE_0__=__webpack_require__(268),_lib__WEBPACK_IMPORTED_MODULE_1__=__webpack_require__(849),JValueTag;function Cons(e,t){return[e,t]}function car(e){return e[0]}function cdr(e){return e[1]}function evalExpr(idenScope,argScope,hscb,exp){var _a;switch(exp.tag){case ExprTag.Null:return null;case ExprTag.Boolean:return 0!=exp[0];case ExprTag.Num:return exp.coefficient*Math.pow(10,exp.base10Exponent);case ExprTag.Str:return exp[0];case ExprTag.Arr:return exp[0].map(evalExpr.bind(void 0,idenScope,argScope,hscb));case ExprTag.Obj:return Object.fromEntries(exp[0].map((([e,t])=>[e,evalExpr(idenScope,argScope,hscb,t)])));case ExprTag.Dot:{const e=evalExpr(idenScope,argScope,hscb,exp[0]);return e[exp[1]]}case ExprTag.AssignProp:{const e=evalExpr(idenScope,argScope,hscb,exp[2]),t=evalExpr(idenScope,argScope,hscb,exp[0]);return t[exp[1]]=e,e}case ExprTag.Ix:{const e=evalExpr(idenScope,argScope,hscb,exp.exp);return e[exp.ix]}case ExprTag.Add:{const e=evalExpr(idenScope,argScope,hscb,exp[0]),t=evalExpr(idenScope,argScope,hscb,exp[1]);return e+t}case ExprTag.Subtract:{const e=evalExpr(idenScope,argScope,hscb,exp[0]),t=evalExpr(idenScope,argScope,hscb,exp[1]);return e-t}case ExprTag.Multiply:{const e=evalExpr(idenScope,argScope,hscb,exp[0]),t=evalExpr(idenScope,argScope,hscb,exp[1]);return e*t}case ExprTag.Divide:{const e=evalExpr(idenScope,argScope,hscb,exp[0]),t=evalExpr(idenScope,argScope,hscb,exp[1]);return e/t}case ExprTag.Id:{const e=exp[0];for(let t=idenScope;t;t=cdr(t)){const r=car(t);if(e in r)return r[e]}throw new Error("Variable not in scope: "+exp[0])}case ExprTag.Lam:return function(){return evalExpr(idenScope,Cons(arguments,argScope),hscb,exp.body)};case ExprTag.Arg:{let e=argScope,t=0;for(;e;){if(t==exp.scopeIx){const t=car(e);return t[exp.argIx]}e=cdr(e),t++}throw new Error("Argument scope out of a range: "+exp.scopeIx)}case ExprTag.Apply:{const e=evalExpr(idenScope,argScope,hscb,exp[0]);return e.apply(void 0,exp[1].map(evalExpr.bind(void 0,idenScope,argScope,hscb)))}case ExprTag.Call:{const e=evalExpr(idenScope,argScope,hscb,exp[0]),t=e[exp[1]];return t.apply(e,exp[2].map(evalExpr.bind(void 0,idenScope,argScope,hscb)))}case ExprTag.AssignVar:{const e=evalExpr(idenScope,argScope,hscb,exp.rhs);if(varStorage.has(exp.scopeId)){const t=varStorage.get(exp.scopeId);t.set(exp.varId,e)}else{const t=new Map;t.set(exp.varId,e),varStorage.set(exp.scopeId,t)}return e}case ExprTag.FreeVar:return;case ExprTag.Var:return null===(_a=varStorage.get(exp.scopeId))||void 0===_a?void 0:_a.get(exp.varId);case ExprTag.FreeScope:return varStorage.delete(exp.scopeId);case ExprTag.InsertNode:{const e=evalExpr(idenScope,argScope,hscb,exp.parent),t=evalExpr(idenScope,argScope,hscb,exp.child);return domBuilder.insertIntoBuilder(e,t),null}case ExprTag.WithBuilder:{const e=evalExpr(idenScope,argScope,hscb,exp.builder),t=evalExpr(idenScope,argScope,hscb,exp.builderContent);return t(e),e}case ExprTag.CreateElement:return document.createElement(exp.tagName);case ExprTag.CreateText:return document.createTextNode(exp.content);case ExprTag.ElementProp:{const e=evalExpr(idenScope,argScope,hscb,exp.node),t=evalExpr(idenScope,argScope,hscb,exp.propValue);return domBuilder.assignProperty(e,exp.propName,t),null}case ExprTag.ElementAttr:{const e=evalExpr(idenScope,argScope,hscb,exp.node);return domBuilder.assignAttribute(e,exp.attrName,exp.attrValue),null}case ExprTag.AddEventListener:{const e=evalExpr(idenScope,argScope,hscb,exp.node),t=evalExpr(idenScope,argScope,hscb,exp.listener);return domBuilder.addEventListener(e,exp.eventName,t),null}case ExprTag.ToggleClass:{const e=evalExpr(idenScope,argScope,hscb,exp.node);return domBuilder.toggleClass(e,exp.className,Boolean(exp.enable)),null}case ExprTag.AssignText:{const e=evalExpr(idenScope,argScope,hscb,exp.node);return e.textContent=exp.content,null}case ExprTag.InsertBoundary:{const e=evalExpr(idenScope,argScope,hscb,exp.parent);return domBuilder.insertBoundary(e)}case ExprTag.ClearBoundary:{const e=evalExpr(idenScope,argScope,hscb,exp.boundary);return domBuilder.clearBoundary(e,Boolean(exp.detach))}case ExprTag.RevSeq:return exp.exprs.reduceRight(((e,t)=>evalExpr(idenScope,argScope,hscb,t)),null);case ExprTag.Eval:return eval(exp.rawJavaScript);case ExprTag.TriggerEvent:{const e=evalExpr(idenScope,argScope,hscb,exp.arg),t={tag:JavaScriptMessageTag.TriggerEvent,arg:unknownToJValue(e),callbackId:exp.callbackId};return hscb(t,argScope)}case ExprTag.AsyncCallback:{const e=evalExpr(idenScope,argScope,hscb,exp.arg),t={tag:JavaScriptMessageTag.AsyncCallback,arg:unknownToJValue(e),callbackId:exp.callbackId};return hscb(t,argScope)}case ExprTag.UncaughtException:throw new Error(exp.message)}(0,_lib__WEBPACK_IMPORTED_MODULE_1__.R)(exp)}function unknownToJValue(e){if("boolean"==typeof e)return{tag:JValueTag.JBool,0:e?1:0};if("number"==typeof e){const{coefficient:t,base10Exponent:r}=toScientific(e);return{tag:JValueTag.JNum,coefficient:t,base10Exponent:r}}if("string"==typeof e)return{tag:JValueTag.JStr,0:e};if(Array.isArray(e))return{tag:JValueTag.JArr,0:e.map(unknownToJValue)};if(null==e)return{tag:JValueTag.JNull};const t=Object.entries(e).map((([e,t])=>[e,unknownToJValue(t)]));return{tag:JValueTag.JObj,0:t}}function toScientific(e){if(0===e)return{coefficient:0,base10Exponent:0};let t=0,r=e;for(;r%10!=0;)r*=10,t--;return{coefficient:r,base10Exponent:t}}!function(e){e[e.JObj=0]="JObj",e[e.JArr=1]="JArr",e[e.JStr=2]="JStr",e[e.JNum=3]="JNum",e[e.JBool=4]="JBool",e[e.JNull=5]="JNull"}(JValueTag||(JValueTag={}));const jvalue=_binary__WEBPACK_IMPORTED_MODULE_0__.BE((e=>_binary__WEBPACK_IMPORTED_MODULE_0__.a0({[JValueTag.JObj]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:_binary__WEBPACK_IMPORTED_MODULE_0__.IX(_binary__WEBPACK_IMPORTED_MODULE_0__.bc(_binary__WEBPACK_IMPORTED_MODULE_0__.Z_,e))}),[JValueTag.JArr]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:_binary__WEBPACK_IMPORTED_MODULE_0__.IX(e)}),[JValueTag.JStr]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_}),[JValueTag.JNum]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({coefficient:_binary__WEBPACK_IMPORTED_MODULE_0__.a2,base10Exponent:_binary__WEBPACK_IMPORTED_MODULE_0__.cS}),[JValueTag.JBool]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:_binary__WEBPACK_IMPORTED_MODULE_0__.cS}),[JValueTag.JNull]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({})}))),startLocation=_binary__WEBPACK_IMPORTED_MODULE_0__.IM({protocol:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_,hostname:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_,port:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_,pathname:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_,search:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_,hash:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_}),startFlags=_binary__WEBPACK_IMPORTED_MODULE_0__.IM({initial_url:startLocation});var ExprTag;!function(e){e[e.Null=0]="Null",e[e.Boolean=1]="Boolean",e[e.Num=2]="Num",e[e.Str=3]="Str",e[e.Arr=4]="Arr",e[e.Obj=5]="Obj",e[e.Dot=6]="Dot",e[e.AssignProp=7]="AssignProp",e[e.Ix=8]="Ix",e[e.Add=9]="Add",e[e.Subtract=10]="Subtract",e[e.Multiply=11]="Multiply",e[e.Divide=12]="Divide",e[e.Id=13]="Id",e[e.Lam=14]="Lam",e[e.Arg=15]="Arg",e[e.Apply=16]="Apply",e[e.Call=17]="Call",e[e.AssignVar=18]="AssignVar",e[e.FreeVar=19]="FreeVar",e[e.Var=20]="Var",e[e.FreeScope=21]="FreeScope",e[e.InsertNode=22]="InsertNode",e[e.WithBuilder=23]="WithBuilder",e[e.CreateElement=24]="CreateElement",e[e.CreateText=25]="CreateText",e[e.ElementProp=26]="ElementProp",e[e.ElementAttr=27]="ElementAttr",e[e.AddEventListener=28]="AddEventListener",e[e.ToggleClass=29]="ToggleClass",e[e.AssignText=30]="AssignText",e[e.InsertBoundary=31]="InsertBoundary",e[e.ClearBoundary=32]="ClearBoundary",e[e.RevSeq=33]="RevSeq",e[e.Eval=34]="Eval",e[e.TriggerEvent=35]="TriggerEvent",e[e.AsyncCallback=36]="AsyncCallback",e[e.UncaughtException=37]="UncaughtException"}(ExprTag||(ExprTag={}));const expr=_binary__WEBPACK_IMPORTED_MODULE_0__.BE((e=>_binary__WEBPACK_IMPORTED_MODULE_0__.a0({[ExprTag.Null]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({}),[ExprTag.Boolean]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:_binary__WEBPACK_IMPORTED_MODULE_0__.cS}),[ExprTag.Num]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({coefficient:_binary__WEBPACK_IMPORTED_MODULE_0__.a2,base10Exponent:_binary__WEBPACK_IMPORTED_MODULE_0__.cS}),[ExprTag.Str]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_}),[ExprTag.Arr]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:_binary__WEBPACK_IMPORTED_MODULE_0__.IX(e)}),[ExprTag.Obj]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:_binary__WEBPACK_IMPORTED_MODULE_0__.IX(_binary__WEBPACK_IMPORTED_MODULE_0__.bc(_binary__WEBPACK_IMPORTED_MODULE_0__.Z_,e))}),[ExprTag.Dot]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:e,1:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_}),[ExprTag.AssignProp]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:e,1:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_,2:e}),[ExprTag.Ix]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({exp:e,ix:_binary__WEBPACK_IMPORTED_MODULE_0__.a2}),[ExprTag.Add]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:e,1:e}),[ExprTag.Subtract]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:e,1:e}),[ExprTag.Multiply]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:e,1:e}),[ExprTag.Divide]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:e,1:e}),[ExprTag.Id]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_}),[ExprTag.Lam]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({body:e}),[ExprTag.Arg]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({scopeIx:_binary__WEBPACK_IMPORTED_MODULE_0__.cS,argIx:_binary__WEBPACK_IMPORTED_MODULE_0__.cS}),[ExprTag.Apply]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:e,1:_binary__WEBPACK_IMPORTED_MODULE_0__.IX(e)}),[ExprTag.Call]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:e,1:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_,2:_binary__WEBPACK_IMPORTED_MODULE_0__.IX(e)}),[ExprTag.AssignVar]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({scopeId:_binary__WEBPACK_IMPORTED_MODULE_0__.a2,varId:_binary__WEBPACK_IMPORTED_MODULE_0__.a2,rhs:e}),[ExprTag.FreeVar]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({scopeId:_binary__WEBPACK_IMPORTED_MODULE_0__.a2,varId:_binary__WEBPACK_IMPORTED_MODULE_0__.a2}),[ExprTag.Var]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({scopeId:_binary__WEBPACK_IMPORTED_MODULE_0__.a2,varId:_binary__WEBPACK_IMPORTED_MODULE_0__.a2}),[ExprTag.FreeScope]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({scopeId:_binary__WEBPACK_IMPORTED_MODULE_0__.a2}),[ExprTag.InsertNode]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({parent:e,child:e}),[ExprTag.WithBuilder]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({builder:e,builderContent:e}),[ExprTag.CreateElement]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({tagName:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_}),[ExprTag.CreateText]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({content:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_}),[ExprTag.ElementProp]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({node:e,propName:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_,propValue:e}),[ExprTag.ElementAttr]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({node:e,attrName:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_,attrValue:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_}),[ExprTag.AddEventListener]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({node:e,eventName:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_,listener:e}),[ExprTag.ToggleClass]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({node:e,className:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_,enable:_binary__WEBPACK_IMPORTED_MODULE_0__.cS}),[ExprTag.AssignText]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({node:e,content:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_}),[ExprTag.InsertBoundary]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({parent:e}),[ExprTag.ClearBoundary]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({boundary:e,detach:_binary__WEBPACK_IMPORTED_MODULE_0__.cS}),[ExprTag.RevSeq]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({exprs:_binary__WEBPACK_IMPORTED_MODULE_0__.IX(e)}),[ExprTag.Eval]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({rawJavaScript:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_}),[ExprTag.TriggerEvent]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({callbackId:_binary__WEBPACK_IMPORTED_MODULE_0__.a2,arg:e}),[ExprTag.AsyncCallback]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({callbackId:_binary__WEBPACK_IMPORTED_MODULE_0__.a2,arg:e}),[ExprTag.UncaughtException]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({message:_binary__WEBPACK_IMPORTED_MODULE_0__.Z_})})));var HaskellMessageTag;!function(e){e[e.EvalExpr=0]="EvalExpr",e[e.Yield=1]="Yield",e[e.HotReload=2]="HotReload",e[e.Exit=3]="Exit"}(HaskellMessageTag||(HaskellMessageTag={}));const haskellMessage=_binary__WEBPACK_IMPORTED_MODULE_0__.a0({[HaskellMessageTag.EvalExpr]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({expr}),[HaskellMessageTag.Yield]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({expr}),[HaskellMessageTag.HotReload]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({}),[HaskellMessageTag.Exit]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({})});var JavaScriptMessageTag;!function(e){e[e.Start=0]="Start",e[e.Return=1]="Return",e[e.TriggerEvent=2]="TriggerEvent",e[e.AsyncCallback=3]="AsyncCallback",e[e.BeforeUnload=4]="BeforeUnload"}(JavaScriptMessageTag||(JavaScriptMessageTag={}));const javascriptMessage=_binary__WEBPACK_IMPORTED_MODULE_0__.a0({[JavaScriptMessageTag.Start]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({startFlags}),[JavaScriptMessageTag.Return]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({0:jvalue}),[JavaScriptMessageTag.TriggerEvent]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({arg:jvalue,callbackId:_binary__WEBPACK_IMPORTED_MODULE_0__.a2}),[JavaScriptMessageTag.AsyncCallback]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({arg:jvalue,callbackId:_binary__WEBPACK_IMPORTED_MODULE_0__.a2}),[JavaScriptMessageTag.BeforeUnload]:_binary__WEBPACK_IMPORTED_MODULE_0__.IM({})}),varStorage=new Map;function mkStartMessage(){const e={protocol:location.protocol,hostname:location.hostname,port:location.port,pathname:location.pathname,search:location.search,hash:location.hash};return{tag:JavaScriptMessageTag.Start,startFlags:{initial_url:e}}}var domBuilder;!function(e){function t(e,t){e instanceof Comment?e.parentElement.insertBefore(t,e):e.appendChild(t)}function r(e){return e instanceof Comment?e.parentElement:e}function n(e){return e instanceof Comment&&"ContentBoundary {{"==e.textContent}e.insertIntoBuilder=t,e.assignProperty=function(e,t,r){e instanceof Comment?e.parentElement[t]=r:e[t]=r},e.assignAttribute=function(e,t,n){r(e).setAttribute(t,n)},e.addEventListener=function(e,t,n){r(e).addEventListener(t,n)},e.toggleClass=function(e,t,n){const _=r(e);n?_.classList.add(t):_.classList.remove(t)},e.insertBoundary=function(e){const r=document.createComment("ContentBoundary {{"),n=document.createComment("}}");return t(e,r),t(e,n),n},e.clearBoundary=function(e,t){const r=e;let _=0;for(;r.previousSibling&&(0!=_||!n(r.previousSibling));)(a=r.previousSibling)instanceof Comment&&"}}"==a.textContent?_++:n(r.previousSibling)&&_--,r.previousSibling.parentNode.removeChild(r.previousSibling);var a;t&&(r.previousSibling.parentNode.removeChild(r.previousSibling),r.parentNode.removeChild(r))}}(domBuilder||(domBuilder={}))}},__webpack_module_cache__={};function __webpack_require__(e){var t=__webpack_module_cache__[e];if(void 0!==t)return t.exports;var r=__webpack_module_cache__[e]={exports:{}};return __webpack_modules__[e](r,r.exports,__webpack_require__),r.exports}__webpack_require__.d=(e,t)=>{for(var r in t)__webpack_require__.o(t,r)&&!__webpack_require__.o(e,r)&&Object.defineProperty(e,r,{enumerable:!0,get:t[r]})},__webpack_require__.o=(e,t)=>Object.prototype.hasOwnProperty.call(e,t);var __webpack_exports__={};(()=>{function e(e,t,r,n){return new(r||(r=Promise))((function(_,a){function s(e){try{o(n.next(e))}catch(e){a(e)}}function i(e){try{o(n.throw(e))}catch(e){a(e)}}function o(e){var t;e.done?_(e.value):(t=e.value,t instanceof r?t:new r((function(e){e(t)}))).then(s,i)}o((n=n.apply(e,t||[])).next())}))}Object.create,Object.create,"function"==typeof SuppressedError&&SuppressedError;class t{static read_bytes(e,r){let n=new t;return n.buf=e.getUint32(r,!0),n.buf_len=e.getUint32(r+4,!0),n}static read_bytes_array(e,r,n){let _=[];for(let a=0;a<n;a++)_.push(t.read_bytes(e,r+8*a));return _}}class r{static read_bytes(e,t){let n=new r;return n.buf=e.getUint32(t,!0),n.buf_len=e.getUint32(t+4,!0),n}static read_bytes_array(e,t,n){let _=[];for(let a=0;a<n;a++)_.push(r.read_bytes(e,t+8*a));return _}}class n{write_bytes(e,t){e.setUint8(t,this.fs_filetype),e.setUint16(t+2,this.fs_flags,!0),e.setBigUint64(t+8,this.fs_rights_base,!0),e.setBigUint64(t+16,this.fs_rights_inherited,!0)}constructor(e,t){this.fs_rights_base=0n,this.fs_rights_inherited=0n,this.fs_filetype=e,this.fs_flags=t}}class _{write_bytes(e,t){e.setBigUint64(t,this.dev,!0),e.setBigUint64(t+8,this.ino,!0),e.setUint8(t+16,this.filetype),e.setBigUint64(t+24,this.nlink,!0),e.setBigUint64(t+32,this.size,!0),e.setBigUint64(t+38,this.atim,!0),e.setBigUint64(t+46,this.mtim,!0),e.setBigUint64(t+52,this.ctim,!0)}constructor(e,t){this.dev=0n,this.ino=0n,this.nlink=0n,this.atim=0n,this.mtim=0n,this.ctim=0n,this.filetype=e,this.size=t}}class a{fd_advise(e,t,r){return-1}fd_allocate(e,t){return-1}fd_close(){return 0}fd_datasync(){return-1}fd_fdstat_get(){return{ret:-1,fdstat:null}}fd_fdstat_set_flags(e){return-1}fd_fdstat_set_rights(e,t){return-1}fd_filestat_get(){return{ret:-1,filestat:null}}fd_filestat_set_size(e){return-1}fd_filestat_set_times(e,t,r){return-1}fd_pread(e,t,r){return{ret:-1,nread:0}}fd_prestat_get(){return{ret:-1,prestat:null}}fd_prestat_dir_name(e,t){return{ret:-1,prestat_dir_name:null}}fd_pwrite(e,t,r){return{ret:-1,nwritten:0}}fd_read(e,t){return{ret:-1,nread:0}}fd_readdir_single(e){return{ret:-1,dirent:null}}fd_seek(e,t){return{ret:-1,offset:0n}}fd_sync(){return 0}fd_tell(){return{ret:-1,offset:0n}}fd_write(e,t){return{ret:-1,nwritten:0}}path_create_directory(e){return-1}path_filestat_get(e,t){return{ret:-1,filestat:null}}path_filestat_set_times(e,t,r,n,_){return-1}path_link(e,t,r,n){return-1}path_open(e,t,r,n,_,a){return{ret:-1,fd_obj:null}}path_readlink(e){return{ret:-1,data:null}}path_remove_directory(e){return-1}path_rename(e,t,r){return-1}path_symlink(e,t){return-1}path_unlink_file(e){return-1}}class s extends a{fd_fdstat_get(){return{ret:0,fdstat:new n(4,0)}}fd_read(e,t){let r=0;for(let n of t){if(!(this.file_pos<this.file.data.byteLength))break;{let t=this.file.data.slice(Number(this.file_pos),Number(this.file_pos+BigInt(n.buf_len)));e.set(t,n.buf),this.file_pos+=BigInt(t.length),r+=t.length}}return{ret:0,nread:r}}fd_seek(e,t){let r;switch(t){case 0:r=e;break;case 1:r=this.file_pos+e;break;case 2:r=BigInt(this.file.data.byteLength)+e;break;default:return{ret:28,offset:0n}}return r<0?{ret:28,offset:0n}:(this.file_pos=r,{ret:0,offset:this.file_pos})}fd_write(e,t){let r=0;if(this.file.readonly)return{ret:8,nwritten:r};for(let n of t){let t=e.slice(n.buf,n.buf+n.buf_len);if(this.file_pos+BigInt(t.byteLength)>this.file.size){let e=this.file.data;this.file.data=new Uint8Array(Number(this.file_pos+BigInt(t.byteLength))),this.file.data.set(e)}this.file.data.set(t.slice(0,Number(this.file.size-this.file_pos)),Number(this.file_pos)),this.file_pos+=BigInt(t.byteLength),r+=n.buf_len}return{ret:0,nwritten:r}}fd_filestat_get(){return{ret:0,filestat:this.file.stat()}}constructor(e){super(),this.file_pos=0n,this.file=e}}class i{open(e){let t=new s(this);return 1&e&&t.fd_seek(0n,2),t}get size(){return BigInt(this.data.byteLength)}stat(){return new _(4,this.size)}truncate(){return this.readonly?63:(this.data=new Uint8Array([]),0)}constructor(e,t){this.data=new Uint8Array(e),this.readonly=!!t?.readonly}}var o=__webpack_require__(849),l=__webpack_require__(741);function c(e,t,r=null){const n=t||l.f(),_=function(e,t){const r=function(e,t){const r=t.byteLength,n=e.exports.hs_malloc(t.length+8);return new DataView(e.exports.memory.buffer).setUint32(n,r,!0),new Uint8Array(e.exports.memory.buffer,n+8,r).set(t),n}(e,l.r.encode(t)),n=function(e,t){const r=new Uint8Array(e.exports.memory.buffer,t),n=r[0]+(r[1]<<8)+(r[2]<<16)+(r[3]<<24)+(r[4]<<32)+(r[5]<<40)+(r[6]<<48)+(r[7]<<56),_=new Uint8Array(e.exports.memory.buffer,t+8,n).slice().buffer;return e.exports.hs_free(t),new Uint8Array(_)}(e,e.exports.app(r));return l.iI.decode(n)}(e,n),a=(t,r)=>{c(e,t,r)};switch(_.tag){case l.Ub.EvalExpr:{const t=l.sN(p,r,a,_.expr),n=l.Xq(t);return c(e,{tag:l.bK.Return,0:n},r)}case l.Ub.Yield:return void l.sN(p,r,a,_.expr);case l.Ub.HotReload:return void window.location.reload();case l.Ub.Exit:return}(0,o.R)(_)}const p=[window,null];class u extends s{constructor(e,t){super(e),this.printDebug=t}fd_write(e,t){const r=super.fd_write(e,t);return t.forEach((r=>{this.printDebug(e.subarray(t[0].buf,r.buf+r.buf_len))})),r}}function d(e){let t=[];return r=>{const n=r=>{if(0==r.byteLength)return;const _=r.findIndex((e=>e=="\n".charCodeAt(0)));if(_>=0){const a=t.map((e=>new TextDecoder("utf8").decode(e))).join("");t=[];const s=new TextDecoder("utf8").decode(r.subarray(0,_));e(a+s),n(r.subarray(_+1))}else t.push(r.slice())};n(r)}}function f(t,r,n){return e(this,void 0,void 0,(function*(){switch(t.tag){case l.Ub.EvalExpr:{const e=l.sN(E,r,n,t.expr),_=l.Xq(e);return n({tag:l.bK.Return,0:_},r)}case l.Ub.Yield:return void l.sN(E,r,n,t.expr);case l.Ub.HotReload:return void window.location.reload();case l.Ub.Exit:return}(0,o.R)(t)}))}const E=[window,null];function g(e){return new Promise(((t,r)=>{const n=new FileReader;n.onload=()=>{const e=n.result,r=new Uint8Array(e);t(r)},n.onerror=e=>{r(e)},n.readAsArrayBuffer(e)}))}window.startReactor=function(n,_={}){return e(this,void 0,void 0,(function*(){const e=d(console.log),a=d(console.log),o=new class{start(e){this.inst=e,e.exports._start()}initialize(e){this.inst=e,e.exports._initialize()}constructor(e,n,_){this.args=[],this.env=[],this.fds=[],this.args=e,this.env=n,this.fds=_;let a=this;this.wasiImport={args_sizes_get(e,t){let r=new DataView(a.inst.exports.memory.buffer);r.setUint32(e,a.args.length,!0);let n=0;for(let e of a.args)n+=e.length+1;return r.setUint32(t,n,!0),0},args_get(e,t){let r=new DataView(a.inst.exports.memory.buffer),n=new Uint8Array(a.inst.exports.memory.buffer);for(let _=0;_<a.args.length;_++){r.setUint32(e,t,!0),e+=4;let s=new TextEncoder("utf-8").encode(a.args[_]);n.set(s,t),r.setUint8(t+s.length,0),t+=s.length+1}return 0},environ_sizes_get(e,t){let r=new DataView(a.inst.exports.memory.buffer);r.setUint32(e,a.env.length,!0);let n=0;for(let e of a.env)n+=e.length+1;return r.setUint32(t,n,!0),0},environ_get(e,t){let r=new DataView(a.inst.exports.memory.buffer),_=new Uint8Array(a.inst.exports.memory.buffer);for(let a=0;a<n.length;a++){r.setUint32(e,t,!0),e+=4;let s=new TextEncoder("utf-8").encode(n[a]);_.set(s,t),r.setUint8(t+s.length,0),t+=s.length+1}return 0},clock_res_get(e,t){throw"unimplemented"},clock_time_get(e,t,r){let n=new DataView(a.inst.exports.memory.buffer);if(0===e)n.setBigUint64(r,1000000n*BigInt((new Date).getTime()),!0);else if(1==e){let e;try{e=BigInt(Math.round(1e6*performance.now()))}catch(t){e=0n}n.setBigUint64(r,e,!0)}else n.setBigUint64(r,0n,!0);return 0},fd_advise:(e,t,r,n)=>null!=a.fds[e]?a.fds[e].fd_advise(t,r,n):8,fd_allocate:(e,t,r)=>null!=a.fds[e]?a.fds[e].fd_allocate(t,r):8,fd_close(e){if(null!=a.fds[e]){let t=a.fds[e].fd_close();return a.fds[e]=void 0,t}return 8},fd_datasync:e=>null!=a.fds[e]?a.fds[e].fd_datasync():8,fd_fdstat_get(e,t){if(null!=a.fds[e]){let{ret:r,fdstat:n}=a.fds[e].fd_fdstat_get();return null!=n&&n.write_bytes(new DataView(a.inst.exports.memory.buffer),t),r}return 8},fd_fdstat_set_flags:(e,t)=>null!=a.fds[e]?a.fds[e].fd_fdstat_set_flags(t):8,fd_fdstat_set_rights:(e,t,r)=>null!=a.fds[e]?a.fds[e].fd_fdstat_set_rights(t,r):8,fd_filestat_get(e,t){if(null!=a.fds[e]){let{ret:r,filestat:n}=a.fds[e].fd_filestat_get();return null!=n&&n.write_bytes(new DataView(a.inst.exports.memory.buffer),t),r}return 8},fd_filestat_set_size:(e,t)=>null!=a.fds[e]?a.fds[e].fd_filestat_set_size(t):8,fd_filestat_set_times:(e,t,r,n)=>null!=a.fds[e]?a.fds[e].fd_filestat_set_times(t,r,n):8,fd_pread(e,r,n,_,s){let i=new DataView(a.inst.exports.memory.buffer),o=new Uint8Array(a.inst.exports.memory.buffer);if(null!=a.fds[e]){let l=t.read_bytes_array(i,r,n),{ret:c,nread:p}=a.fds[e].fd_pread(o,l,_);return i.setUint32(s,p,!0),c}return 8},fd_prestat_get(e,t){let r=new DataView(a.inst.exports.memory.buffer);if(null!=a.fds[e]){let{ret:n,prestat:_}=a.fds[e].fd_prestat_get();return null!=_&&_.write_bytes(r,t),n}return 8},fd_prestat_dir_name(e,t,r){if(null!=a.fds[e]){let{ret:r,prestat_dir_name:n}=a.fds[e].fd_prestat_dir_name();return null!=n&&new Uint8Array(a.inst.exports.memory.buffer).set(n,t),r}return 8},fd_pwrite(e,t,n,_,s){let i=new DataView(a.inst.exports.memory.buffer),o=new Uint8Array(a.inst.exports.memory.buffer);if(null!=a.fds[e]){let l=r.read_bytes_array(i,t,n),{ret:c,nwritten:p}=a.fds[e].fd_pwrite(o,l,_);return i.setUint32(s,p,!0),c}return 8},fd_read(e,r,n,_){let s=new DataView(a.inst.exports.memory.buffer),i=new Uint8Array(a.inst.exports.memory.buffer);if(null!=a.fds[e]){let o=t.read_bytes_array(s,r,n),{ret:l,nread:c}=a.fds[e].fd_read(i,o);return s.setUint32(_,c,!0),l}return 8},fd_readdir(e,t,r,n,_){let s=new DataView(a.inst.exports.memory.buffer),i=new Uint8Array(a.inst.exports.memory.buffer);if(null!=a.fds[e]){let o=0;for(;;){let{ret:l,dirent:c}=a.fds[e].fd_readdir_single(n);if(0!=l)return s.setUint32(_,o,!0),l;if(null==c)break;if(r-o<c.head_length()){o=r;break}let p=new ArrayBuffer(c.head_length());if(c.write_head_bytes(new DataView(p),0),i.set(new Uint8Array(p).slice(0,Math.min(p.byteLength,r-o)),t),t+=c.head_length(),o+=c.head_length(),r-o<c.name_length()){o=r;break}c.write_name_bytes(i,t,r-o),t+=c.name_length(),o+=c.name_length(),n=c.d_next}return s.setUint32(_,o,!0),0}return 8},fd_renumber(e,t){if(null!=a.fds[e]&&null!=a.fds[t]){let r=a.fds[t].fd_close();return 0!=r?r:(a.fds[t]=a.fds[e],a.fds[e]=void 0,0)}return 8},fd_seek(e,t,r,n){let _=new DataView(a.inst.exports.memory.buffer);if(null!=a.fds[e]){let{ret:s,offset:i}=a.fds[e].fd_seek(t,r);return _.setBigInt64(n,i,!0),s}return 8},fd_sync:e=>null!=a.fds[e]?a.fds[e].fd_sync():8,fd_tell(e,t){let r=new DataView(a.inst.exports.memory.buffer);if(null!=a.fds[e]){let{ret:n,offset:_}=a.fds[e].fd_tell();return r.setBigUint64(t,_,!0),n}return 8},fd_write(e,t,n,_){let s=new DataView(a.inst.exports.memory.buffer),i=new Uint8Array(a.inst.exports.memory.buffer);if(null!=a.fds[e]){let o=r.read_bytes_array(s,t,n),{ret:l,nwritten:c}=a.fds[e].fd_write(i,o);return s.setUint32(_,c,!0),l}return 8},path_create_directory(e,t,r){let n=new Uint8Array(a.inst.exports.memory.buffer);if(null!=a.fds[e]){let _=new TextDecoder("utf-8").decode(n.slice(t,t+r));return a.fds[e].path_create_directory(_)}},path_filestat_get(e,t,r,n,_){let s=new DataView(a.inst.exports.memory.buffer),i=new Uint8Array(a.inst.exports.memory.buffer);if(null!=a.fds[e]){let o=new TextDecoder("utf-8").decode(i.slice(r,r+n)),{ret:l,filestat:c}=a.fds[e].path_filestat_get(t,o);return null!=c&&c.write_bytes(s,_),l}return 8},path_filestat_set_times(e,t,r,n,_,s,i){let o=new Uint8Array(a.inst.exports.memory.buffer);if(null!=a.fds[e]){let l=new TextDecoder("utf-8").decode(o.slice(r,r+n));return a.fds[e].path_filestat_set_times(t,l,_,s,i)}return 8},path_link(e,t,r,n,_,s,i){let o=new Uint8Array(a.inst.exports.memory.buffer);if(null!=a.fds[e]&&null!=a.fds[_]){let l=new TextDecoder("utf-8").decode(o.slice(r,r+n)),c=new TextDecoder("utf-8").decode(o.slice(s,s+i));return a.fds[_].path_link(e,t,l,c)}return 8},path_open(e,t,r,n,_,s,i,o,l){let c=new DataView(a.inst.exports.memory.buffer),p=new Uint8Array(a.inst.exports.memory.buffer);if(null!=a.fds[e]){let u=new TextDecoder("utf-8").decode(p.slice(r,r+n)),{ret:d,fd_obj:f}=a.fds[e].path_open(t,u,_,s,i,o);if(0!=d)return d;a.fds.push(f);let E=a.fds.length-1;return c.setUint32(l,E,!0),0}return 8},path_readlink(e,t,r,n,_,s){let i=new DataView(a.inst.exports.memory.buffer),o=new Uint8Array(a.inst.exports.memory.buffer);if(null!=a.fds[e]){let l=new TextDecoder("utf-8").decode(o.slice(t,t+r)),{ret:c,data:p}=a.fds[e].path_readlink(l);if(null!=p){if(p.length>_)return i.setUint32(s,0,!0),8;o.set(p,n),i.setUint32(s,p.length,!0)}return c}return 8},path_remove_directory(e,t,r){let n=new Uint8Array(a.inst.exports.memory.buffer);if(null!=a.fds[e]){let _=new TextDecoder("utf-8").decode(n.slice(t,t+r));return a.fds[e].path_remove_directory(_)}return 8},path_rename(e,t,r,n,_,a){throw"FIXME what is the best abstraction for this?"},path_symlink(e,t,r,n,_){let s=new Uint8Array(a.inst.exports.memory.buffer);if(null!=a.fds[r]){let i=new TextDecoder("utf-8").decode(s.slice(e,e+t)),o=new TextDecoder("utf-8").decode(s.slice(n,n+_));return a.fds[r].path_symlink(i,o)}return 8},path_unlink_file(e,t,r){let n=new Uint8Array(a.inst.exports.memory.buffer);if(null!=a.fds[e]){let _=new TextDecoder("utf-8").decode(n.slice(t,t+r));return a.fds[e].path_unlink_file(_)}return 8},poll_oneoff(e,t,r){throw"async io not supported"},proc_exit(e){throw"exit with exit code "+e},proc_raise(e){throw"raised signal "+e},sched_yield(){},random_get(e,t){let r=new Uint8Array(a.inst.exports.memory.buffer);for(let n=0;n<t;n++)r[e+n]=256*Math.random()|0},sock_recv(e,t,r){throw"sockets not supported"},sock_send(e,t,r){throw"sockets not supported"},sock_shutdown(e,t){throw"sockets not supported"},sock_accept(e,t){throw"sockets not supported"}}}}([],[],[new s(new i([])),new u(new i([]),e),new u(new i([]),a)]),p=yield WebAssembly.compileStreaming(fetch(n)),f=yield WebAssembly.instantiate(p,{wasi_snapshot_preview1:o.wasiImport});o.inst=f,_.greedyMem?f.exports.init_greadymem():f.exports.init_debug(),window.addEventListener("beforeunload",(()=>c(f,{tag:l.bK.BeforeUnload}))),c(f)}))},window.startDevClient=function(t){return e(this,void 0,void 0,(function*(){const r=new WebSocket(t),n=(t,_)=>e(this,void 0,void 0,(function*(){r.send(l.r.encode(t));const a=yield function(){return new Promise(((t,n)=>{const _=r.onmessage;r.onmessage=a=>e(this,void 0,void 0,(function*(){r.onmessage=_;try{const e=yield g(a.data),r=l.iI.decode(e);t(r)}catch(e){n(e)}}))}))}();yield f(a,_,n)}));r.onopen=e=>{const t=l.r.encode(l.f());r.send(t)},r.onmessage=t=>e(this,void 0,void 0,(function*(){const e=yield g(t.data);f(l.iI.decode(e),null,n)})),r.onerror=e=>{console.error("WebSocket error:",e)},r.onclose=e=>{console.log("WebSocket connection closed:",e)}}))}})()})();
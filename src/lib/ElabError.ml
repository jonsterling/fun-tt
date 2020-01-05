module CS = ConcreteSyntax
module D = Domain
module S = Syntax
open CoolBasis

type t =
  | UnboundVariable of CS.ident
  | ExpectedEqual of D.tp * D.t * D.t
  | ExpectedEqualTypes of D.tp * D.tp
  | InvalidTypeExpression of CS.t
  | ExpectedConnective of [`Pi | `Sg | `Id | `Nat] * D.tp
  | ExpectedSynthesizableTerm of S.t
[@@deriving show]

exception ElabError of t

let _ = 
  PpExn.install_printer @@ fun fmt ->
  function 
  | ElabError err ->
    pp fmt err 
  | _ -> 
    raise PpExn.Unrecognized
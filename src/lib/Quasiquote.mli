(** Constructing values in the semantic domain that go underneath binders is
    very difficult! In general you need to be able to form exactly the right
    closure for each binder, and it is usually not obvious how to do this,
    and it usually involves some awful De Bruijn arithmetic.

    An alternative is to create a term in an extended context, and then
    evaluate that in an environment that contains the values you want to
    "splice" into it; then, the resulting value will have the desired behavior.
    This module, which is called [Quasiquote] for lack of a better name,
    achieves this in an automatic way, avoiding all De Bruijn arithmetic.  *)

module S := Syntax
module D := Domain
module TB := TermBuilder

type 'a builder
val foreign : D.con -> (S.t TB.m -> 'a builder) -> 'a builder
val foreign_tp : D.tp -> (S.tp TB.m -> 'a builder) -> 'a builder
val compile : 'a builder -> D.env * 'a
val term : 'a TB.m -> 'a builder

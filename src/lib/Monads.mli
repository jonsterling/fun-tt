module D := Domain 
module S := Syntax
module St := ElabState
open CoolBasis

type 'a compute 
type 'a evaluate
type 'a quote

module CmpM : sig 
  include Monad.MonadReaderResult 
    with type 'a m = 'a compute
    with type local := St.t * Restriction.t

  val lift_ev : D.env -> 'a evaluate -> 'a m
  val compare_dim : D.dim -> D.dim -> [`Same | `Apart | `Indet] m
  val equal_dim : D.dim -> D.dim -> bool m
end

module EvM : sig 
  include Monad.MonadReaderResult 
    with type 'a m = 'a evaluate

  val lift_cmp : 'a compute -> 'a m

  val read_global : ElabState.t m
  val read_local : D.env m

  val close_tp : S.tp -> 'n D.tp_clo m
  val close_tm : S.t -> 'n D.tm_clo m
  val append : [`Con of D.con | `Dim of D.dim | `Prf] list -> 'a m -> 'a m
end

module QuM : sig 
  include Monad.MonadReaderResult 
    with type 'a m = 'a quote

  val lift_cmp : 'a compute -> 'a m

  val read_global : ElabState.t m
  val read_local : int m
  val read_veil : Veil.t m

  val binder : int -> 'a m -> 'a m
end

module ElabM : sig
  include Monad.MonadReaderStateResult 
    with type global := St.t
    with type local := ElabEnv.t

  val lift_qu : 'a quote -> 'a m
  val lift_ev : 'a evaluate -> 'a m
  val lift_cmp : 'a compute -> 'a m

  val veil : Veil.t -> 'a m -> 'a m

  val globally : 'a m -> 'a m
  val emit : (Format.formatter -> 'a -> unit) -> 'a -> unit m
end
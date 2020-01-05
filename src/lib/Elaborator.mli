module CS := ConcreteSyntax
module S := Syntax
module EM := Monads.ElabM
module D := Domain

open Refiner

val check_tp : CS.t -> tp_tac
val check_tm : CS.t -> chk_tac 
val synth_tm : CS.t -> syn_tac
module S = Syntax
open CoolBasis
open Bwd

type dim =
  | Dim0
  | Dim1
  | DimVar of int
  | DimProbe of Symbol.t

type cof = (dim, int) Cof.cof

type env = con bwd

and tp_clo = 
  | TpClo of S.tp * env
  | ElClo of con
  | ConstTpClo of tp 
  | CloFromPathData of con * con
  | CloBoundaryType of con

and tm_clo = 
  | Clo of S.t * env
  | PiCoeBaseClo of tm_clo
  | PiCoeFibClo of {dest : dim; base_abs : tm_clo; arg : con; clo: tm_clo}
  | SgCoeBaseClo of tm_clo
  | SgCoeFibClo of {src : dim; base_abs : tm_clo; fst : con; clo: tm_clo}
  | SgHComFibClo of {src : dim; base : con; fam : con; cof : cof; clo : tm_clo} 
  | AppClo of con * tm_clo
  | FstClo of tm_clo 
  | SndClo of tm_clo
  | ComClo of dim * tm_clo * tm_clo
  | SplitClo of tp * cof * cof * tm_clo * tm_clo
  | SubOutClo of tm_clo

and con =
  | Lam of tm_clo
  | ConCoe of [`Pi | `Sg | `Path] * tm_clo * dim * dim * con
  | ConHCom of [`Pi | `Sg | `Path] * con * dim * dim * cof * tm_clo
  | Cut of {tp : tp; cut : cut; unfold : lazy_con option}
  | Zero
  | Suc of con
  | Pair of con * con
  | Refl of con
  | GoalRet of con
  | Abort
  | SubIn of con
  | DimCon0
  | DimCon1
  | Cof of (con, con) Cof.cof_f
  | Prf

  | CodePath of con * con
  | CodePi of con * con
  | CodeSg of con * con
  | CodeNat


and tp = 
  | Sub of tp * cof * tm_clo
  | Univ
  | El of cut
  | GoalTp of string option * tp
  | TpDim 
  | TpCof
  | TpPrf of cof 
  | Pi of tp * tp_clo
  | Sg of tp * tp_clo
  | Id : tp * con * con -> tp
  | Nat

and hd =
  | Global of Symbol.t 
  | Var of int (* De Bruijn level *)
  | Coe of tm_clo * dim * dim * con
  | HCom of cut * dim * dim * cof * tm_clo
  | SubOut of cut * cof * tm_clo
  | Split of tp * cof * cof * tm_clo * tm_clo

and cut = hd * frm list

and lazy_con = [`Do of con * frm list | `Done of con]

and frm = 
  | KAp of tp * con
  | KFst 
  | KSnd
  | KNatElim of ghost option * tp_clo * con * tm_clo
  | KIdElim of ghost option * tp_clo * tm_clo * tp * con * con
  | KGoalProj

and ghost = string bwd * (tp * con) list

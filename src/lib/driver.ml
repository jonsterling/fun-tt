module CS = Concrete_syntax
module S = Syntax
module D = Domain

type env = Env of {size : int; check_env : Check.env; bindings : string list}

let initial_env = Env {size = 0; check_env = []; bindings = []}

type output =
    NoOutput of env
  | NF_term of S.t * D.t
  | NF_def of CS.ident * D.t
  | Quit

let update_env env = function
  | NoOutput env -> env
  | NF_term _ | NF_def _ | Quit -> env

let output (Env {bindings; _}) = function
  | NoOutput _ -> ()
  | NF_term (s, t) ->
    let open Sexplib in
    let s_rep = Syntax.to_sexp (List.map (fun x -> Sexp.Atom x) bindings) s
                |> Sexp.to_string_hum in
    Printf.printf "Computed normal form of\n%s\nas\n%s\n" s_rep (D.pp t)
  | NF_def (name, t) -> Printf.printf "Computed normal form of [%s]:\n%s\n" name (D.pp t)
  | Quit -> exit 0

let find_idx key =
  let rec go i = function
    | [] -> raise (Check.Type_error (Check.Misc ("Unbound variable: " ^ key)))
    | x :: xs -> if String.equal x key then i else go (i + 1) xs in
  go 0

let rec int_to_term = function
  | 0 -> S.Zero
  | n -> S.Suc (int_to_term (n - 1))

let rec unravel_spine f = function
  | [] -> f
  | x :: xs -> unravel_spine (x f) xs

let rec bind env = function
  | CS.Var i -> S.Var (find_idx i env)
  | CS.Let (tp, Binder {name; body}) ->
    S.Let (bind env tp, bind (name :: env) body)
  | CS.Check {term; tp} -> S.Check (bind env term, bind env tp)
  | CS.Nat -> S.Nat
  | CS.Suc t -> S.Suc (bind env t)
  | CS.Lit i -> int_to_term i
  | CS.NRec
      { mot = Binder {name = mot_name; body = mot_body};
        zero;
        suc = Binder2 {name1 = suc_name1; name2 = suc_name2; body = suc_body};
        nat} ->
    S.NRec
      (bind (mot_name :: env) mot_body,
       bind env zero,
       bind (suc_name2 :: suc_name1 :: env) suc_body,
       bind env nat)
  | CS.Pi (tp, Binder {name; body}) ->
    S.Pi (bind env tp, bind (name :: env) body)
  | CS.Lam (tp, Binder {name; body}) ->
    S.Lam (bind env tp, bind (name :: env) body)
  | CS.Ap (f, args) ->
    List.map (bind_spine env) args |> unravel_spine (bind env f)
  | CS.Sig (tp, Binder {name; body}) ->
    S.Sig (bind env tp, bind (name :: env) body)
  | CS.Pair (l, r) -> S.Pair (bind env l, bind env r)
  | CS.Fst p -> S.Fst (bind env p)
  | CS.Snd p -> S.Snd (bind env p)
  | CS.Later (Binder {name; body}) -> S.Later (bind (name :: env) body)
  | CS.Next (Binder {name; body}) -> S.Next (bind (name :: env) body)
  | CS.Bullet -> S.Bullet
  | CS.Box t -> S.Box (bind env t)
  | CS.Shut t -> S.Shut (bind env t)
  | CS.Open t -> S.Open (bind env t)
  | CS.DFix (tp, Binder {name; body}) ->
    S.DFix (bind env tp, bind (name :: env) body)
  | CS.Fold {uni; idx_tp; fix_body = Binder {name; body}; idx; term; tick} ->
    S.Fold
      (uni,
       bind env idx_tp,
       bind (name :: env) body,
       bind env idx,
       bind env term,
       bind env tick)
  | CS.Unfold {uni; idx_tp; fix_body = Binder {name; body}; idx; term; tick} ->
    S.Unfold
      (uni,
       bind env idx_tp,
       bind (name :: env) body,
       bind env idx,
       bind env term,
       bind env tick)
  | CS.Uni i -> S.Uni i

and bind_spine env = function
  | CS.Term t -> fun f -> S.Ap (f, bind env t)
  | CS.Tick t -> fun f -> S.Prev (f, bind env t)

let process_decl (Env {size; check_env; bindings})  = function
  | CS.Def {name; def; tp} ->
    let def = bind bindings def in
    let tp = bind bindings tp in
    Check.check_tp ~size ~env:check_env ~term:tp;
    let sem_env = Check.env_to_sem_env size check_env in
    let sem_tp = Nbe.eval tp sem_env in
    Check.check ~size ~env:check_env ~term:def ~tp:sem_tp;
    let sem_def = Nbe.eval def sem_env in
    let new_entry = Check.TopLevel {term = sem_def; tp = sem_tp} in
    NoOutput (Env {size = size + 1; check_env = new_entry :: check_env; bindings = name :: bindings })
  | CS.NormalizeDef name ->
    let err = Check.Type_error (Check.Misc ("Unbound variable: " ^ name)) in
    begin
      match List.nth check_env (find_idx name bindings) with
      | Check.TopLevel {term; _} -> NF_def (name, term)
      | _ -> raise err
      | exception Failure _ -> raise err
    end
  | CS.NormalizeTerm {term; tp} ->
    let term = bind bindings term in
    let tp = bind bindings tp in
    Check.check_tp ~size ~env:check_env ~term:tp;
    let sem_env = Check.env_to_sem_env size check_env in
    let sem_tp = Nbe.eval tp sem_env in
    Check.check ~size ~env:check_env ~term ~tp:sem_tp;
    NF_term (term, Nbe.eval term sem_env)
  | CS.Quit -> Quit

let rec process_sign ?env = function
  | [] -> ()
  | d :: ds ->
    let env = match env with
        None -> initial_env
      | Some e -> e in
    let o = process_decl env d in
    output env o;
    process_sign ?env:(Some (update_env env o)) ds


(*FINALIZED as of 5:53pm*)

let contains element list_l = List.mem element list_l  

let rec subset a b = match a with 
	| [] -> true 
	| hd::tl -> (List.mem hd b) && subset tl b

let equal_sets a b = subset a b && subset b a;;

let set_union a b = List.sort_uniq compare (List.append a b);;

let rec set_intersection a b = match a with 
	| [] -> []
	| hd::tl -> if contains hd b then hd::(set_intersection tl b)
				else (set_intersection tl b)  

let rec set_diff a b = match a with 
	| [] -> [] 
	| hd::tl-> if not (contains hd b) then hd::(set_diff tl b)
				else (set_diff tl b)

let rec computed_fixed_point eq f x = 
	if eq (f x) x  then x
	else (computed_fixed_point (eq) (f) (f x))

type ('nonterminal, 'terminal) symbol =
  | N of 'nonterminal
  | T of 'terminal;;


let is_NT element = match element with 
	| N n -> true
 	| _  -> false 
 (**everything above this point has been checked and is ready for turnin**)

(*results is always initially empty; go through all grammar rules, keep rules that we have nonterminal (startexpr) for*)
let rec reachable_rules_helper results available_nts rules = match rules with 
    | [] -> results 
    | (start_expr,sub_exprs)::tail -> if contains (N start_expr) available_nts (*if we have access to rule's start_expr*) 
        then reachable_rules_helper (sub_exprs @ results) available_nts tail (*add those subexpresions to results(available nts)*)
        else reachable_rules_helper results available_nts tail;;

(*takes in list of nonterminals/terminals and return list of nonterminals*)
let rec explore_sub l = match l with 
	| [] -> [] 
	| head::tail -> if is_NT head then head::explore_sub tail 
					else explore_sub tail 
let reachable_rules reached rules = reachable_rules_helper [] reached rules;;

(*gets all nonterminals from list of expressions and removes duplicates*)
let get_nts expressions = List.sort_uniq compare (explore_sub expressions)  

(*get all reachable rules by unioning old_reachable_rules with new_reachables*)
let all_reachables rules old_reachables = 
	let new_reachables = get_nts (reachable_rules old_reachables rules) in 
	set_union old_reachables new_reachables 

(*gets all reachable_rules by repeatedly finding reachable_rules until we've reached "fixed point" of reachable rules;*)
let fixed_reachables g =
	let grammar_rules = snd g in  
	let start_expr = fst g in (*the original starting_expression*) 
	computed_fixed_point  equal_sets (all_reachables grammar_rules) [N start_expr];;  

(*takes nonterminals, and retrieves resulting reachable rules *)
(** filter out rules whose start_expr we do not have in available_nts **)
let filter_helper g_rules available_nts = 
	List.filter(function curr_rule -> List.mem (N (fst curr_rule)) available_nts) g_rules;;

(*returns grammar as tuple that has same start point and all reachable rules*)
let filter_reachable g = 
	let start_expr = fst g in 
	let grammar_rules = snd g in 
	((start_expr, filter_helper grammar_rules (fixed_reachables g)));;


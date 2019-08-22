type ('nonterminal, 'terminal) symbol =
  | N of 'nonterminal
  | T of 'terminal

(*
create_list: returns the list of rules that correspond to a nonterminal symbol
convert_grammar: returns a tuple of (the grammar's start symbol) and (a function that returns the
    associated rules for a nonterminal symbol in the grammar)
*)
let convert_grammar gram1 =
    let rec create_list sym rules = match rules with
        [] -> []
        | (nt, rhs)::tail -> if sym = nt then rhs::(create_list sym tail) else create_list sym tail
    in
    (fst gram1, fun nonterm -> create_list nonterm (snd gram1));;

(*
parse_prefix: begins parsing the grammar by calling expand_nonterm on the starting nonterminal symbol
expand_nonterm: recursively tries each of the rules of the nonterminal symbol and returns if a rule works
match_terms: recursively tries to match the frag's prefix to each symbol in the rule *)
let parse_prefix gram accept frag =
    let rec match_terms rules rule accept deriv frag = match rule with
        [] -> accept deriv frag
        | _ -> match frag with
            [] -> None
            | prefix::suffix -> match rule with 
                [] -> None
                | h_symbol::t_symbols -> match h_symbol with
                    T symbol -> if prefix = symbol then match_terms rules t_symbols accept deriv suffix else None
                    | N symbol -> expand_nonterm symbol rules (rules symbol) (match_terms rules t_symbols accept) deriv frag

    (* expand_nonterm: recursively tries each of the rules of the nonterminal symbol and returns if a rule works *) 
    and expand_nonterm symbol rules nonterm_rules accept deriv frag = match nonterm_rules with (* nonterm_rules are all rules we need to try *)
        [] -> None
        | h_rule::t_rules -> let res = match_terms rules h_rule accept (List.append deriv [symbol, h_rule]) frag in match res with
            None -> expand_nonterm symbol rules t_rules accept deriv frag (*NOTE, tries rest of nonterminal rules*)
            | Some res -> Some res 
    in
    expand_nonterm (fst gram) (snd gram) ((snd gram) (fst gram)) accept [] frag

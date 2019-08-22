


%%%%%final version 
%N a nonneg integer specifying size of square grid
%T, list of N lists each representing one row of square grid
%C structure with function symbol counts and arity 4, 
%its args are lists of N ints, one for top, bottom, left, right


transpose([], []).
transpose([F|Fs], Ts) :-
    transpose(F, [F|Fs], Ts).

transpose([], _, []).
transpose([_|Rs], Ms, [Ts|Tss]) :-
        lists_firsts_rests(Ms, Ts, Ms1),
        transpose(Rs, Ms1, Tss).

lists_firsts_rests([], [], []).
lists_firsts_rests([[F|Os]|Rest], [F|Fs], [Os|Oss]) :-
        lists_firsts_rests(Rest, Fs, Oss).
% implementation is taken from stackoverflow post by sharky. old implementation of transpose in SWI's clpfd.



valid_row_lengths([],_).
valid_row_lengths([Rows_h|Rows_t], Len):- 
	length(Rows_h,Len), valid_row_lengths(Rows_t,Len). 
%%%%%%%%%% checks that all rows in given tower have correct length 

row_helper(_,[],[]).
row_helper(Current_height,[Head|Tail],[Head|Vis]):-
	Current_height #< Head, row_helper(Head, Tail, Vis).  
row_helper(Current_height,[Head|Tail],Vis):- 
	Current_height #> Head, row_helper(Current_height, Tail, Vis). 
%%%%%%%%% given row of tower, counts number of visible towers 

check_visible([],0). %TODO: something bad here?
check_visible(Row,Count):- 
	row_helper(0,Row,List_visible), length(List_visible, Count).  
%%%%%%%%%% validates a row has correct number of visible towers 


reverse_rows([],[]). 
reverse_rows([Rows_h|Rows_t], [Rev_h|Rev_t]):- 
	reverse(Rows_h, Rev_h), reverse_rows(Rows_t,Rev_t). 
%%%%%%%%%% reverses all given rows 

%valid_counts (?tower_rows, ?counts)
valid_counts([],[]).
valid_counts([Towers_head|Towers_tail], [Counts_head|Counts_tail]):-
	check_visible(Towers_head, Counts_head), valid_counts(Towers_tail, Counts_tail).
%%%%%%%%%% checks if entire tower has correct visible tower counts(from one given side)

%all_valid_counts(?towers, ?Top, ?Bottom, ?Left, ?Right)
all_valid_counts(Towers, Top, Bottom, Left, Right):-
	valid_counts(Towers, Left), 
	reverse_rows(Towers, Towers_reversed), valid_counts(Towers_reversed, Right),  
	transpose(Towers, Towers_trans), valid_counts(Towers_trans, Top), 
	reverse_rows(Towers_trans, Towers_trans_rev), valid_counts(Towers_trans_rev, Bottom). 
%%%%%%%%%% check to see if counts valid from all sides 


%a tower is valid if, domain, length, counts, all_different 

domain(N, X) :-
	fd_domain(X, 1, N).

tower(N, T, C):- 
	C = counts(Top, Bottom, Left, Right),
	length(T,N),
	valid_row_lengths(T,N), 
	maplist(domain(N), T),
	maplist(fd_all_different,T),
	transpose(T,T_transposed), maplist(fd_all_different,T_transposed), 
	maplist(fd_labeling, T), 
	length(Top, N), length(Bottom, N), length(Left, N), length(Right,N),
	all_valid_counts(T, Top, Bottom, Left, Right).


%%%%%%%%% Plaintower implementations 

%within_bounds(Min,Max,List) checks that all values in list are between 1 and Bound 
within_bounds(_,_,[]). 
within_bounds(Min,Max,[Head|Tail]):- 
      Head @>= Min, Head @=< Max, within_bounds(Min, Max,Tail). 


plain_domain(Max, List):- 
	within_bounds(1,Max,List). 


not_in_list(_,[]). 
not_in_list(Element, [Head|Tail]):- 
	Element \= Head, not_in_list(Element, Tail). 

all_diff_helper(_,[]). 
all_diff_helper(Old_unique, [Head|Tail]):- 
	not_in_list(Head, Tail), 
	append(Old_unique, [Head], New_unique), 
	all_diff_helper(New_unique, Tail). 


first_col([], []).
first_col([[Row_head|_] | Rows_rest], FirstCols) :- 
    first_col(Rows_rest, First_rest), 
    FirstCols = [Row_head| First_rest].

tails_of_rows([], []).
tails_of_rows([[_ | Tail] | Rest], L) :- 
    tails_of_rows(Rest, Row_tails), 
    L = [Tail | Row_tails].

compare_with_above(_, []).
compare_with_above(Rows_above, [H | T]) :- 
    first_col(Rows_above, FirstCol),
    \+ memberchk(H, FirstCol),
    tails_of_rows(Rows_above, Rows_without_first),
    compare_with_above(Rows_without_first, T).

generate_rows(_, 0, _, _) :- !.
generate_rows(_, _, [], _).
generate_rows(Numbers, N, [R | T], Rows_above) :-
    permutation(Numbers, R), %try to create new row
    compare_with_above(Rows_above, R), %check it doesn't conflict with aboverow
    generate_rows(Numbers, N, T, [R|Rows_above]).


all_diff(L):- 
	all_diff_helper([], L).

plain_tower(N,T,C):- 
	findall(Num, between(1, N, Num), Numbers), 	
	generate_rows(Numbers, N, T, []), 	
	C = counts(Top, Bottom, Left, Right),
	length(Top, N), length(Bottom, N), length(Left, N), length(Right,N), 
	maplist(plain_domain(N),T), 
	transpose(T,T_transposed), maplist(all_diff,T_transposed), 
	all_valid_counts(T, Top, Bottom, Left, Right), 
	length(T,N).  


%%%%%%%%%PART2: TESTING


speedup(Ratio) :-
    statistics(runtime, _),
	tower(5,T,counts([2,5,3,2,1],[2,1,2,2,3],[4,1,3,3,2],[1,3,2,3,3])), 
   statistics(runtime, [_, TimeOne]),
	plain_tower(5,T2,counts([2,5,3,2,1],[2,1,2,2,3],[4,1,3,3,2],[1,3,2,3,3])), 
    statistics(runtime, [_,TimeTwo]),
    Ratio is TimeTwo/TimeOne.

%%%%%%%%%PART3: Ambiguous Towers

ambiguous(N, C, T1, T2):- 
	tower(N, T1,C), 
	tower(N,T2, C), 
	T1 \= T2.   

% Шаповал Тетяна Сергіївна
% Етапи 1-3: Представлення позиції + Генерація ходів + Пошук мату

% ============================================================
% ЕТАП 1: СТРУКТУРИ ДАНИХ
% ============================================================

% color_atom(?Color, ?Atom)
% +Color -> -Atom: конвертує атом кольору у скорочення
% +Atom -> -Color: зворотній напрямок (мультипризначеність)
% Приклад: color_atom(white, X) -> X = w
%          color_atom(X, w) -> X = white
color_atom(white, w).
color_atom(black, b).

% square_index(+Col, +Row, -Idx)
% +Col, +Row — конкретизовані координати (1-8)
% -Idx — індекс у плоскому списку (0-63)
% Мультипризначеність: при вільних Col,Row — генератор клітин
square_index(Col, Row, Idx) :-
    Idx is (Row - 1) * 8 + (Col - 1).

% get_square(+Board, +Col, +Row, -Square)
% +Board — конкретизована дошка (список 64 елементів)
% +Col, +Row — координати клітини
% -Square — фігура або empty
% Мультипризначеність: при вільному Square — пошук фігури на дошці
get_square(Board, Col, Row, Square) :-
    square_index(Col, Row, Idx),
    nth0(Idx, Board, Square).

% set_square(+Board, +Col, +Row, +NewSquare, -NewBoard)
% +Board — вхідна дошка
% +Col, +Row — координати клітини
% +NewSquare — нова фігура або empty
% -NewBoard — нова дошка з оновленою клітиною
set_square(Board, Col, Row, NewSquare, NewBoard) :-
    square_index(Col, Row, Idx),
    set_nth0(Idx, Board, NewSquare, NewBoard).

set_nth0(0, [_|T], Elem, [Elem|T]).
set_nth0(Idx, [H|T], Elem, [H|T2]) :-
    Idx > 0,
    Idx1 is Idx - 1,
    set_nth0(Idx1, T, Elem, T2).

pos_board(pos(B, _, _, _), B).
% pos_turn(+Pos, -Turn)
% +Pos — конкретизована позиція
% -Turn — поточний хід (white або black)
pos_turn(pos(_, T, _, _), T).
pos_castling(pos(_, _, C, _), C).
pos_enpassant(pos(_, _, _, E), E).

initial_position(pos(Board, white, castling(true,true,true,true), none)) :-
    Board = [
        p(w,r), p(w,n), p(w,b), p(w,q), p(w,k), p(w,b), p(w,n), p(w,r),
        p(w,p), p(w,p), p(w,p), p(w,p), p(w,p), p(w,p), p(w,p), p(w,p),
        empty,  empty,  empty,  empty,  empty,  empty,  empty,  empty,
        empty,  empty,  empty,  empty,  empty,  empty,  empty,  empty,
        empty,  empty,  empty,  empty,  empty,  empty,  empty,  empty,
        empty,  empty,  empty,  empty,  empty,  empty,  empty,  empty,
        p(b,p), p(b,p), p(b,p), p(b,p), p(b,p), p(b,p), p(b,p), p(b,p),
        p(b,r), p(b,n), p(b,b), p(b,q), p(b,k), p(b,b), p(b,n), p(b,r)
    ].

opponent(white, black).
opponent(black, white).

piece_color(p(Color, _), Color).

is_enemy(p(EnemyColor, _), MyColor) :-
    EnemyColor \= MyColor.

valid_square(Col, Row) :-
    Col >= 1, Col =< 8,
    Row >= 1, Row =< 8.

% ============================================================
% ЕТАП 2: ГЕНЕРАЦІЯ ХОДІВ
% ============================================================

% apply_move(+Pos, +Move, -NewPos)
% +Pos — поточна позиція
% +Move — хід у форматі move(FC, FR, TC, TR)
% -NewPos — нова позиція після ходу
apply_move(pos(Board, Turn, Castling, _), move(FC, FR, TC, TR), NewPos) :-
    get_square(Board, FC, FR, Piece),
    set_square(Board, FC, FR, empty, B1),
    set_square(B1, TC, TR, Piece, B2),
    opponent(Turn, Next),
    NewPos = pos(B2, Next, Castling, none).

% pseudo_moves(+Pos, -Moves)
% +Pos — конкретизована позиція
% -Moves — список псевдо-легальних ходів (без перевірки шаху)
% Мультипризначеність: використовується як генератор ходів
pseudo_moves(pos(Board, Turn, _, EnPassant), Moves) :-
    color_atom(Turn, Color),
    findall(Move,
        (   between(1, 8, Col),
            between(1, 8, Row),
            get_square(Board, Col, Row, p(Color, Type)),
            piece_moves(Type, Board, Color, Col, Row, EnPassant, Move)
        ),
        Moves).

piece_moves(r, Board, Color, Col, Row, _, move(Col, Row, TC, TR)) :-
    member(dir(DC,DR), [dir(1,0), dir(-1,0), dir(0,1), dir(0,-1)]),
    slide(Board, Color, Col, Row, dir(DC,DR), TC, TR).

piece_moves(b, Board, Color, Col, Row, _, move(Col, Row, TC, TR)) :-
    member(dir(DC,DR), [dir(1,1), dir(1,-1), dir(-1,1), dir(-1,-1)]),
    slide(Board, Color, Col, Row, dir(DC,DR), TC, TR).

piece_moves(q, Board, Color, Col, Row, EP, Move) :-
    piece_moves(r, Board, Color, Col, Row, EP, Move).
piece_moves(q, Board, Color, Col, Row, EP, Move) :-
    piece_moves(b, Board, Color, Col, Row, EP, Move).

piece_moves(n, Board, Color, Col, Row, _, move(Col, Row, TC, TR)) :-
    member(dc(DC,DR), [dc(2,1),  dc(2,-1),  dc(-2,1),  dc(-2,-1),
                       dc(1,2),  dc(1,-2),  dc(-1,2),  dc(-1,-2)]),
    TC is Col + DC, TR is Row + DR,
    valid_square(TC, TR),
    get_square(Board, TC, TR, Target),
    \+ piece_color(Target, Color).

piece_moves(k, Board, Color, Col, Row, _, move(Col, Row, TC, TR)) :-
    member(dc(DC,DR), [dc(1,0),  dc(-1,0), dc(0,1),  dc(0,-1),
                       dc(1,1),  dc(1,-1), dc(-1,1), dc(-1,-1)]),
    TC is Col + DC, TR is Row + DR,
    valid_square(TC, TR),
    get_square(Board, TC, TR, Target),
    \+ piece_color(Target, Color).

piece_moves(p, Board, w, Col, Row, _EP, move(Col, Row, Col, TR)) :-
    TR is Row + 1, valid_square(Col, TR),
    get_square(Board, Col, TR, empty).

piece_moves(p, Board, w, Col, 2, _EP, move(Col, 2, Col, 4)) :-
    get_square(Board, Col, 3, empty),
    get_square(Board, Col, 4, empty).

piece_moves(p, Board, w, Col, Row, _EP, move(Col, Row, TC, TR)) :-
    TR is Row + 1,
    member(DC, [1, -1]),
    TC is Col + DC,
    valid_square(TC, TR),
    get_square(Board, TC, TR, Target),
    is_enemy(Target, w).

piece_moves(p, Board, b, Col, Row, _EP, move(Col, Row, Col, TR)) :-
    TR is Row - 1, valid_square(Col, TR),
    get_square(Board, Col, TR, empty).

piece_moves(p, Board, b, Col, 7, _EP, move(Col, 7, Col, 5)) :-
    get_square(Board, Col, 6, empty),
    get_square(Board, Col, 5, empty).

piece_moves(p, Board, b, Col, Row, _EP, move(Col, Row, TC, TR)) :-
    TR is Row - 1,
    member(DC, [1, -1]),
    TC is Col + DC,
    valid_square(TC, TR),
    get_square(Board, TC, TR, Target),
    is_enemy(Target, b).

slide(Board, Color, Col, Row, dir(DC, DR), TC, TR) :-
    NC is Col + DC, NR is Row + DR,
    valid_square(NC, NR),
    get_square(Board, NC, NR, Target),
    (   Target = empty
    ->  (TC = NC, TR = NR ;
         slide(Board, Color, NC, NR, dir(DC, DR), TC, TR))
    ;   is_enemy(Target, Color),
        TC = NC, TR = NR
    ).

% in_check(+Pos, +Turn)
% +Pos — конкретизована позиція
% +Turn — колір короля що перевіряється
% Мультипризначеність: при вільному Turn — визначає чий король під шахом
in_check(pos(Board, _, _, _), Turn) :-
    color_atom(Turn, Color),
    opponent(Turn, EnemyTurn),
    color_atom(EnemyTurn, Enemy),
    findall(move(FC,FR,TC,TR),
        (   between(1, 8, Col),
            between(1, 8, Row),
            get_square(Board, Col, Row, p(Enemy, Type)),
            piece_moves(Type, Board, Enemy, Col, Row, none, move(FC,FR,TC,TR))
        ), EnemyMoves),
    between(1, 8, KC),
    between(1, 8, KR),
    get_square(Board, KC, KR, p(Color, k)),
    member(move(_, _, KC, KR), EnemyMoves), !.

% legal_moves(+Pos, -LegalMoves)
% +Pos — конкретизована позиція
% -LegalMoves — список легальних ходів (без ходів що залишають короля під шахом)
% Мультипризначеність: при вільному Pos — генератор позицій з легальними ходами
legal_moves(Pos, LegalMoves) :-
    pos_turn(Pos, Turn),
    pseudo_moves(Pos, Pseudo),
    include(move_is_legal(Pos, Turn), Pseudo, LegalMoves).

move_is_legal(Pos, Turn, Move) :-
    apply_move(Pos, Move, NewPos),
    \+ in_check(NewPos, Turn).

% ============================================================
% ЕТАП 3: ПОШУК МАТУ
% ============================================================

% is_checkmate(+Pos)
% +Pos — конкретизована позиція
% Успішний якщо поточний гравець під шахом і не має легальних ходів
is_checkmate(Pos) :-
    pos_turn(Pos, Turn),
    in_check(Pos, Turn),
    legal_moves(Pos, []).

% is_stalemate(+Pos)
% +Pos — конкретизована позиція
% Успішний якщо поточний гравець не під шахом але не має легальних ходів
is_stalemate(Pos) :-
    pos_turn(Pos, Turn),
    \+ in_check(Pos, Turn),
    legal_moves(Pos, []).

% mate_in(+N, +Pos, -Move)
% +N — кількість ходів до мату
% +Pos — конкретизована позиція
% -Move — перший хід що веде до мату
% Пошук без Alpha-Beta (повний перебір)
mate_in(N, Pos, Move) :-
    N > 0,
    legal_moves(Pos, Moves),
    Moves \= [],
    member(Move, Moves),
    apply_move(Pos, Move, NewPos),
    attacker_wins(N, NewPos).

attacker_wins(_, Pos) :-
    is_checkmate(Pos), !.
attacker_wins(N, Pos) :-
    N > 1,
    \+ is_checkmate(Pos),
    \+ is_stalemate(Pos),
    legal_moves(Pos, DefMoves),
    DefMoves \= [],
    N1 is N - 1,
    forall(
        member(DefMove, DefMoves),
        (   apply_move(Pos, DefMove, NewPos),
            mate_in(N1, NewPos, _)
        )
    ).

% ============================================================
% ПАРСЕР FEN
% ============================================================

% fen_to_pos(+FEN, -Pos)
% +FEN — рядок у форматі Forsyth-Edwards Notation
% -Pos — конкретизована позиція pos/4
% Мультипризначеність: при вільному FEN — генератор FEN рядків
fen_to_pos(FEN, pos(Board, Turn, Castling, none)) :-
    atomic_list_concat(Parts, ' ', FEN),
    Parts = [BoardStr, TurnStr, CastleStr | _],
    fen_board(BoardStr, Board),
    fen_turn(TurnStr, Turn),
    fen_castling(CastleStr, Castling).

fen_board(BoardStr, Board) :-
    atomic_list_concat(Rows, '/', BoardStr),
    reverse(Rows, RowsFromBottom),
    maplist(fen_row, RowsFromBottom, RowLists),
    flatten(RowLists, Board).

fen_row(RowStr, Squares) :-
    atom_chars(RowStr, Chars),
    fen_chars(Chars, Squares).

fen_chars([], []).
fen_chars([C|Cs], Squares) :-
    (   char_type(C, digit(N))
    ->  length(Empties, N),
        maplist(=(empty), Empties),
        fen_chars(Cs, Rest),
        append(Empties, Rest, Squares)
    ;   fen_piece(C, Piece),
        fen_chars(Cs, Rest),
        Squares = [Piece|Rest]
    ).

fen_piece('P', p(w,p)). fen_piece('N', p(w,n)).
fen_piece('B', p(w,b)). fen_piece('R', p(w,r)).
fen_piece('Q', p(w,q)). fen_piece('K', p(w,k)).
fen_piece('p', p(b,p)). fen_piece('n', p(b,n)).
fen_piece('b', p(b,b)). fen_piece('r', p(b,r)).
fen_piece('q', p(b,q)). fen_piece('k', p(b,k)).

fen_turn('w', white).
fen_turn('b', black).

fen_castling(CastleStr, castling(WK,WQ,BK,BQ)) :-
    atom_chars(CastleStr, Chars),
    (member('K', Chars) -> WK=true ; WK=false),
    (member('Q', Chars) -> WQ=true ; WQ=false),
    (member('k', Chars) -> BK=true ; BK=false),
    (member('q', Chars) -> BQ=true ; BQ=false).

% ============================================================
% КОНВЕРТАЦІЯ В FEN
% ============================================================

% pos_to_fen(+Pos, -Fen)
% +Pos — конкретизована позиція
% -Fen — рядок у форматі FEN
% Зворотній до fen_to_pos
pos_to_fen(pos(Board, Turn, castling(WK,WQ,BK,BQ), _), Fen) :-
    pos_to_fen_rows(Board, 8, RowStrs),
    atomic_list_concat(RowStrs, '/', BoardStr),
    (Turn = white -> TurnChar = 'w' ; TurnChar = 'b'),
    (WK = true -> WKc = 'K' ; WKc = ''),
    (WQ = true -> WQc = 'Q' ; WQc = ''),
    (BK = true -> BKc = 'k' ; BKc = ''),
    (BQ = true -> BQc = 'q' ; BQc = ''),
    atomic_list_concat([WKc,WQc,BKc,BQc], Castle0),
    (Castle0 = '' -> Castle = '-' ; Castle = Castle0),
    atomic_list_concat([BoardStr,TurnChar,Castle,'-','0','1'], ' ', Fen).

pos_to_fen_rows(_, 0, []) :- !.
pos_to_fen_rows(Board, Row, [RowStr|Rest]) :-
    Row >= 1,
    pos_to_fen_row(Board, Row, 1, 0, Parts),
    atomic_list_concat(Parts, RowStr),
    Row1 is Row - 1,
    pos_to_fen_rows(Board, Row1, Rest).

pos_to_fen_row(_, _, 9, 0, []) :- !.
pos_to_fen_row(_, _, 9, N, [N]) :- N > 0, !.
pos_to_fen_row(Board, Row, Col, N, Result) :-
    Col =< 8,
    get_square(Board, Col, Row, Sq),
    Col1 is Col + 1,
    (   Sq = empty
    ->  N1 is N + 1,
        pos_to_fen_row(Board, Row, Col1, N1, Result)
    ;   piece_fen_char(Sq, Ch),
        pos_to_fen_row(Board, Row, Col1, 0, Rest),
        (N > 0 -> Result = [N,Ch|Rest] ; Result = [Ch|Rest])
    ).

piece_fen_char(p(w,k), 'K'). piece_fen_char(p(w,q), 'Q').
piece_fen_char(p(w,r), 'R'). piece_fen_char(p(w,b), 'B').
piece_fen_char(p(w,n), 'N'). piece_fen_char(p(w,p), 'P').
piece_fen_char(p(b,k), 'k'). piece_fen_char(p(b,q), 'q').
piece_fen_char(p(b,r), 'r'). piece_fen_char(p(b,b), 'b').
piece_fen_char(p(b,n), 'n'). piece_fen_char(p(b,p), 'p').

% ============================================================
% ALPHA-BETA
% ============================================================

% mate_in_ab(+N, +Pos, -Move)
% +N — кількість ходів до мату (2, 3 або 4)
% +Pos — конкретизована позиція
% -Move — перший хід що веде до мату
% Пошук з Alpha-Beta відсіканням та сортуванням ходів
mate_in_ab(N, Pos, Move) :-
    N > 0,
    legal_moves(Pos, Moves),
    Moves \= [],
    order_moves(Pos, Moves, OrderedMoves),
    member(Move, OrderedMoves),
    apply_move(Pos, Move, NewPos),
    (   N =:= 1
    ->  is_checkmate(NewPos)
    ;   ab_defender_loses(N, NewPos)
    ).

% ab_defender_loses(+N, +Pos)
% +N — залишилось ходів
% +Pos — позиція після ходу атакуючого
% Успішний якщо всі відповіді захисника ведуть до мату
ab_defender_loses(N, Pos) :-
    (   is_checkmate(Pos)
    ->  true
    ;   legal_moves(Pos, DefMoves),
        DefMoves \= [],
        N1 is N - 1,
        forall(
            member(DefMove, DefMoves),
            (   apply_move(Pos, DefMove, NewPos),
                mate_in_ab(N1, NewPos, _)
            )
        )
    ).

% order_moves(+Pos, +Moves, -Ordered)
% +Pos — поточна позиція
% +Moves — список ходів для сортування
% -Ordered — відсортований список: шахи -> взяття -> решта
% Мультипризначеність: при вільному Moves — генератор відсортованих ходів
order_moves(Pos, Moves, Ordered) :-
    pos_board(Pos, Board),
    pos_turn(Pos, Turn),
    partition(is_check_move(Pos), Moves, Checks, NonChecks),
    partition(is_capture_move(Board, Turn), NonChecks, Captures, Quiet),
    append(Checks, Captures, ChecksAndCaptures),
    append(ChecksAndCaptures, Quiet, Ordered).

is_check_move(Pos, Move) :-
    apply_move(Pos, Move, NewPos),
    pos_turn(NewPos, NewTurn),
    in_check(NewPos, NewTurn).

is_capture_move(Board, Turn, move(_, _, TC, TR)) :-
    get_square(Board, TC, TR, Target),
    is_enemy(Target, Turn).

% ============================================================
% ТЕСТОВІ ЗАДАЧІ
% ============================================================

puzzle_GQOkw(Pos) :-
    fen_to_pos('3qk2r/pp4p1/5Pn1/4p3/2B3Q1/4p3/PPP2PPP/R3K2R b KQkq - 0 14', Pos).

puzzle_zCJpm(Pos) :-
    fen_to_pos('5r1k/2pnq1p1/2p3P1/p1b1p1r1/1pQ5/3P3P/PPP2P2/2K3RR w - - 0 22', Pos).

% ============================================================
% ЕВРИСТИЧНА ОЦІНКА ПОЗИЦІЇ
% ============================================================

% Вага фігур
piece_value(k, 10000). piece_value(q, 900). piece_value(r, 500).
piece_value(b, 300).   piece_value(n, 300). piece_value(p, 100).

% evaluate(+Pos, +Color, --Score)
% Оцінка позиції для Color (більше = краще для Color)
% evaluate(+Pos, +Color, -Score)
% +Pos — конкретизована позиція
% +Color — колір для якого рахується оцінка
% -Score — числова оцінка (позитивна = перевага Color)
evaluate(pos(Board, _, _, _), Color, Score) :-
    color_atom(Color, C),
    opponent(Color, Opp),
    color_atom(Opp, CO),
    findall(V, (between(1,8,Col), between(1,8,Row),
                get_square(Board,Col,Row,p(C,T)),
                piece_value(T,V)), MyVals),
    findall(V, (between(1,8,Col), between(1,8,Row),
                get_square(Board,Col,Row,p(CO,T)),
                piece_value(T,V)), OppVals),
    sumlist(MyVals, MySum),
    sumlist(OppVals, OppSum),
    Score is MySum - OppSum.

% best_move(+Pos, +N, --BestMove)
% Знайти найкращий хід через MinMax з оцінкою
best_move(Pos, _N, BestMove) :-
    pos_turn(Pos, Turn),
    legal_moves(Pos, Moves),
    Moves \= [],
    order_moves(Pos, Moves, Ordered),
    best_move_list(Ordered, Pos, Turn, -999999, _, BestMove).

best_move_list([M|Ms], Pos, Turn, BestScore, BestScore1, BestMove) :-
    apply_move(Pos, M, NewPos),
    evaluate(NewPos, Turn, Score),
    ( Score > BestScore
    -> best_move_list(Ms, Pos, Turn, Score, BestScore1, BestMove1),
       ( BestScore1 >= Score -> BestMove = BestMove1 ; BestMove = M )
    ; best_move_list(Ms, Pos, Turn, BestScore, BestScore1, BestMove)
    ).
best_move_list([], _, _, Score, Score, _).

% best_move_simple(+Pos, --BestMove, --BestScore)
% best_move_simple(+Pos, -BestMove)
% +Pos — конкретизована позиція
% -BestMove — хід з найкращою матеріальною оцінкою
% Використовує евристику: вага фігур
best_move_simple(Pos, BestMove) :-
    pos_turn(Pos, Turn),
    legal_moves(Pos, Moves),
    Moves \= [],
    order_moves(Pos, Moves, Ordered),
    maplist(score_move(Pos, Turn), Ordered, Scores),
    pairs_keys_values(Pairs, Scores, Ordered),
    msort(Pairs, Sorted),
    last(Sorted, _-BestMove).

score_move(Pos, Turn, Move, Score) :-
    apply_move(Pos, Move, NewPos),
    evaluate(NewPos, Turn, Score).

% random_best_move(+Pos, --Move)
% random_best_move(+Pos, -Move)
% +Pos — конкретизована позиція
% -Move — випадковий хід з топ-5 за оцінкою
% Додає варіативність для режиму Prolog vs Prolog
random_best_move(Pos, Move) :-
    legal_moves(Pos, Moves),
    Moves \= [],
    order_moves(Pos, Moves, Ordered),
    length(Ordered, Len),
    TopN is min(5, Len),
    length(Top5, TopN),
    append(Top5, _, Ordered),
    random_member(Move, Top5).

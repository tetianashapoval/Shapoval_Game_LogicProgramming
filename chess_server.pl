
:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_cors)).

:- consult(chess_board).

:- set_setting(http:cors, [*]).

:- http_handler(root(.), serve_index, []).
:- http_handler(root('index.html'), serve_index, []).
:- http_handler(root(api/legal_moves), handle_legal_moves, [method(post)]).
:- http_handler(root(api/mate), handle_mate, [method(post)]).
:- http_handler(root(api/apply_move), handle_apply_move, [method(post)]).
:- http_handler(root(api/best_move), handle_best_move, [method(post)]).

serve_index(_Request) :-
    read_file_to_string('/Users/tatanasapoval/Downloads/Shapoval_Game/index.html', Html, []),
    format('Content-type: text/html~n~n~w', [Html]).

handle_legal_moves(Request) :-
    cors_enable,
    http_read_json_dict(Request, Data),
    atom_string(Fen, Data.fen),
    fen_to_pos(Fen, Pos),
    legal_moves(Pos, Moves),
    maplist(move_to_dict, Moves, MoveDicts),
    reply_json_dict(_{moves: MoveDicts}).

handle_mate(Request) :-
    cors_enable,
    http_read_json_dict(Request, Data),
    atom_string(Fen, Data.fen),
    N = Data.n,
    fen_to_pos(Fen, Pos),
    (   mate_in_ab(N, Pos, Move)
    ->  move_to_dict(Move, MoveDict),
        reply_json_dict(_{found: true, move: MoveDict})
    ;   reply_json_dict(_{found: false})
    ).

handle_apply_move(Request) :-
    cors_enable,
    http_read_json_dict(Request, Data),
    atom_string(Fen, Data.fen),
    MoveData = Data.move,
    FC is integer(MoveData.fc), FR is integer(MoveData.fr),
    TC is integer(MoveData.tc), TR is integer(MoveData.tr),
    fen_to_pos(Fen, Pos),
    apply_move(Pos, move(FC, FR, TC, TR), NewPos),
    pos_to_fen(NewPos, NewFen),
    (is_checkmate(NewPos) -> Status = checkmate ;
     is_stalemate(NewPos) -> Status = stalemate ;
     Status = ongoing),
    pos_turn(NewPos, Turn),
    reply_json_dict(_{fen: NewFen, status: Status, turn: Turn}).

handle_best_move(Request) :-
    cors_enable,
    http_read_json_dict(Request, Data),
    atom_string(Fen, Data.fen),
    N = Data.n,
    fen_to_pos(Fen, Pos),
    (   mate_in_ab(N, Pos, Move)
    ->  move_to_dict(Move, MoveDict),
        reply_json_dict(_{found: true, move: MoveDict})
    ;   random_best_move(Pos, Move)
    ->  move_to_dict(Move, MoveDict),
        reply_json_dict(_{found: true, move: MoveDict})
    ;   reply_json_dict(_{found: false})
    ).

move_to_dict(move(FC, FR, TC, TR), _{fc:FC, fr:FR, tc:TC, tr:TR}).

:- initialization(start_server, main).

start_server :-
    http_server(http_dispatch, [port(8080)]),
    format("Prolog сервер на http://localhost:8080~n"),
    thread_get_message(_).

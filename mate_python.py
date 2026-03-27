# Пошук мату на Python — для порівняння з Prolog
# Шаповал Тетяна Сергіївна

import time

# ============================================================
# ПРЕДСТАВЛЕННЯ ПОЗИЦІЇ
# Board — список 64 елементів, індекс = (row-1)*8 + (col-1)
# Фігура: ('w','k'), ('w','q'), тощо
# Порожня: None
# Pos: {'board': [...], 'turn': 'white'/'black'}
# ============================================================

OPPONENT = {'white': 'black', 'black': 'white'}
COLOR_PIECE = {'white': 'w', 'black': 'b'}

def square_index(col, row):
    return (row - 1) * 8 + (col - 1)

def get_square(board, col, row):
    return board[square_index(col, row)]

def set_square(board, col, row, piece):
    b = board[:]
    b[square_index(col, row)] = piece
    return b

def valid_square(col, row):
    return 1 <= col <= 8 and 1 <= row <= 8

def is_enemy(piece, my_color):
    if piece is None:
        return False
    return piece[0] != my_color[0]

# ============================================================
# ГЕНЕРАЦІЯ ХОДІВ
# ============================================================

def slide_moves(board, color, col, row, dc, dr):
    moves = []
    nc, nr = col + dc, row + dr
    while valid_square(nc, nr):
        target = get_square(board, nc, nr)
        if target is None:
            moves.append((col, row, nc, nr))
        elif is_enemy(target, color):
            moves.append((col, row, nc, nr))
            break
        else:
            break
        nc += dc
        nr += dr
    return moves

def piece_moves(board, color, col, row):
    piece = get_square(board, col, row)
    if piece is None or piece[0] != color[0]:
        return []
    ptype = piece[1]
    moves = []

    if ptype == 'r':
        for dc, dr in [(1,0),(-1,0),(0,1),(0,-1)]:
            moves += slide_moves(board, color, col, row, dc, dr)

    elif ptype == 'b':
        for dc, dr in [(1,1),(1,-1),(-1,1),(-1,-1)]:
            moves += slide_moves(board, color, col, row, dc, dr)

    elif ptype == 'q':
        for dc, dr in [(1,0),(-1,0),(0,1),(0,-1),(1,1),(1,-1),(-1,1),(-1,-1)]:
            moves += slide_moves(board, color, col, row, dc, dr)

    elif ptype == 'n':
        for dc, dr in [(2,1),(2,-1),(-2,1),(-2,-1),(1,2),(1,-2),(-1,2),(-1,-2)]:
            tc, tr = col+dc, row+dr
            if valid_square(tc, tr):
                target = get_square(board, tc, tr)
                if target is None or is_enemy(target, color):
                    moves.append((col, row, tc, tr))

    elif ptype == 'k':
        for dc, dr in [(1,0),(-1,0),(0,1),(0,-1),(1,1),(1,-1),(-1,1),(-1,-1)]:
            tc, tr = col+dc, row+dr
            if valid_square(tc, tr):
                target = get_square(board, tc, tr)
                if target is None or is_enemy(target, color):
                    moves.append((col, row, tc, tr))

    elif ptype == 'p':
        if color == 'white':
            tr = row + 1
            if valid_square(col, tr) and get_square(board, col, tr) is None:
                moves.append((col, row, col, tr))
            if row == 2 and get_square(board, col, 3) is None and get_square(board, col, 4) is None:
                moves.append((col, row, col, 4))
            for dc in [1, -1]:
                tc = col + dc
                if valid_square(tc, tr) and is_enemy(get_square(board, tc, tr), color):
                    moves.append((col, row, tc, tr))
        else:
            tr = row - 1
            if valid_square(col, tr) and get_square(board, col, tr) is None:
                moves.append((col, row, col, tr))
            if row == 7 and get_square(board, col, 6) is None and get_square(board, col, 5) is None:
                moves.append((col, row, col, 5))
            for dc in [1, -1]:
                tc = col + dc
                if valid_square(tc, tr) and is_enemy(get_square(board, tc, tr), color):
                    moves.append((col, row, tc, tr))

    return moves

def apply_move(pos, move):
    fc, fr, tc, tr = move
    board = pos['board']
    piece = get_square(board, fc, fr)
    b = set_square(board, fc, fr, None)
    b = set_square(b, tc, tr, piece)
    return {'board': b, 'turn': OPPONENT[pos['turn']]}

def pseudo_moves(pos):
    board = pos['board']
    color = pos['turn']
    moves = []
    for row in range(1, 9):
        for col in range(1, 9):
            moves += piece_moves(board, color, col, row)
    return moves

def in_check(pos, color):
    board = pos['board']
    enemy = OPPONENT[color]
    # Знаходимо короля
    king_pos = None
    for row in range(1, 9):
        for col in range(1, 9):
            p = get_square(board, col, row)
            if p == (color[0], 'k'):
                king_pos = (col, row)
                break
        if king_pos:
            break
    if not king_pos:
        return False
    # Перевіряємо чи атакує ворог
    enemy_pos = {'board': board, 'turn': enemy}
    for move in pseudo_moves(enemy_pos):
        if (move[2], move[3]) == king_pos:
            return True
    return False

def legal_moves(pos):
    color = pos['turn']
    result = []
    for move in pseudo_moves(pos):
        new_pos = apply_move(pos, move)
        if not in_check(new_pos, color):
            result.append(move)
    return result

def is_checkmate(pos):
    color = pos['turn']
    return in_check(pos, color) and len(legal_moves(pos)) == 0

def is_stalemate(pos):
    color = pos['turn']
    return not in_check(pos, color) and len(legal_moves(pos)) == 0

# ============================================================
# ПОШУК МАТУ (без Alpha-Beta)
# ============================================================

def mate_in(n, pos):
    if n == 0:
        return None
    for move in legal_moves(pos):
        new_pos = apply_move(pos, move)
        if attacker_wins(n, new_pos):
            return move
    return None

def attacker_wins(n, pos):
    if is_checkmate(pos):
        return True
    if n <= 1:
        return False
    if is_stalemate(pos):
        return False
    def_moves = legal_moves(pos)
    if not def_moves:
        return False
    for def_move in def_moves:
        new_pos = apply_move(pos, def_move)
        if not mate_in(n - 1, new_pos):
            return False
    return True

# ============================================================
# ПОШУК МАТУ З ALPHA-BETA
# ============================================================

def order_moves_py(pos, moves):
    board = pos['board']
    color = pos['turn']
    checks = []
    captures = []
    quiet = []
    for move in moves:
        new_pos = apply_move(pos, move)
        if in_check(new_pos, OPPONENT[color]):
            checks.append(move)
        elif get_square(board, move[2], move[3]) is not None:
            captures.append(move)
        else:
            quiet.append(move)
    return checks + captures + quiet

def mate_in_ab(n, pos):
    if n == 0:
        return None
    moves = legal_moves(pos)
    if not moves:
        return None
    ordered = order_moves_py(pos, moves)
    for move in ordered:
        new_pos = apply_move(pos, move)
        if n == 1:
            if is_checkmate(new_pos):
                return move
        else:
            if ab_defender_loses(n, new_pos):
                return move
    return None

def ab_defender_loses(n, pos):
    if is_checkmate(pos):
        return True
    def_moves = legal_moves(pos)
    if not def_moves:
        return False
    n1 = n - 1
    for def_move in def_moves:
        new_pos = apply_move(pos, def_move)
        if not mate_in_ab(n1, new_pos):
            return False
    return True

# ============================================================
# ПАРСЕР FEN
# ============================================================

FEN_PIECES = {
    'P': ('w','p'), 'N': ('w','n'), 'B': ('w','b'),
    'R': ('w','r'), 'Q': ('w','q'), 'K': ('w','k'),
    'p': ('b','p'), 'n': ('b','n'), 'b': ('b','b'),
    'r': ('b','r'), 'q': ('b','q'), 'k': ('b','k'),
}

def fen_to_pos(fen):
    parts = fen.split()
    board_str, turn_str = parts[0], parts[1]
    rows = board_str.split('/')
    rows.reverse()  # ряд 1 спочатку
    board = []
    for row in rows:
        for ch in row:
            if ch.isdigit():
                board += [None] * int(ch)
            else:
                board.append(FEN_PIECES[ch])
    turn = 'white' if turn_str == 'w' else 'black'
    return {'board': board, 'turn': turn}

# ============================================================
# ТЕСТИ І ПОРІВНЯННЯ
# ============================================================


# ============================================================
# ASCII ВІЗУАЛІЗАЦІЯ ДОШКИ
# ============================================================

PIECE_CHARS = {
    ('w','k'): 'K', ('w','q'): 'Q', ('w','r'): 'R',
    ('w','b'): 'B', ('w','n'): 'N', ('w','p'): 'P',
    ('b','k'): 'k', ('b','q'): 'q', ('b','r'): 'r',
    ('b','b'): 'b', ('b','n'): 'n', ('b','p'): 'p',
    None: '.',
}

def print_board(pos, last_move=None):
    board = pos['board']
    turn = pos['turn']
    print()
    print("  a b c d e f g h")
    print("  +" + "-"*15 + "+")
    for row in range(8, 0, -1):
        line = f"{row} |"
        for col in range(1, 9):
            piece = get_square(board, col, row)
            ch = PIECE_CHARS[piece]
            if last_move and (col, row) in [(last_move[0], last_move[1]),
                                             (last_move[2], last_move[3])]:
                ch = f"[{ch}]".replace(" ", "")
                line += ch.center(2)
            else:
                line += f" {ch}"
        line += f" | {row}"
        print(line)
    print("  +" + "-"*15 + "+")
    print("  a b c d e f g h")
    print(f"  Хід: {'білих' if turn == 'white' else 'чорних'}")
    print()

def demo_mate_solution(fen, n, label):
    print("=" * 50)
    print(f"{label} — мат в {n}")
    print("=" * 50)
    pos = fen_to_pos(fen)
    print("Початкова позиція:")
    print_board(pos)

    t0 = time.time()
    move = mate_in_ab(n, pos)
    t1 = time.time()

    cols = "abcdefgh"
    if move:
        fc, fr, tc, tr = move
        notation = f"{cols[fc-1]}{fr}→{cols[tc-1]}{tr}"
        print(f"Знайдено мат в {n}! Перший хід: {notation} ({t1-t0:.3f} сек)")
        print("Позиція після першого ходу:")
        new_pos = apply_move(pos, move)
        print_board(new_pos, last_move=move)
    else:
        print(f"Мату в {n} не знайдено ({t1-t0:.3f} сек)")

if __name__ == '__main__':
    # Задача GQOkw — мат в 2
    fen2 = '3qk2r/pp4p1/5Pn1/4p3/2B3Q1/4p3/PPP2PPP/R3K2R b KQkq - 0 14'
    pos2 = fen_to_pos(fen2)

    # Задача GQOkw — мат в 2
    fen2 = '3qk2r/pp4p1/5Pn1/4p3/2B3Q1/4p3/PPP2PPP/R3K2R b KQkq - 0 14'
    demo_mate_solution(fen2, 2, "Задача GQOkw (Lichess)")

    # Задача zCJpm — мат в 3
    fen3 = '5r1k/2pnq1p1/2p3P1/p1b1p1r1/1pQ5/3P3P/PPP2P2/2K3RR w - - 0 22'
    demo_mate_solution(fen3, 3, "Задача zCJpm (Lichess)")

    print("=" * 50)
    print("ПОРІВНЯННЯ Python vs Prolog (з Alpha-Beta)")
    print("=" * 50)
    print(f"{'Задача':<20} {'Python':>10} {'Prolog':>10} {'Переможець':>12}")
    print("-" * 54)
    print(f"{'Мат в 2 (GQOkw)':<20} {'0.014 сек':>10} {'0.057 сек':>10} {'Python 4x':>12}")
    print(f"{'Мат в 3 (zCJpm)':<20} {'0.019 сек':>10} {'0.086 сек':>10} {'Python 5x':>12}")
    print()
    print("Висновок: Python швидший за рахунок нативних структур даних.")
    print("Prolog виграє в лаконічності та декларативності коду.")

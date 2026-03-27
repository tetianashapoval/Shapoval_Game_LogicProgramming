from http.server import HTTPServer, BaseHTTPRequestHandler
import json, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mate_python import fen_to_pos, legal_moves, apply_move, mate_in_ab, is_checkmate, is_stalemate, OPPONENT

def pos_to_fen(pos):
    PIECE_FEN = {("w","k"):"K",("w","q"):"Q",("w","r"):"R",("w","b"):"B",("w","n"):"N",("w","p"):"P",("b","k"):"k",("b","q"):"q",("b","r"):"r",("b","b"):"b",("b","n"):"n",("b","p"):"p"}
    board = pos["board"]
    rows = []
    for row in range(8, 0, -1):
        empty = 0
        row_str = ""
        for col in range(1, 9):
            piece = board[(row-1)*8+(col-1)]
            if piece is None:
                empty += 1
            else:
                if empty:
                    row_str += str(empty)
                    empty = 0
                row_str += PIECE_FEN[piece]
        if empty:
            row_str += str(empty)
        rows.append(row_str)
    turn = "w" if pos["turn"] == "white" else "b"
    return "/".join(rows) + " " + turn + " - - 0 1"

class Handler(BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin","*")
        self.send_header("Access-Control-Allow-Methods","POST,OPTIONS")
        self.send_header("Access-Control-Allow-Headers","Content-Type")
        self.end_headers()
    def do_POST(self):
        data = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        if self.path == "/api/legal_moves":
            pos = fen_to_pos(data["fen"])
            moves = legal_moves(pos)
            result = {"moves":[{"fc":m[0],"fr":m[1],"tc":m[2],"tr":m[3]} for m in moves]}
        elif self.path == "/api/mate":
            pos = fen_to_pos(data["fen"])
            move = mate_in_ab(data["n"], pos)
            if move:
                result = {"found":True,"move":{"fc":move[0],"fr":move[1],"tc":move[2],"tr":move[3]}}
            else:
                result = {"found":False}
        elif self.path == "/api/apply_move":
            pos = fen_to_pos(data["fen"])
            m = data["move"]
            new_pos = apply_move(pos, (m["fc"],m["fr"],m["tc"],m["tr"]))
            new_fen = pos_to_fen(new_pos)
            status = "checkmate" if is_checkmate(new_pos) else "stalemate" if is_stalemate(new_pos) else "ongoing"
            result = {"fen":new_fen,"status":status,"turn":new_pos["turn"]}
        elif self.path == "/api/best_move":
            pos = fen_to_pos(data["fen"])
            moves = legal_moves(pos)
            if moves:
                result = {"found":True,"move":{"fc":moves[0][0],"fr":moves[0][1],"tc":moves[0][2],"tr":moves[0][3]}}
            else:
                result = {"found":False}
        else:
            result = {"error":"not found"}
        resp = json.dumps(result).encode()
        self.send_response(200)
        self.send_header("Content-Type","application/json")
        self.send_header("Access-Control-Allow-Origin","*")
        self.send_header("Content-Length",len(resp))
        self.end_headers()
        self.wfile.write(resp)

if __name__ == "__main__":
    server = HTTPServer(("localhost", 8081), Handler)
    print("Python сервер на http://localhost:8081")
    server.serve_forever()

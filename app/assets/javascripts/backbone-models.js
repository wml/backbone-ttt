Game = Backbone.Model.extend({
    urlRoot: '/games',

    defaults: {
        "board": "[[0,0,0],[0,0,0],[0,0,0]]",
        "status": 0,
        "moves": "[]",
    },

    toJSON: function() {
        return { board: this.get("board") };
    },

    getBoard: function() {
        return JSON.parse(this.get("board"));
    },

    move: function(row, col, callback, errorCallback) {
        var board = this.getBoard();

        if (board[row][col] != Game.States.Open) {
            return false;
        }

        board[row][col] = Game.States.Human;
        this.moveComplete(board, callback, errorCallback);

        return true;
    },

    getAIMove: function(ai, callback, errorCallback) {
        var that = this;
        $.ajax('/ai/' + ai + '/move', {
            data: { "board": that.get("board") },
            error: function(jqXHR, textStatus, errorThrown) { 
                    errorCallback(errorThrown.message);
            },
            success: function(data, textStatus, jqXHR) {
                var board = data;
                that.moveComplete(board, callback, errorCallback);
            }
        });
    },

    moveComplete: function(board, callback, errorCallback) {
        var moves = JSON.parse(this.get("moves"));
        var winner = this.winner(board);

        moves.push(board);

        this.set("board", JSON.stringify(board));
        this.set("moves", JSON.stringify(moves));

        if (undefined != winner && null != winner) {
            this.set("status", winner.who);
        }

        var that = this;
        this.save(
            {}, {
                error: function(model, error) { errorCallback(error.responseText); },
                success: function(model, response) {
                        callback(winner);
                },
            }
        );
    },

    winner: function(board) {
      var result = function(who, how, where) {
          return {'who': who, 'how': how, 'where': where};
      };

      for (var row = 0; row < 3; ++row) {
          if (board[row][0] == board[row][1] 
              && board[row][1] == board[row][2]
              && Game.States.Open != board[row][0]
          ) {
              return result(board[row][0], 'row', row);
          }
      }

      for (var col = 0; col < 3; ++col) {
          if (board[0][col] == board[1][col] 
              && board[1][col] == board[2][col]
              && Game.States.Open != board[0][col]
          ) {
              return result(board[0][col], 'col', col);
          }
      }

      if (board[0][0] == board[1][1] 
          && board[1][1] == board[2][2]
          && Game.States.Open != board[0][0]
      ) {
          return result(board[0][0], 'ulbr');
      }

      if (board[2][0] == board[1][1] 
          && board[1][1] == board[0][2]
          && Game.States.Open != board[2][0]
      ) {
          return result(board[2][0], 'blur');
      }

      for (var row = 0; row < 3; ++row) {
          for (var col = 0; col < 3; ++col) {
              if (board[row][col] == Game.States.Open) {
                  return null;
              }
          }
      }

      return result(Game.States.Tie);
    },
});

Game.States = {
    Open: 0,
    Human: 1,
    Opponent: 2,
    Tie: 3,
};

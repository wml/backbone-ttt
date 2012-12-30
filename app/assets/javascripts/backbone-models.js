Game = Backbone.Model.extend({
    urlRoot: '/games',

    defaults: {
        "state": "[[0,0,0],[0,0,0],[0,0,0]]",
        "moves": "[]",
    },

    getState: function() {
        return JSON.parse(this.get("state"));
    },

    move: function(row, col, callback, errorCallback) {
        var state = this.getState();

        if (state[row][col] != Game.States.Open) {
            return false;
        }

        state[row][col] = Game.States.Human;
        this.moveComplete(state, callback, errorCallback);

        return true;
    },

    getAIMove: function(ai, callback, errorCallback) {
        var that = this;
        $.ajax('/ai/' + ai + '/move', {
            data: { "state": that.get("state") },
            error: function(jqXHR, textStatus, errorThrown) { 
                    errorCallback(errorThrown.message);
            },
            success: function(data, textStatus, jqXHR) {
                state = data;
                that.moveComplete(state, callback, errorCallback);
            }
        });
    },

    moveComplete: function(state, callback, errorCallback) {
        var moves = JSON.parse(this.get("moves"));
        var winner = this.winner(state);

        moves.push(state);

        this.set("state", JSON.stringify(state));
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

    winner: function(state) {
      var result = function(who, how, where) {
          return {'who': who, 'how': how, 'where': where};
      };

      for (var row = 0; row < 3; ++row) {
          if (state[row][0] == state[row][1] 
              && state[row][1] == state[row][2]
              && Game.States.Open != state[row][0]
          ) {
              return result(state[row][0], 'row', row);
          }
      }

      for (var col = 0; col < 3; ++col) {
          if (state[0][col] == state[1][col] 
              && state[1][col] == state[2][col]
              && Game.States.Open != state[0][col]
          ) {
              return result(state[0][col], 'col', col);
          }
      }

      if (state[0][0] == state[1][1] 
          && state[1][1] == state[2][2]
          && Game.States.Open != state[0][0]
      ) {
          return result(state[0][0], 'ulbr');
      }

      if (state[2][0] == state[1][1] 
          && state[1][1] == state[0][2]
          && Game.States.Open != state[2][0]
      ) {
          return result(state[2][0], 'blur');
      }

      for (var row = 0; row < 3; ++row) {
          for (var col = 0; col < 3; ++col) {
              if (state[row][col] == Game.States.Open) {
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
    Tie: 3
};

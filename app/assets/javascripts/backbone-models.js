Game = Backbone.Model.extend({
    urlRoot: '/games',

    defaults: {
        "state": "[[0,0,0],[0,0,0],[0,0,0]]",
        "moves": "[]",
    },

    move: function(row, col, callback) {
        // TODO: still struggling in the backbone / rails model with where to
        // put this kind of logic

        var state = JSON.parse(this.get('state'));
        var moves = JSON.parse(this.get('moves'));

        state[row][col] = Game.States.Human;
        moves.push(state);

        if (null == this.winner(state)) {
            this.getAIMove(state, moves, callback);
        }
        else {
            this.moveComplete(state, moves, callback);
        }
    },

    getAIMove: function(state, moves, callback) {
        // TODO: ability to select which AI
        var that = this;
        $.ajax('/ai/FirstAvailable/move', {
            data: { "state": JSON.stringify(state) },
            error: function(jqXHR, textStatus, errorThrown) { /* TODO */ },
            success: function(data, textStatus, jqXHR) {
                state = data;
                moves.push(state);
                that.moveComplete(state, moves, callback);
            }
        });
    },

    moveComplete: function(state, moves, callback) {
        this.set("state", JSON.stringify(state));
        this.set("moves", JSON.stringify(moves));

        var that = this;
        // TODO: error handling
        this.save(
            {}, {
               success: function(model, response) {
                    that.fetch({
                        success: function(){ callback(that.winner(state)) }
               });
            }
        });
    },

    winner: function(state) {
      for (var row = 0; row < 3; ++row) {
          if (state[row][0] == state[row][1] 
              && state[row][1] == state[row][2]
              && Game.States.Open != state[row][0]
          ) {
              return [state[row][0], 'row', row];
          }
      }

      for (var col = 0; col < 3; ++col) {
          if (state[0][col] == state[1][col] 
              && state[1][col] == state[2][col]
              && Game.States.Open != state[0][col]
          ) {
              return [state[0][col], 'col', col];
          }
      }

      if (state[0][0] == state[1][1] 
          && state[1][1] == state[2][2]
          && Game.States.Open != state[0][0]
      ) {
          return [state[0][0], 'ulbr'];
      }

      if (state[2][0] == state[1][1] 
          && state[1][1] == state[0][2]
          && Game.States.Open != state[2][0]
      ) {
          return [state[2][0], 'blur'];
      }
        
      return null;
    },
});

Game.States = {
    Open: 0,
    Human: 1,
    Opponent: 2
};

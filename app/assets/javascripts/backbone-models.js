Game = Backbone.Model.extend({
	urlRoot: '/games',

	defaults: {
	    "state": "[[0,0,0],[0,0,0],[0,0,0]]",
	    "moves": "[]",
	},

	move: function(row, col, callback) {
	    stateJson = JSON.parse(this.get('state'));
	    stateJson[row][col] = Game.States.Human;
	    this.set("state", JSON.stringify(stateJson));

	    var that = this;
	    this.save(
                {}, {
   	        success: function(model, response) {
			that.fetch({
				success: callback
			});
		}
	    });
	},
});

Game.States = {
    Open: 0,
    Human: 1,
    Opponent: 2
};

Game = Backbone.Model.extend({
	urlRoot: '/games',
	
	initialize: function() {
	    this.state = this.state || "[[0,0,0],[0,0,0],[0,0,0]]";
	    this.moves = this.moves || "[]";

	    this.stateJson = JSON.parse(this.state);
	    this.movesJson = JSON.parse(this.moves);
	},

	move: function(row, col) {
	    this.stateJson[row][col] = Game.States.Human;
	    this.set("state", JSON.stringify(this.stateJson));

	    this.save();
	    // TODO: reload w/ computer move
	},
});

Game.States = {
    Open: 0,
    Human: 1,
    Opponent: 2
};

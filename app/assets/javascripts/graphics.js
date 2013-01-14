var Graphics = Graphics || { };

Graphics.Core = {
  eachRow: function(callback) {
    for (var row = 0; row < 3; ++row) {
      for (var col = 0; col < 3; ++col) {
        callback(row, col);			    
      }
    }
  },

  drawState: function(ctx, x, y, ximg, oimg, cellsize, state, winner, lastState) {
    var s = cellsize;
    ctx.globalAlpha = 1;

    Graphics.Core.eachRow(function(row, col) {
      var left = x + s * col;
      var top = y + s * row;

      ctx.beginPath();
      ctx.rect(left, top, s, s);
      ctx.fillStyle = 
        (null != lastState && lastState[row][col] != state[row][col]) 
          ? "#bbbbff"
          : "#e8e8e8";
      ctx.fill();
      ctx.lineWidth = 1;
      ctx.strokeStyle = "#666666";
      ctx.stroke();

      if (Game.States.Human == state[row][col]) {
        ctx.drawImage(ximg, left, top, cellsize, cellsize);
      }
      else if (Game.States.Opponent == state[row][col]) {
        ctx.drawImage(oimg, left, top, cellsize, cellsize);
      }
    });

    if (null != winner) {
      if (Game.States.Tie != winner.who) {
        Graphics.Core.drawWinner(ctx, winner, x, y, cellsize);
      }

      if (null == lastState) {
        ctx.beginPath();
        ctx.globalAlpha = 0.5;
        ctx.rect(0, y, 3 * cellsize, 3 * cellsize);
        ctx.fillStyle = "#fff";
        ctx.fill();
      }
    }
  },

  drawWinner: function(ctx, winner, x, y, cellsize) {
    var s = cellsize;
    var color = (Game.States.Human == winner.who ? '#0F0' : '#F00');

    ctx.beginPath();
    ctx.lineWidth = cellsize / 12;
    ctx.lineCap = 'round';
    ctx.strokeStyle = color;

    if ('row' == winner.how) {
      ctx.moveTo(x + s/4, y + s/2 + s * winner.where);
      ctx.lineTo(x + s * 3 - s / 4, y + s/2 + s * winner.where);
    }
    else if ('col' == winner.how) {
      ctx.moveTo(x + s/2 + s * winner.where, y + s/4);
      ctx.lineTo(x + s/2 + s * winner.where, y + s * 3 - s / 4);
    }
    else if ('ulbr' == winner.how) {
      ctx.moveTo(x + s/4, y + s/4);
      ctx.lineTo(x + s * 3 - s / 4, y + s * 3 - s / 4);
    }
    else {
      ctx.moveTo(x + s/4, y + s * 3 - s / 4);
      ctx.lineTo(x + s * 3 - s / 4, y + s/4);
    }

    ctx.stroke();
  },
};

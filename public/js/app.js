$(document).ready(function(){
  if (typeof(WebSocket) != 'undefined' || typeof(MozWebSocket)) {
    $('#ask').show();
  } else {
    $('#error').show();
  }
  
  // join on enter
  $('#ask input').keydown(function(event) {
    if (event.keyCode == 13) {
      $('#ask a').click();
    }
  })
  
  // join on click
  $('#ask a').click(function() {
    join($('#ask input').val());
    $('#ask').hide();
    $('#game').show();
    $('input#message').focus();
  });

  function finishTurn() {
    $('#turn').hide();
  }

  function join(name) {
    var host = window.location.host.split(':')[0];

    var SocketKlass = "MozWebSocket" in window ? MozWebSocket : WebSocket;
    var ws = new SocketKlass('ws://' + window.location.host + '/clients');

    function addTiles(set, tiles) {
      set.children().remove();
      $.each(tiles, function (index, value) {
        var tile = templates.find('.tile').clone();
        tile.appendTo(set);
        tile.text(value.number);
        tile.addClass(value.color);
        tile.data(value);
        tile.data('set', set.data('index'));
      });
      set.sortable();
      set.droppable({
        drop: function(event, ui) {
          var tile = $(event.toElement).data();
          call('move-tile', {source: tile.set, destination: set.data('index'), tile: {number: tile.number, color: tile.color}});
        }
      });
    }

    var templates = $('div#templates');
    ws.onmessage = function(evt) {
      var obj = $.evalJSON(evt.data);
      if (typeof obj != 'object') return;

      var action = obj['action'];
      console.log({"obj": obj});

      switch (action) {
        case 'refresh':
          addTiles($('#rack .set'), obj.rack);
          $('div#sets').children().remove();
          $.each(obj.sets, function (index, value) {
            var set = templates.find('.set').clone();
            set.appendTo('div#sets');
            set.data('index', value.index);
            addTiles(set, value.tiles);
          });
          break;
        case 'take_turn':
          $('div#turn').show();
          break;
        default:
          console.log("Could not handle: " + evt.data);
          return;
      }
    };

    $('#pickup').click(function(event) {
      call('pickup');
      finishTurn();
    });

    $('#finished').click(function(event) {
      call('finished');
      finishTurn();
    });

    $('#add-set').droppable({
      drop: function(event, ui) {
        var tile = $(event.toElement).data();
        call('add-set', {source: tile.set, tile: {number: tile.number, color: tile.color}});
      }
    });

    // send name when joining
    ws.onopen = function() {
      call('join', {user: name})
    }

    var call = function(action, body) {
      ws.send($.toJSON({action: action, body: body}));
    };
  }
});

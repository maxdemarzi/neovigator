Path = {
  init: function() {

  },
  addNode: function(node) {
    // add to path
    $('#path ul li').removeClass('current');
    
    var idxstr = (node.subject.idx<10) ? "0"+node.subject.idx : node.subject.idx;
    var li = $('<li id="'+node.subject.id+'" class="current"><div>'+idxstr+'</div><a href="#">'+node.subject.name+'</a></li>');
    $('#path ul').append(li);
    
    li.click(function() {
      myGraph.selectNode(myGraph.getNodeById($(this).attr('id')));
      $('#path ul li').removeClass('current');
      $('#path ul li[id='+$(this).attr('id')+']').addClass('current');
      return false;
    });
  },
  removeNode: function(node) {
    
  }
}


Attributes = {
  expanded: false,
  adjustHeight: function() {
    $('#attributes').height($('#sidebar').height()-$('#topic').height());
//    console.log("adjusted height");
  },
  init: function(donut) {
    $('ul.attributes').empty();
    
    $.each(donut.segments, function() {
      var li = $('<li><a href="'+this.subject.id+'" attrid="'+this.subject.id+'">'+this.subject.name+'<span class="count">'+this.subject.values.length+'</span><br class="clear"/></a></li>');
      li.css('background', this.col);
      $('ul.attributes').append(li);
    });
    
    Attributes.contract();
    
    $('ul.attributes li').find('a').mouseover(function() {      
      // triggers an Attributes#select
      myGraph.selectedNode.subject.setSelectedAttribute($(this).attr('attrid'));
      $('ul.attributes li').removeClass('current');
      $(this).parent().addClass('current');
      return false; // prevent from event bubbling
    })
    .click(function() {
      Attributes.contract();
      return false;
    });
    
    $('h3#selected-attribute').click(function() { Attributes.toggle(); });
  },
  select: function(segment) { 
    // donut segments are passed here because they also contain the attribute color!
    $('#sidebar').css("background", segment.col);
    
    Attributes.adjustHeight();
    
    $('h3#selected-attribute')
      .html('<a href="#">'+segment.subject.name+'<span class="arrow"></span><span class="count">'+segment.subject.values.length+'</span><br class="clear"/></a>')
      .find('a');
    
    // collect values
    $('ul.attribute-values').empty();
    $.each(segment.subject.values, function() {
      var html = $('<li><a href="#" valueid="'+this.id+'">'+this.name+'</a></li>');
      html.data('value', this);
      $('ul.attribute-values').append(html);
    });
    
    $('ul.attribute-values li a').click(function() {
      p.addNode($(this).parent().data('value'));
    });
  },
  expand: function() {
    $('ul.attributes li').show();
    Attributes.expanded = true;
    return false; // prevent from event bubbling
  },
  contract: function() {
    $('ul.attributes li').hide();
    return Attributes.expanded = false; // prevent from event bubbling as well
  },
  toggle: function() {
    if (Attributes.expanded) {
      return Attributes.contract();
    } else {
      return Attributes.expand();
    }
  }
}

$(function() {
  $('aside').height(window.innerHeight-60);
  $(window).resize(function(){
    $('aside').height(window.innerHeight-60);
  });

  //Sidebar show/hide
  $('#toggle-sidebar').toggle(function() {
    $("#sidebar").slideUp("slow");
    $(this).toggleClass("active");
  }, function() {
    $("#sidebar").slideDown("slow");
    $(this).toggleClass("active");
  });
});

Event.observe(window, 'load', initialize, false);

if (!window.ArdesAjaxCrud) {
  var ArdesAjaxCrud = new Object();
}

Object.extend(ArdesAjaxCrud, {

  initialize: function() {
    this.dirty = new Array();
  },
  
  setDirty: function(id) {
    if (this.dirty.indexOf(id) == -1) {
      this.dirty.push(id);
    }
  },
  
  setClean: function(id) {
    this.dirty = this.dirty.without(id);
    this[id] = null;
  },
  
  observe: function(id) {
    form_id = id + '_form';
    if ($(form_id)) {
      this[id] = new Form.EventObserver($(form_id), function(){
        ArdesAjaxCrud.setDirty(id);
      });
    }
  },
  
  confirm: function() {
    if (this.dirty.length > 0) {
      this.dirty.each(function(id){
        new Effect.Highlight(id, {startcolor: '#990000'});
      });
      return confirm('You have unsaved changes on this page.  Continuing will discard those changes.');
    } else {
      return true;
    }
  },
  
  focus: function(element_id) {
    Element.scrollTo(element_id);
    if (first = Form.findFirstElement(element_id)) {
      Field.focus(first);
    }
  }
})

function initialize() {
  ArdesAjaxCrud.initialize();
}
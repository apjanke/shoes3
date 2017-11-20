
#include "shoes/types/event.h"


VALUE cShoesEvent; 

FUNC_M("+shoesevent", shoesevent, -1);

void shoes_shoesevent_init() {
    cShoesEvent = rb_define_class_under(cTypes, "ShoesEvent", cNative); 
    rb_define_alloc_func(cShoesEvent, shoes_event_alloc);
    rb_define_method(cShoesEvent, "type", CASTHOOK(shoes_event_type), 0);
    rb_define_method(cShoesEvent, "object", CASTHOOK(shoes_event_object), 0);
    rb_define_method(cShoesEvent, "accept", CASTHOOK(shoes_event_get_accept),0);
    rb_define_method(cShoesEvent, "accept=", CASTHOOK(shoes_event_set_accept),1);
    rb_define_method(cShoesEvent, "button", CASTHOOK(shoes_event_button), 0);
    rb_define_method(cShoesEvent, "x", CASTHOOK(shoes_event_x), 0);
    rb_define_method(cShoesEvent, "y", CASTHOOK(shoes_event_y), 0);
    rb_define_method(cShoesEvent, "width", CASTHOOK(shoes_event_width), 0);
    rb_define_method(cShoesEvent, "height", CASTHOOK(shoes_event_height), 0);
    rb_define_method(cShoesEvent, "key", CASTHOOK(shoes_event_key), 0);
    rb_define_method(cShoesEvent, "key=", CASTHOOK(shoes_event_set_key), 1);
    rb_define_method(cShoesEvent, "modifiers", CASTHOOK(shoes_event_modifiers), 0);
    RUBY_M("+shoesevent", shoesevent, -1);
}
 
// ruby
void shoes_event_mark(shoes_event *event) {
    rb_gc_mark_maybe(event->type);
    rb_gc_mark_maybe(event->object);
    rb_gc_mark_maybe(event->key);
    rb_gc_mark_maybe(event->modifiers);
}

void shoes_event_free(shoes_event *event) {
    RUBY_CRITICAL(free(event));
}

// users should not create events but something has to be visible
// click calls here.
VALUE shoes_event_new(VALUE klass, ID type, VALUE widget, int x, int y, int btn, VALUE mods) {
    shoes_event *event;
    VALUE obj = shoes_event_alloc(klass);
    Data_Get_Struct(obj, shoes_event, event);
    event->accept = 1;
    event->type = type;
    event->object = widget;
    event->x = x;
    event->y = y;
    event->btn = btn;
    event->key = Qnil;
    event->modifiers = mods;
    return obj;
}

VALUE shoes_event_new_widget(VALUE klass, ID type, VALUE widget, int btn, int x,
        int y, int w, int h) {
    shoes_event *event;
    VALUE obj = shoes_event_alloc(klass);
    Data_Get_Struct(obj, shoes_event, event);
    event->accept = 1;
    event->type = type;
    event->object = widget;
    event->btn = btn;
    event->x = x;
    event->y = y;
    event->width = w;
    event->height = h;
    event->key = Qnil;
    event->modifiers = Qnil;
    return obj;
}

VALUE shoes_event_alloc(VALUE klass) {
    VALUE obj;
    shoes_event *event = SHOE_ALLOC(shoes_event);
    SHOE_MEMZERO(event, shoes_event, 1);
    obj = Data_Wrap_Struct(klass, shoes_event_mark, shoes_event_free, event);
    event->type = Qnil;
    event->object = Qnil;
 
    return obj;
}


VALUE shoes_canvas_shoesevent(int argc, VALUE *argv, VALUE self) {
    VALUE ev = Qnil;
    SETUP_CANVAS();
    // Parse the hash args
    VALUE hsh = argv[0];
    VALUE typeq = shoes_hash_get(hsh, rb_intern("type"));
    VALUE typesym;
    ID type;
    if (TYPE(typeq) == T_SYMBOL) {
      type = SYM2ID(typeq);
    } else {
      type = rb_intern(RSTRING_PTR(typeq));
    }

    //if (type == s_click)
    //  fprintf(stderr, "made a s_click\n");
    VALUE obj = Qnil;
    int x = NUM2INT(shoes_hash_get(hsh, rb_intern("x")));
    int y = NUM2INT(shoes_hash_get(hsh, rb_intern("y")));
    int btn = NUM2INT(shoes_hash_get(hsh, rb_intern("button")));
    ev = shoes_event_new(cShoesEvent,type,obj,x,y,btn,Qnil);
    return ev;
}


VALUE shoes_event_type(VALUE self) {
    shoes_event *event;
    Data_Get_Struct(self, shoes_event, event);
    return ID2SYM(event->type);
}

VALUE shoes_event_object(VALUE self) {
    shoes_event *event;
    Data_Get_Struct(self, shoes_event, event);
    return event->object;
}

VALUE shoes_event_get_accept(VALUE self) {
    shoes_event *event;
    Data_Get_Struct(self, shoes_event, event);
    return (event->accept) ? Qtrue : Qfalse;
}
VALUE shoes_event_set_accept(VALUE self, VALUE tf) {
    shoes_event *event;
    Data_Get_Struct(self, shoes_event, event);
    event->accept = (NIL_P(tf) || tf == Qfalse ) ? 0 : 1;
    return tf;
}
VALUE shoes_event_button(VALUE self) {
    shoes_event *event;
    Data_Get_Struct(self, shoes_event, event);
    return INT2NUM(event->btn);
}
VALUE shoes_event_x(VALUE self) {
    shoes_event *event;
    Data_Get_Struct(self, shoes_event, event);
    return INT2NUM(event->x);
}
VALUE shoes_event_y(VALUE self) {
    shoes_event *event;
    Data_Get_Struct(self, shoes_event, event);
    return INT2NUM(event->y);
}

VALUE shoes_event_height(VALUE self) {
    shoes_event *event;
    Data_Get_Struct(self, shoes_event, event);
    return INT2NUM(event->height);
}
VALUE shoes_event_width(VALUE self) {
    shoes_event *event;
    Data_Get_Struct(self, shoes_event, event);
    return INT2NUM(event->width);
}

// TODO keys: strings, not ints. Beware UTF8
VALUE shoes_event_key(VALUE self) {
    shoes_event *event;
    Data_Get_Struct(self, shoes_event, event);
    return INT2NUM(event->key);
}
VALUE shoes_event_set_key(VALUE self, VALUE key) {
    shoes_event *event;
    Data_Get_Struct(self, shoes_event, event);  
    return INT2NUM(event->key);
}
VALUE shoes_event_modifiers(VALUE self) {
    shoes_event *event;
    Data_Get_Struct(self, shoes_event, event);  
    return event->modifiers;
}

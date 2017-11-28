#include "shoes/ruby.h"
#include "shoes/canvas.h"
#include "shoes/app.h"
#include "shoes/internal.h"
#include "shoes/world.h"
#include "shoes/native/native.h"

#ifndef SHOES_EVENT_TYPE_H
#define SHOES_EVENT_TYPE_H

/* extern variables necessary to communicate with other parts of Shoes */
extern VALUE cShoes, cApp, cTypes, cCanvas, cWidget;
extern VALUE cShoesEvent;

extern shoes_app _shoes_app;

#define SHOES_MODIFY_SHIFT 0x01
#define SHOES_MODIFY_CTRL  0x02
#define SHOES_MODIFY_ALT   0x04
#define SHOES_MODIFY_META  0x08  // caution: fan key on osx, something else on linux


typedef struct {
    VALUE type; 
    VALUE object;
    int accept;
    int btn;
    int x;  
    int y;
    int width;
    int height;
    VALUE key;     // UTF-8 string
    VALUE modifiers; //  modifiers if we can get them.
} shoes_event;


// ruby getters and setters
VALUE shoes_event_type(VALUE self);
VALUE shoes_event_object(VALUE self);
VALUE shoes_event_get_accept(VALUE self);
VALUE shoes_event_set_accept(VALUE self, VALUE tf);
VALUE shoes_event_button(VALUE self);
VALUE shoes_event_x(VALUE self);
VALUE shoes_event_y(VALUE self);
VALUE shoes_event_width(VALUE self);
VALUE shoes_event_height(VALUE self);
VALUE shoes_event_key(VALUE self);
VALUE shoes_event_set_key(VALUE self, VALUE key);
VALUE shoes_event_modifiers(VALUE self);
// init create
void shoes_event_mark(shoes_event *event);
void shoes_event_free(shoes_event *event);
VALUE shoes_event_new(VALUE klass, ID type, VALUE widget, int x, int y,
    int btn, VALUE modifiers);
VALUE shoes_event_alloc(VALUE klass);
VALUE shoes_canvas_shoesevent(int argc, VALUE *argv, VALUE self);
VALUE shoes_event_new_widget(VALUE klass, ID type, VALUE widget, int btn, int x,
        int y, int w, int h);
#endif
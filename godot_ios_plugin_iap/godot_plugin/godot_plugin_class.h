#pragma once

#include "core/object/object.h"
#include "core/object/class_db.h"

class PluginClass : public Object {
    GDCLASS(IOSInAppPurchase, Object);
    
    static void _bind_methods();
    
public:
    
    PluginClass();
    ~PluginClass();
};



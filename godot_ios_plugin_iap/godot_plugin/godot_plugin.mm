
#import <Foundation/Foundation.h>
#import "godot_plugin.h"
#import "godot_plugin_class.h"
#import "core/config/engine.h"

PluginClass *plugin;

void ios_in_app_purchase_init() {
    plugin = memnew(PluginClass);
    Engine::get_singleton()->add_singleton(Engine::Singleton("IOSInAppPurchase", plugin));
}

void ios_in_app_purchase_deinit() {
   if (plugin) {
       memdelete(plugin);
   }
}

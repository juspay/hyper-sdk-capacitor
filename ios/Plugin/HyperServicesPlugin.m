/*
 * Copyright (c) Juspay Technologies.
 *
 * This source code is licensed under the AGPL 3.0 license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

// Define the plugin using the CAP_PLUGIN Macro, and
// each method the plugin supports using the CAP_PLUGIN_METHOD macro.
CAP_PLUGIN(HyperServicesPlugin, "HyperServices",
           CAP_PLUGIN_METHOD(createHyperServices, CAPPluginReturnNone);
           CAP_PLUGIN_METHOD(isInitialised, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(preFetch, CAPPluginReturnNone);
           CAP_PLUGIN_METHOD(initiate, CAPPluginReturnNone);
           CAP_PLUGIN_METHOD(process, CAPPluginReturnNone);
           CAP_PLUGIN_METHOD(terminate, CAPPluginReturnNone);
           CAP_PLUGIN_METHOD(updateBaseViewController, CAPPluginReturnNone);
           CAP_PLUGIN_METHOD(onBackPressed, CAPPluginReturnNone);
           CAP_PLUGIN_METHOD(isNull, CAPPluginReturnPromise);
)

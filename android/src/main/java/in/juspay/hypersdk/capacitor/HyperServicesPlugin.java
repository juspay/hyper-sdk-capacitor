package in.juspay.hypersdk.capacitor;

import android.util.Log;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

@CapacitorPlugin(name = "HyperServices")
public class HyperServicesPlugin extends Plugin {

    @PluginMethod
    public void echo(PluginCall call) {
        String value = call.getString("value");

        Log.i("ECHO", value);

        JSObject ret = new JSObject();
        ret.put("value", value);
        call.resolve(ret);
    }
}

package in.juspay.hypersdk.capacitor;

import androidx.annotation.Nullable;
import androidx.fragment.app.FragmentActivity;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

import org.json.JSONException;
import org.json.JSONObject;

import in.juspay.hyper.constants.LogLevel;
import in.juspay.hyper.constants.LogSubCategory;
import in.juspay.hypersdk.core.SdkTracker;
import in.juspay.hypersdk.data.JuspayResponseHandler;
import in.juspay.hypersdk.ui.HyperPaymentsCallbackAdapter;
import in.juspay.services.HyperServices;

@CapacitorPlugin(name = "HyperServices")
public class HyperServicesPlugin extends Plugin {

    private static final String HYPER_EVENT = "HyperEvent";
    protected static final String SDK_TRACKER_LABEL = "hyper_sdk_capacitor";

    private static final Object lock = new Object();

    @Nullable
    private HyperServices hyperServices;

    @PluginMethod
    public void createHyperServices(PluginCall call) {
        synchronized (lock) {
            FragmentActivity activity = getActivity();

            if (activity == null) {
                call.reject("createHyperServices failed: Activity is null");
                return;
            }
            if (hyperServices == null) {
                hyperServices = new HyperServices(activity);
            }
            call.resolve();
        }
    }

    @PluginMethod
    public void preFetch(PluginCall call) {
        try {
            JSONObject payload = call.getData();
            FragmentActivity activity = getActivity();
            HyperServices.preFetch(activity, payload);
            call.resolve();
        } catch (Exception e) {
            e.printStackTrace();
            call.reject(e.getMessage());
        }
    }

    @PluginMethod
    public void onBackPressed(PluginCall call) {
        synchronized (lock) {
            JSObject ret = new JSObject();
            ret.put("onBackPressed", hyperServices != null && hyperServices.onBackPressed());
            call.resolve(ret);
        }
    }

    @PluginMethod
    public void initiate(PluginCall call) {
        JSONObject payload = call.getData();
        synchronized (lock) {
            try {
                FragmentActivity activity = getActivity();

                if (activity == null) {
                    SdkTracker.trackBootLifecycle(
                            LogSubCategory.LifeCycle.HYPER_SDK,
                            LogLevel.ERROR,
                            SDK_TRACKER_LABEL,
                            "initiate",
                            "activity is null");
                    call.reject("Initiate Failed: Activity is null");
                    return;
                }

                if (hyperServices == null) {
                    SdkTracker.trackBootLifecycle(
                            LogSubCategory.LifeCycle.HYPER_SDK,
                            LogLevel.ERROR,
                            SDK_TRACKER_LABEL,
                            "initiate",
                            "hyperServices is null");
                    call.reject("HyperServices is null, create a HyperSDK instance before calling initiate");
                    return;
                }
                hyperServices.initiate(activity, payload, new HyperPaymentsCallbackAdapter() {
                    @Override
                    public void onEvent(JSONObject data, JuspayResponseHandler handler) {
                        // Send out the event to the merchant on JS side
                        JSObject response;
                        try {
                            response = JSObject.fromJSONObject(data);
                        } catch (JSONException e) {
                            response = new JSObject();
                        }

                        notifyListeners(HYPER_EVENT, response);
                    }
                });
            } catch (Exception e) {
                e.printStackTrace();
                call.reject(e.getMessage());
            }
            call.resolve();
        }
    }

    @PluginMethod
    public void process(PluginCall call) {
        JSONObject payload = call.getData();
        synchronized (lock) {
            try {
                FragmentActivity activity = getActivity();

                if (activity == null) {
                    SdkTracker.trackBootLifecycle(
                            LogSubCategory.LifeCycle.HYPER_SDK,
                            LogLevel.ERROR,
                            SDK_TRACKER_LABEL,
                            "initiate",
                            "activity is null");
                    call.reject("process failed: Activity is Null");
                    return;
                }

                if (hyperServices == null) {
                    SdkTracker.trackBootLifecycle(
                            LogSubCategory.LifeCycle.HYPER_SDK,
                            LogLevel.ERROR,
                            SDK_TRACKER_LABEL,
                            "initiate",
                            "hyperServices is null");
                    call.reject("HyperServices instance is Null");
                    return;
                }
                if (!hyperServices.isInitialised()) {
                    call.reject("Initiate should be done before calling process!");
                    return;
                }
                hyperServices.process(activity, payload);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    @PluginMethod
    public void terminate(PluginCall call) {
        synchronized (lock) {
            if (hyperServices != null) {
                hyperServices.terminate();
            }
        }
        hyperServices = null;
        call.resolve();
    }

    @PluginMethod
    public void isInitialised(PluginCall call) {
        boolean isInitialised = false;

        synchronized (lock) {
            if (hyperServices != null) {
                try {
                    isInitialised = hyperServices.isInitialised();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }
        JSObject ret = new JSObject();
        ret.put("isInitialised", isInitialised);

        call.resolve(ret);
    }

    @PluginMethod
    public void isNull(PluginCall call) {
        JSObject ret = new JSObject();
        ret.put("isNull", hyperServices == null);
        call.resolve(ret);
    }
}

/*
 * Copyright (c) Juspay Technologies.
 *
 * This source code is licensed under the AGPL 3.0 license found in the
 * LICENSE file in the root directory of this source tree.
 */

package in.juspay.hypersdk.capacitor;

import androidx.annotation.Nullable;
import androidx.fragment.app.FragmentActivity;

import android.graphics.Rect;
import android.view.Gravity;
import android.view.ViewTreeObserver;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

import in.juspay.hyper.constants.LogLevel;
import in.juspay.hyper.constants.LogSubCategory;
import in.juspay.hypersdk.core.SdkTracker;
import in.juspay.hypersdk.data.JuspayResponseHandler;
import in.juspay.hypersdk.ui.HyperPaymentsCallbackAdapter;
import in.juspay.services.HyperServices;

import org.json.JSONException;
import org.json.JSONObject;

@CapacitorPlugin(name = "HyperServices")
public class HyperServicesPlugin extends Plugin {

    private static final String HYPER_EVENT = "HyperEvent";
    protected static final String SDK_TRACKER_LABEL = "hyper_sdk_capacitor";

    private static final Object lock = new Object();

    @Nullable
    private HyperServices hyperServices;

    @Nullable
    private FrameLayout widgetContainer;

    @Nullable
    private ViewTreeObserver.OnGlobalLayoutListener keyboardLayoutListener;

    private void detachKeyboardAdjustment() {
        if (widgetContainer != null && keyboardLayoutListener != null) {
            ViewTreeObserver observer = widgetContainer.getViewTreeObserver();
            if (observer.isAlive()) {
                observer.removeOnGlobalLayoutListener(keyboardLayoutListener);
            }
        }
        if (widgetContainer != null) {
            widgetContainer.setTranslationY(0);
        }
        keyboardLayoutListener = null;
    }

    private void attachKeyboardAdjustment(FrameLayout container) {
        detachKeyboardAdjustment();

        keyboardLayoutListener = () -> {
            if (widgetContainer == null) {
                return;
            }

            Rect visibleFrame = new Rect();
            widgetContainer.getWindowVisibleDisplayFrame(visibleFrame);

            int[] containerLocation = new int[2];
            widgetContainer.getLocationOnScreen(containerLocation);

            int containerBottom = containerLocation[1] + widgetContainer.getHeight();
            int overlap = Math.max(0, containerBottom - visibleFrame.bottom);
            widgetContainer.setTranslationY(-overlap);
        };

        ViewTreeObserver observer = container.getViewTreeObserver();
        if (observer.isAlive()) {
            observer.addOnGlobalLayoutListener(keyboardLayoutListener);
        }
        container.post(() -> {
            if (keyboardLayoutListener != null) {
                keyboardLayoutListener.onGlobalLayout();
            }
        });
    }

    @PluginMethod
    public void createHyperServices(PluginCall call) {
        synchronized (lock) {
            createHyperService(call, null, null);
        }
    }

    @PluginMethod
    public void createHyperServicesWithTenantId(PluginCall call) {
        synchronized (lock) {
            String tenantId = call.getString("tenantId");
            String clientId = call.getString("clientId");
            createHyperService(call, tenantId, clientId);
        }
    }

    private void createHyperService(PluginCall call, @Nullable String tenantId, @Nullable String clientId) {
        FragmentActivity activity = getActivity();

        if (activity == null) {
            call.reject("createHyperServices failed: Activity is null");
            return;
        }
        if (hyperServices == null) {
            if (tenantId != null && clientId != null) {
                hyperServices = new HyperServices(activity, tenantId, clientId);
            } else {
                hyperServices = new HyperServices(activity);
            }
        }
        call.resolve();
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
                            "activity is null"
                    );
                    call.reject("Initiate Failed: Activity is null");
                    return;
                }

                if (hyperServices == null) {
                    SdkTracker.trackBootLifecycle(
                            LogSubCategory.LifeCycle.HYPER_SDK,
                            LogLevel.ERROR,
                            SDK_TRACKER_LABEL,
                            "initiate",
                            "hyperServices is null"
                    );
                    call.reject("HyperServices is null, create a HyperSDK instance before calling initiate");
                    return;
                }
                hyperServices.initiate(
                        activity,
                        payload,
                        new HyperPaymentsCallbackAdapter() {
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
                        }
                );
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
                            "activity is null"
                    );
                    call.reject("process failed: Activity is Null");
                    return;
                }

                if (hyperServices == null) {
                    SdkTracker.trackBootLifecycle(
                            LogSubCategory.LifeCycle.HYPER_SDK,
                            LogLevel.ERROR,
                            SDK_TRACKER_LABEL,
                            "initiate",
                            "hyperServices is null"
                    );
                    call.reject("HyperServices instance is Null");
                    return;
                }
                if (!hyperServices.isInitialised()) {
                    call.reject("Initiate should be done before calling process!");
                    return;
                }

                // Payment Widget: create native container if fragmentViewGroups is present
                JSONObject hyperPayload = payload.optJSONObject("payload");
                JSONObject fragmentViewGroups = hyperPayload != null
                        ? hyperPayload.optJSONObject("fragmentViewGroups")
                        : null;
                if (fragmentViewGroups != null && fragmentViewGroups.has("paymentWidget")) {
                    final JSONObject fvg = fragmentViewGroups;
                    final JSONObject rectJson = hyperPayload != null ? hyperPayload.optJSONObject("paymentWidgetRect") : null;
                    if (rectJson == null) {
                        call.reject("paymentWidgetRect is required for payment widget");
                        return;
                    }
                    final HyperServices hs = hyperServices;
                    final FragmentActivity act = activity;
                    act.runOnUiThread(() -> {
                        try {
                            FrameLayout container = new FrameLayout(act);
                            float density = act.getResources().getDisplayMetrics().density;
                            int x = (int) (rectJson.optDouble("x", 0) * density);
                            int y = (int) (rectJson.optDouble("y", 0) * density);
                            int width = (int) (rectJson.optDouble("width", 0) * density);
                            int height = (int) (rectJson.optDouble("height", 0) * density);

                            FrameLayout.LayoutParams params;
                            if (height > 0) {
                                params = new FrameLayout.LayoutParams(width, height);
                            } else {
                                params = new FrameLayout.LayoutParams(width, FrameLayout.LayoutParams.WRAP_CONTENT);
                            }
                            params.leftMargin = x;
                            params.topMargin = y;
                            params.gravity = Gravity.TOP | Gravity.START;
                            container.setLayoutParams(params);
                            ViewGroup contentView = act.findViewById(android.R.id.content);
                            contentView.addView(container, params);
                            widgetContainer = container;
                            attachKeyboardAdjustment(container);

                            fvg.put("paymentWidget", container);
                            if (hyperPayload != null) {
                                hyperPayload.put("fragmentViewGroups", fvg);
                                payload.put("payload", hyperPayload);
                            }

                            hs.process(act, payload);
                        } catch (Exception e) {
                            e.printStackTrace();
                            JSObject errorEvent = new JSObject();
                            errorEvent.put("event", "widget_setup_error");
                            errorEvent.put("error", e.getMessage());
                            notifyListeners(HYPER_EVENT, errorEvent);
                        }
                    });
                    call.resolve();
                } else {
                    hyperServices.process(activity, payload);
                    call.resolve();
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    @PluginMethod
    public void terminate(PluginCall call) {
        synchronized (lock) {
            detachKeyboardAdjustment();
            if (widgetContainer != null) {
                FragmentActivity activity = getActivity();
                if (activity != null) {
                    activity.runOnUiThread(() -> {
                        if (widgetContainer != null && widgetContainer.getParent() != null) {
                            ((ViewGroup) widgetContainer.getParent()).removeView(widgetContainer);
                        }
                        widgetContainer = null;
                    });
                } else {
                    widgetContainer = null;
                }
            }
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

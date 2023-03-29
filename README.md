# HYPER-SDK-CAPACITOR

Capacitor Wrapper over HyperSDK which enables payment orchestration via different dynamic modules. More details available at Juspay Developer Docs for [Express Checkout SDK](https://developer.juspay.in/v2.0/docs/introduction) and [Payment Page SDK](https://developer.juspay.in/v4.0/docs/introduction).

## Install

```bash
npm install hyper-sdk-capacitor
npx cap sync
```

### Android

Add following maven url in root build.gradle:

```groovy
allprojects {
    repositories {
        ....
        ....
        maven { url "https://maven.juspay.in/jp-build-packages/hyper-sdk/" }
    }
}
```

#### **Updating Client ID (3.0.0 and above)**

Add the clientId ext property in root(top) `build.gradle`:

```groovy
buildscript {
    ....
    ext {
        ....
        clientId = "<clientId shared by Juspay team>"
        hyperSDKVersion = "2.1.12"
        ....
    }
    ....
}
```

This is the same clientId present earlier in the `MerchantConfig.txt` file.

Optionally, you can also provide an override for base SDK version present in plugin (the newer version among both would be considered).

#### **Updating Client ID (2.0.x) [Deprecated]**

Place the `MerchantConfig.txt` file alongside the root(top) `build.gradle` file. The contents of the file should be as follows.

```txt
clientId = <clientId shared by Juspay Team>
```

### iOS

Place the `MerchantConfig.txt` file inside the folder where the Podfile is present. This file doesn't need to be added to the project. The content of the file should be as below

```txt
clientId = <clientId shared by Juspay Team>
```

Add below post_install script in the Podfile

```sh
post_install do |installer|
 fuse_path = "./Pods/HyperSDK/Fuse.rb"
 clean_assets = false # Pass true to re-download all the assets
 if File.exist?(fuse_path)
   if system("ruby", fuse_path.to_s, clean_assets.to_s)
   end
 end
end
```

Run the following command inside the ios folder of your project:

```sh
pod install
```

__________________

### Import HyperSDK

```ts
import { Plugins } from '@capacitor/core';
import 'hyper-sdk-capacitor';

const { HyperServices } = Plugins;
```

### Prefetch

To keep the SDK up to date with the latest changes, it is highly recommended to call preFetch as early as possible. It takes a `JSON Object` as its argument.

```javascript
await HyperServices.preFetch(payload);
```

__________________

### Step-1: Create HyperServices Object

This method creates an instance of `HyperServices` class in the Capacitor Plugin on which all the `HyperSDK` APIs / methods are triggered. It internally uses the current activity as an argument.

**Note**: This method is mandatory and is required to call any other subsequent methods from `HyperSDK`.

```javascript
await HyperServices.createHyperServices();
```

**Note**: For Web, following parameters should be passed createHyperServices API.

- clientId : "Client shared by Juspay"
- service :
  - `"in.juspay.hyperpay"` (For Payment Page)
  - `"in.juspay.hyperapi"` (For Express Checkout)

```javascript
await HyperServices.createHyperServices(clientId, service)
```

__________________

### Step-2: Initiate

This method should be called on the render of the host screen. This will boot up the SDK and start the Hyper engine. It takes a `JSON Object` as its argument which will contain the base parameters for the entire session and remains static throughout one SDK instance lifetime.

**Notes**:

1. It is highly recommended to initiate SDK from the order summary page (at least 5 seconds before opening your payment page) for seamless user experience.
2. `initiate` should be called only once in one session.

```javascript
await HyperServices.initiate(initiatePayload);
```

Follow the documentation for [initiatePayload](https://developer.juspay.in/v4.0/docs/initiate-payload)

__________________

### To check if SDK is initialized or not

```javascript
var { isInitialised } = await HyperServices.isInitialised();
```

### Step-3: Process

This API can be triggered any number of times based on requirements or app flow structure.
It should not be called on an HyperSDK instance which has not been initiated (Initiate API should be called before calling process API and make sure SDK is initialized)

This API should be triggered for all operations required from `HyperSDK`. The operation may be related to:

- Displaying payment options on your payment page
- Performing a transaction
- User's payment profile management

The result of the process call is provided in the `Hyper Event listener`, later discussed in [step-4](#step-4-listen-to-events-from-hypersdk).

```javascript
await HyperServices.process(processPayload);

```

Follow the documentation for [Process Payload](https://developer.juspay.in/v4.0/docs/process-payload) :

__________________

### Step-4: Listen to events from HyperSDK

`HyperSDK` Native Module will be emitting all the relevant events to JS via `notifyListeners` and JavaScript modules can then register to receive events by invoking `addListener` on the `HyperServices` Plugin instance with the event name `'HyperEvent'`. The listener will return a `JSON` response.

The following events should be handled here:

- `show_loader`: To show a loader for the processing state.
- `hide_loader`: To hide the previously shown loader.
- `initiate_result`: Result of initiate done in [step-2](#step-2-initiate).
- `process_result`: Result of the process operation done in [step-3](#step-3-process).

```javascript

HyperServices.addListener('HyperEvent', async (data) => {
   var event = data["event"];
   switch (event) {
      case "show_loader": {
         // Show a loader
      }
      break;
      case "hide_loader": {
         // Hide Loader
      }
      break;
      case "initiate_result": {
         // Initiate api response
      }
      break;
      case "process_result": {
         // Process result
      }
      break;
      default:
         let payload = data["payload"];
         console.log("process result: ", payload)
      break;
   }
});
```

#### WEB

Documentation : <https://developer.juspay.in/v5.1/docs/introduction>
Once the payment is complete the user is redirected to the return_url configured by you. Following is the typical destination where the user is taken to:
Payment Response : <https://developer.juspay.in/docs/integration#section-payment-response>

__________________

### Step-5: Android Hardware Back-Press Handling

`HyperSDK` internally uses an android fragment for opening the bank page and will need the control to hardware back press when the bank page is active. This can be done by invoking `addEventListener` on the `backButton` provided by React Capacitor.

If the blocking asynchronous call `HyperServices.onBackPressed()` returns true, `HyperSDK` will handle the back press, else merchant can handle it.

```javascript
import { App } from '@capacitor/app';

.........
.........

App.addListener('backButton', async (data) => {
  const { onBackPressed } = await HyperServices.onBackPressed();
  if (!onBackPressed) {
    window.history.back();
  }
});
```

__________________

### Terminate SDK

This method shall be triggered when `HyperSDK` is no longer required.
Note : After calling terminate, initiate has to be called again.

```javascript
await HyperServices.terminate();
```

__________________

### Helper Method: Is Null

This is a helper method and can be used to check whether the `HyperServices` object is `null` at any particular moment. It is a blocking synchronous method and returns a `boolean` value.

```javascript
var { isNull } = await HyperServices.isNull();
```

## License

hyper-sdk-capacitor is distributed under [AGPL-3.0-only](https://bitbucket.org/juspay/hyper-sdk-capacitor/src/main/LICENSE.md) license.

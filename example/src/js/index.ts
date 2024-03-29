/*
 * Copyright (c) Juspay Technologies.
 *
 * This source code is licensed under the AGPL 3.0 license found in the
 * LICENSE file in the root directory of this source tree.
 */

/* eslint-disable @typescript-eslint/no-unused-vars */
/* eslint-disable no-undef */
import { App } from '@capacitor/app';
import { SplashScreen } from '@capacitor/splash-screen';
import { defineCustomElements } from '@ionic/pwa-elements/loader';
import { HyperServices } from 'hyper-sdk-capacitor';
import * as KJUR from 'jsrsasign';

import customerData from './customer_config.json';
import merchantData from './merchant_config.json';

/*
merchantData has the following values [Get these values from Juspay Team]
(This is to create signature at frontend. Ideally it should be created in backend.)
*/
const uuidv4 = () => {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
    const r = (Math.random() * 16) | 0,
      v = c == 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
};

const newOrderId = () => {
  let result = '';
  const characters =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  const charactersLength = characters.length;
  for (let i = 0; i < 10; i++) {
    result += characters.charAt(Math.floor(Math.random() * charactersLength));
  }
  return result;
};

function hexToBase64(hexstring) {
  return btoa(
    hexstring
      .match(/\w{2}/g)
      .map(function (a) {
        return String.fromCharCode(parseInt(a, 16));
      })
      .join(''),
  );
}

function generateSignature(privateKey, payload) {
  const rsaKey = new KJUR.RSAKey();
  rsaKey.readPrivateKeyFromPEMString(privateKey);
  const sig = new KJUR.crypto.Signature({ alg: 'SHA256withRSA' });
  sig.init(rsaKey);
  sig.updateString(payload);
  const sigValueHex = sig.sign();
  const base64String = hexToBase64(sigValueHex);
  return base64String;
}

const getSignature = signatureJson => {
  const signatureJsonString = JSON.stringify(signatureJson);

  let privateKey = merchantData.privateKey;
  if (!privateKey.startsWith('-----BEGIN RSA PRIVATE KEY-----\n')) {
    privateKey = '-----BEGIN RSA PRIVATE KEY-----\n' + privateKey;
  }
  if (!privateKey.endsWith('\n-----END RSA PRIVATE KEY-----')) {
    privateKey = privateKey + '\n-----END RSA PRIVATE KEY-----';
  }

  return generateSignature(privateKey, signatureJsonString);
};

const toggleLoader = status => {
  const loader = document.getElementById('loaderDIV');
  if (status) {
    if (loader?.style.display === 'none' || loader?.style.display === '') {
      loader.style.display = 'block';
    }
  } else {
    if (loader?.style.display === 'block') {
      loader.style.display = 'none';
    }
  }
};

window.customElements.define(
  'capacitor-welcome',
  class extends HTMLElement {
    constructor() {
      super();

      SplashScreen.hide();
      defineCustomElements(window);
      const root = this.attachShadow({ mode: 'open' });

      console.warn('HyperServices', HyperServices);

      HyperServices.addListener('HyperEvent', async data => {
        console.error('SDK Event : ', data);
        const event = data['event'];
        try {
          const textView = root.getElementById('text-view');
          if (textView) {
            textView.innerHTML += '<p>SDK Event</p>';
            textView.innerHTML += JSON.stringify(data);
            textView.innerHTML += '<br>';
          }
        } catch (error) {
          console.error(error);
        }
        switch (event) {
          case 'show_loader':
            {
              // Show some loader here
              toggleLoader(true);
            }
            break;
          case 'hide_loader':
            {
              // Hide Loader
              toggleLoader(false);
            }
            break;
          case 'initiate_result':
            {
              // Get the payload
              toggleLoader(false);
              // let payload = data['payload'];
              console.log('initiate result: ', data);
            }
            break;
          case 'process_result':
            {
              // Get the payload
              // let payload = data['payload'];
              console.log('process result: ', data);
            }
            break;
          default:
            //Error handling
            console.log('process result: ', data);
            break;
        }
      });

      App.addListener('backButton', async _data => {
        const { onBackPressed } = await HyperServices.onBackPressed();
        if (!onBackPressed) {
          window.history.back();
        }
      });

      root.innerHTML = `
    <style>
      :host {
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
        display: block;
        width: 100%;
        height: 100%;
      }
      h1, h2, h3, h4, h5 {
        text-transform: uppercase;
      }
      .button {
        display: inline-block;
        padding: 10px;
        background-color: #73B5F6;
        color: #fff;
        font-size: 0.9em;
        border: 0;
        border-radius: 3px;
        text-decoration: none;
        cursor: pointer;
      }
      main {
        padding: 15px;

      }
      main hr { height: 1px; background-color: #eee; border: 0; }
      main h1 {
        font-size: 1.4em;
        text-transform: uppercase;
        letter-spacing: 1px;
      }
      main h2 {
        font-size: 1.1em;
      }
      main h3 {
        font-size: 0.9em;
      }
      main p {
        color: #333;
      }
      main pre {
        white-space: pre-line;
      }
      .btn-wrapper {
        width: 100%;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
      }
      .btn {
        min-width: 200px;
        padding: 8px 16px;
        background : #04AA6D!important;
        border: none;
        border-radius: 5px;
        font-size: 17px;
        color: #ffffff;
      }
      .text-view {
        min-width: 240px;
        height: wrap-content;
        padding: 8px 16px;
        border: 1px solid blue;
        border-radius: 5px;
        font-size: 17px;
        margin-top: 24px;
        word-break: break-all;
        max-height: 400px;
        overflow-y: scroll;
      }
    </style>
    <div>
      <capacitor-welcome-titlebar>
        <h1>Capacitor</h1>
      </capacitor-welcome-titlebar>
      <main>
      <div class="btn-wrapper">
        <button class="btn" id="create_hyper_btn" >Create Hyper Services</button>
        </br>
        <button class="btn" id="prefetch_btn" >Prefetch</button>
        </br>
        <button class="btn" id="init_btn" >Initiate</button>
        </br>
        <button class="btn" id="is_init_btn" >Is Initiatialised?</button>
        </br>
        <button class="btn" id="process_btn" >Process</button>
        </br>
        <button class="btn btn" id="terminate" >Terminate</button>
        </br>
        <button class="btn btn" id="is_null" >isNull</button>
      </div>
      <div class="text-view" id="text-view"></div>
      </main>
    </div>
    `;
    }

    connectedCallback() {
      const self = this;

      const textView = self.shadowRoot?.getElementById('text-view');
      if (self.shadowRoot) {
        self.shadowRoot
          .querySelector('#create_hyper_btn')
          ?.addEventListener('click', () => {
            toggleLoader(true);
            HyperServices.createHyperServices(
              merchantData.clientId,
              'in.juspay.hyperpay',
            )
              .then(_h => {
                // Any other API call can be done here.
                toggleLoader(false);
              })
              .catch(err => {
                toggleLoader(false);
                console.error(err.message);
              });
          });

        self.shadowRoot
          .querySelector('#prefetch_btn')
          ?.addEventListener('click', async () => {
            const payload = {
              requestId: uuidv4(),
              service: 'in.juspay.hyperpay',
              payload: {
                clientId: merchantData.clientId,
              },
            };
            try {
              if (textView) {
                textView.innerHTML += '<p>Prefetch Payload</p>';
                textView.innerHTML += JSON.stringify(payload);
              }
            } catch (error) {
              console.error(error);
            }
            await HyperServices.preFetch(payload);
          });

        self.shadowRoot
          .querySelector('#init_btn')
          ?.addEventListener('click', async function (_e) {
            try {
              const initiatePayload = {
                service: 'in.juspay.hyperpay',
                requestId: uuidv4(),
                payload: {
                  action: 'initiate',
                  merchantId: merchantData.merchantId,
                  clientId: merchantData.clientId,
                  environment: 'sandbox',
                  integrationType: 'iframe',
                  hyperSDKDiv: 'iframeJuspay',
                },
              };
              try {
                if (textView) {
                  textView.innerHTML += '<br><p>Initiate Payload</p>';
                  textView.innerHTML += JSON.stringify(initiatePayload);
                }
              } catch (error) {
                console.error(error);
              }
              toggleLoader(true);
              HyperServices.initiate(initiatePayload)
                .then(() => {
                  toggleLoader(false);
                })
                .catch(error => {
                  console.error(error);
                });
            } catch (e) {
              if (textView) {
                textView.innerHTML += '<p>Initiate failed!</p>';
              }
              toggleLoader(false);
              console.warn('Initiate failed', e);
            }
          });

        self.shadowRoot
          .querySelector('#is_init_btn')
          ?.addEventListener('click', async _e => {
            const { isInitialised } = await HyperServices.isInitialised();
            console.log('is SDK Initialised? ', isInitialised);
            try {
              if (textView) {
                textView.innerHTML += '<br><span>Initialised? = </span>';
                textView.innerHTML += isInitialised;
              }
            } catch (error) {
              console.error(error);
            }
          });

        self.shadowRoot
          .querySelector('#process_btn')
          ?.addEventListener('click', async _e => {
            try {
              const orderDetailsPayload = {
                order_id: 'DW-' + newOrderId(),
                merchant_id: merchantData.merchantId,
                amount: customerData.amount,
                timestamp: Date.now().toString(),
                customer_id: customerData.customerId,
                customer_phone: customerData.mobile,
                customer_email: customerData.email,
                return_url: 'http://localhost:3000/',
              };
              const signature = getSignature(orderDetailsPayload);
              const processPayload = {
                requestId: uuidv4(),
                service: 'in.juspay.hyperpay',
                payload: {
                  action: 'paymentPage',
                  clientId: merchantData.clientId,
                  merchantKeyId: merchantData.merchantKeyId,
                  orderDetails: JSON.stringify(orderDetailsPayload),
                  signature: signature,
                },
              };
              console.log('Process Payload: ', processPayload);
              try {
                if (textView) {
                  textView.innerHTML += '<br><p>Process Payload = </p>';
                  textView.innerHTML += JSON.stringify(processPayload);
                  textView.innerHTML += '<br>';
                }
              } catch (error) {
                console.error(error);
              }
              toggleLoader(true);
              await HyperServices.process(processPayload);
            } catch (e) {
              toggleLoader(false);
              console.error('Process Failed: ', e);
            }
          });
        self.shadowRoot
          .querySelector('#terminate')
          ?.addEventListener('click', async _e => {
            await HyperServices.terminate();
          });

        self.shadowRoot
          .querySelector('#is_null')
          ?.addEventListener('click', async _e => {
            const { isNull } = await HyperServices.isNull();
            console.log('is isNull? ', isNull);
            try {
              if (textView) {
                textView.innerHTML += '<br><span>isNull? = </span>';
                textView.innerHTML += isNull;
                textView.innerHTML += '<br>';
              }
            } catch (e) {
              console.error(e);
            }
          });
      }
    }
  },
);

window.customElements.define(
  'capacitor-welcome-titlebar',
  class extends HTMLElement {
    constructor() {
      super();
      const root = this.attachShadow({ mode: 'open' });
      root.innerHTML = `
    <style>
      :host {
        position: relative;
        display: block;
        padding: 15px 15px 15px 15px;
        text-align: center;
        background-color: #73B5F6;
      }
      ::slotted(h1) {
        margin: 0;
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
        font-size: 0.9em;
        font-weight: 600;
        color: #fff;
      }
    </style>
    <slot></slot>
    `;
    }
  },
);

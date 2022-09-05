import { WebPlugin } from '@capacitor/core';

import type { HyperServicesPlugin } from './definitions';

declare global {
  interface Window { HyperServices: any; }
}
export class HyperServicesWeb extends WebPlugin implements HyperServicesPlugin {
  hyperServices: any;


  async createHyperServices(clientId?: string, service?: string): Promise<void> {
    return new Promise((resolve) => {
      const jsElm = document.createElement("script");
      jsElm.type = "application/javascript";
      jsElm.src = "https://public.releases.juspay.in/hyper-sdk-web/HyperServices.js";
      if (service) {
        jsElm.setAttribute("service", service);
      }
      if (clientId) {
        jsElm.setAttribute("clientId", clientId);
      }
      document.body.appendChild(jsElm);
      const self = this;
      jsElm.onload = function () {
        self.hyperServices = new window.HyperServices();
        resolve();
      }
    })
  }

  async preFetch(payload: any): Promise<void> {
    return new Promise((resolve) => {
      window.HyperServices.preFetch(payload);
      resolve();
    })
  }

  async initiate(payload: any): Promise<void> {
    return new Promise((resolve, reject) => {
      if (!this.hyperServices) {
        reject(new Error("HyperServices instance not created"));
        return;
      }
      this.hyperServices.initiate(payload, (responseData: any) => {
        try {
          console.warn("HyperEvent ", responseData);
          this.notifyListeners("HyperEvent", responseData);
        } catch (error) {
          //Error handling
          reject(new Error("" + error));
        }
      });
      resolve();
    })
  }

  async process(payload: any): Promise<void> {
    return new Promise((resolve, reject) => {
      if (!this.hyperServices) {
        reject(new Error("HyperServices instance not created"));
        return;
      }
      this.hyperServices.process(payload);
      resolve();
    })
  }

  async terminate(): Promise<void> {
    return new Promise((resolve, reject) => {
      if (!this.hyperServices) {
        reject(new Error("HyperServices instance not created or already terminated!"));
        return;
      }
      this.hyperServices.terminate();
      this.hyperServices = null;
      resolve();
    })
  }

  async isInitialised(): Promise<{ isInitialised: boolean }> {
    return new Promise((resolve) => {
      resolve({ isInitialised: this.hyperServices.isInitialised() });
    });
  }

  async onBackPressed(): Promise<{ onBackPressed: boolean }> {
    return new Promise((resolve) => {
      resolve({ onBackPressed: this.hyperServices.handleBackpress() });
    });
  }

  async isNull(): Promise<{ isNull: boolean }> {
    return new Promise((resolve) => {
      resolve({ isNull: this.hyperServices == null });
    })
  }
}

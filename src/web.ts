import { WebPlugin } from '@capacitor/core';
import type { HyperServicesPlugin } from './definitions';
export class HyperServicesWeb extends WebPlugin implements HyperServicesPlugin {

  async createHyperServices() {
    throw this.unimplemented('Not implemented on web yet.');
  }

  async preFetch(payload: any) {
    console.log("Prefetch called", payload);
    throw this.unimplemented('Not implemented on web yet.');
  }

  async initiate(payload: any) {
    console.log("Initiate called", payload);
    throw this.unimplemented('Not implemented on web yet.');
  }

  async process(payload: any) {
    console.log("Process called", payload);
    throw this.unimplemented('Not implemented on web yet.');
  }

  async terminate() {
    throw this.unimplemented('Not implemented on web yet.');
  }

  async isInitialised(): Promise<boolean> {
    throw this.unimplemented('Not implemented on web.');
  }

  async onBackPressed(): Promise<boolean> {
    throw this.unimplemented('Not implemented on web.');
  }

  async isNull(): Promise<boolean> {
    throw this.unimplemented('Not implemented on web');
  }
}

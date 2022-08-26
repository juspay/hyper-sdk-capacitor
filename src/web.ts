import { WebPlugin } from '@capacitor/core';

import type { HyperServicesPlugin } from './definitions';

export class HyperServicesWeb extends WebPlugin implements HyperServicesPlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
}

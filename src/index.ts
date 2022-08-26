import { registerPlugin } from '@capacitor/core';

import type { HyperServicesPlugin } from './definitions';

const HyperServices = registerPlugin<HyperServicesPlugin>('HyperServices', {
  web: () => import('./web').then(m => new m.HyperServicesWeb()),
});

export * from './definitions';
export { HyperServices };

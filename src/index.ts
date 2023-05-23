/*
 * Copyright (c) Juspay Technologies.
 *
 * This source code is licensed under the AGPL 3.0 license found in the
 * LICENSE file in the root directory of this source tree.
 */

import { registerPlugin } from '@capacitor/core';

import type { HyperServicesPlugin } from './definitions';

const HyperServices = registerPlugin<HyperServicesPlugin>('HyperServices', {
  web: () => import('./web').then(m => new m.HyperServicesWeb()),
});

export * from './definitions';
export { HyperServices };

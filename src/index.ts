/*
 * Copyright (c) Juspay Technologies.
 *
 * This source code is licensed under the AGPL 3.0 license found in the
 * LICENSE file in the root directory of this source tree.
 */

import { registerPlugin, Capacitor } from '@capacitor/core';

import type { HyperServicesPlugin } from './definitions';

const _plugin = registerPlugin<HyperServicesPlugin>('HyperServices', {
  web: () => import('./web').then(m => new m.HyperServicesWeb()),
});

const HyperServices: HyperServicesPlugin = new Proxy(_plugin, {
  get(target: any, prop: string | symbol) {
    if (prop === 'process') {
      return async (payload: any): Promise<void> => {
        if (
          Capacitor.isNativePlatform() &&
          typeof payload?.payload?.fragmentViewGroups?.paymentWidget ===
            'string'
        ) {
          const el = document.getElementById(
            payload.payload.fragmentViewGroups.paymentWidget,
          );
          if (el) {
            const rect = el.getBoundingClientRect();
            payload = {
              ...payload,
              payload: {
                ...payload.payload,
                paymentWidgetRect: {
                  x: rect.left,
                  y: rect.top,
                  width: rect.width,
                  height: rect.height,
                },
              },
            };
          }
        }
        return target.process(payload);
      };
    }
    const value = target[prop];
    return typeof value === 'function' ? value.bind(target) : value;
  },
});

export * from './definitions';
export { HyperServices };
